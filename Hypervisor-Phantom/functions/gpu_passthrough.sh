#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils/formatter.sh"
source "./utils/prompter.sh"

readonly VFIO_CONF_PATH="/etc/modprobe.d/vfio.conf"

# Bootloader config locations for systemd-boot.
declare -a SDBOOT_CONF_LOCATIONS=(
    "/boot/loader/entries"
    "/boot/efi/loader/entries"
    "/efi/loader/entries"
)

# Device category patterns.
declare -A DEVICE_TYPES=(
    [1]='vga|3d'
    [2]='Non-Volatile memory'
    [3]='.*'
)

# isolate_gpu:
# Presents a list of PCI devices based on category and returns the chosen device's hardware ID.
isolate_gpu() {
    local choice pci_devices selection bus_number hwid
    # Cache the lspci output to avoid multiple calls.
    local all_devices
    all_devices=$(lspci)

    while true; do
        fmtr::log "Select device type:

  1) GPUs/iGPUs
  2) NVMe SSDs
  3) All PCI devices
  4) Cancel (restart script)"
        read -rp "$(fmtr::ask 'Enter choice (1-4): ')" choice

        [[ ! "$choice" =~ ^[1-4]$ ]] && { fmtr::warn "Invalid choice"; continue; }

        if [[ "$choice" -eq 4 ]]; then
            clear; fmtr::box_text "VFIO Configuration"; exec "$0"
        fi

        # Filter devices based on selection.
        pci_devices=$(echo "$all_devices" | grep -iE "${DEVICE_TYPES[$choice]}" | sort)
        if [[ -z "$pci_devices" ]]; then
            fmtr::warn "No devices match the criteria. Try a different selection."
            continue
        fi

        fmtr::log "Available devices:"; echo ""
        # Number each device.
        echo "$pci_devices" | nl -w2 -s') ' | sed 's/^/ /'
        read -rp "$(fmtr::ask 'Select device number: ')" selection

        # Select the chosen device.
        bus_number=$(echo "$pci_devices" | sed -n "${selection}p" | awk '{print $1}' | cut -d: -f1)
        if [[ -z "$bus_number" ]]; then
            fmtr::warn "Invalid selection. Please try again."
            continue
        fi

        hwid=$(lspci -nn | grep "^${bus_number}:" | sed -E 's/.*\[([0-9a-f:]+)\].*/\1/' | paste -sd, -)
        if [[ -z "$hwid" ]]; then
            fmtr::warn "Unable to determine Hardware ID. Please try again."
            continue
        fi

        # Append VFIO options to vfio.conf.
        echo -e "options vfio-pci ids=$hwid\nsoftdep nvidia pre: vfio-pci" | \
            sudo tee -a "$VFIO_CONF_PATH" &>> "$LOG_FILE"
        fmtr::log "Configured $VFIO_CONF_PATH with IDs: $hwid"
        # Set and export HWID for bootloader configuration.
        HWID=$hwid
        export HWID
        readonly HWID
        break
    done
}

# configure_bootloader:
# Updates bootloader configurations (GRUB or systemd-boot) with IOMMU and VFIO options.
configure_bootloader() {
    local iommu_setting
    case "$VENDOR_ID" in
        *AuthenticAMD*)
            iommu_setting="amd_iommu=on"
            ;;
        *GenuineIntel*)
            iommu_setting="intel_iommu=on"
            ;;
        *)
            fmtr::error "Unknown CPU vendor"
            exit 1
            ;;
    esac

    if [[ -f "/etc/default/grub" ]]; then
        fmtr::log "Configuring GRUB"
        sudo cp /etc/default/grub{,.bak}
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/& $iommu_setting iommu=pt vfio-pci.ids=$HWID /" /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg || fmtr::warn "Manual GRUB update required"
    else
        local location config_file
        for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            [[ -d "$location" ]] || continue

            config_file=$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)
            if [[ -z "$config_file" ]]; then
                fmtr::warn "No configuration file found in $location"
                continue
            fi

            fmtr::log "Modifying systemd-boot config: $config_file"
            sudo cp "$config_file" "${config_file}.bak"
            echo "options $iommu_setting iommu=pt vfio-pci.ids=$HWID" | sudo tee -a "$config_file" &>> "$LOG_FILE"

            if [[ -f "/boot/loader/loader.conf" ]]; then
                sudo sed -i "s/^default.*/default $(basename "$config_file")/" /boot/loader/loader.conf
            fi
            return 0
        done
        fmtr::warn "No bootloader configuration found."
        return 1
    fi
}

# regenerate_ramdisks:
# Regenerates initramfs and/or GRUB configurations based on the detected distro.
regenerate_ramdisks() {
    case "$DISTRO" in
        Arch)
            sudo mkinitcpio -P &>> "$LOG_FILE"
            command -v grub-mkconfig &>/dev/null && sudo grub-mkconfig -o /boot/grub/grub.cfg
            command -v reinstall-kernels &>/dev/null && sudo reinstall-kernels
            ;;
        Debian)
            sudo update-initramfs -u &>> "$LOG_FILE"
            sudo update-grub
            ;;
        openSUSE|Fedora)
            sudo grub2-mkconfig -o /boot/grub2/grub.cfg &>> "$LOG_FILE"
            sudo dracut -f &>> "$LOG_FILE"
            ;;
        *)
            fmtr::error "Unsupported distro"
            return 1
            ;;
    esac
    return 0
}

# revert_vfio:
# Removes VFIO configurations and restores previous bootloader settings.
revert_vfio() {
    if [[ -f "$VFIO_CONF_PATH" ]]; then
        sudo rm -v "$VFIO_CONF_PATH" | tee -a &>> "$LOG_FILE"
    else
        fmtr::log "$VFIO_CONF_PATH does not exist; nothing to remove."
    fi

    if [[ -f "/etc/default/grub" ]]; then
        sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/s/\(amd_iommu\|intel_iommu\|iommu\|vfio-pci.ids\)=[^ "]*//g' /etc/default/grub
    else
        local location config_file
        for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            [[ -d "$location" ]] || continue
            config_file=$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)
            [[ -z "$config_file" ]] && continue
            sudo sed -i -e '/options/ s/\(amd_iommu\|intel_iommu\|iommu\|vfio-pci.ids\)=[^ ]*//g' \
                        -e '/^options[[:space:]]*$/d' "$config_file"
        done
    fi
}

###############################
# Main flow of configure_vfio.sh
###############################

# Prompt 0: Important disclaimer
fmtr::warn "DISCLAIMER: This VFIO script automates GPU isolation, bootloader reconfiguration, and
      ramdisk regeneration. Due to potential IOMMU grouping issues on some motherboards, this
      process may not execute correctly and could mess up your system. So I highly encourage
      you to double check the work automated for your systems safety! Make sure the vendor and
      device ids of your selected GPU are matching the ones in the following config files:

      - lspci -nn | grep -Ei 'vga|3d|audio device'    _____________________________________
      - $VFIO_CONF_PATH                    / systemd-boot = /boot/loader/entries |
      - Bootloader configuration entries ]__________/  GRUB         = /etc/default/grub    |"

if ! prmt::yes_or_no "$(fmtr::ask 'Acknowledge and proceed with this script?')"; then
    fmtr::log "Acknowledgement declined by $(whoami); therefore exiting."
    exit 0
fi

# Prompt 1: Remove VFIO configs (undo PCI passthrough)?
if prmt::yes_or_no "$(fmtr::ask 'Remove VFIO configs? (undo PCI passthrough)')"; then
    revert_vfio
fi

# Prompt 2: Re-configure VFIO now?
if prmt::yes_or_no "$(fmtr::ask 'Configure VFIO now?')"; then
    if ! isolate_gpu; then
        fmtr::log "Configuration aborted during device selection."
        exit 1
    fi
    if ! configure_bootloader; then
        fmtr::log "Bootloader configuration aborted."
        exit 1
    fi
fi

# Prompt 3: Proceed with regenerating ramdisks?
if prmt::yes_or_no "$(fmtr::ask 'Proceed with regenerating ramdisks?')"; then
    if ! regenerate_ramdisks; then
        fmtr::log "Failed to regenerate ramdisks."
        exit 1
    fi
    fmtr::warn "REBOOT required for changes to take effect"
else
    fmtr::warn "Proceeding without regenerating ramdisks."
fi
