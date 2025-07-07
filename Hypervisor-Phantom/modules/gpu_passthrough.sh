#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils/formatter.sh"
source "./utils/prompter.sh"

readonly VFIO_CONF_PATH="/etc/modprobe.d/vfio.conf"

declare -a SDBOOT_CONF_LOCATIONS=(
    "/boot/loader/entries"
    "/boot/efi/loader/entries"
    "/efi/loader/entries"
)

isolate_gpu() {
    local gpus sel busid group

    mapfile -t gpus < <(for d in /sys/bus/pci/devices/*; do
        [[ $(<"$d/class") == 0x03* ]] &&
        printf '%s %s\n' "$d" \
            "$(lspci -s ${d##*/} | grep -oP '\[\K[^\]]+(?=\])')"
    done)

    for i in "${!gpus[@]}"; do
        printf '\n  %d) %s\n' $((i+1)) "${gpus[i]#* }"
    done
    read -rp "$(fmtr::ask 'Select device number: ')" sel; ((sel--))

    busid=$(basename "${gpus[sel]%% *}")
    group=$(basename "$(readlink -f "/sys/bus/pci/devices/$busid/iommu_group")")

    hwids=$(for d in /sys/kernel/iommu_groups/$group/devices/*; do
                ven=$(<"$d/vendor"); dev=$(<"$d/device")
                printf '%s:%s,' "${ven#0x}" "${dev#0x}"
            done); hwids=${hwids%,}

    fmtr::log "Modifying VFIO config: $VFIO_CONF_PATH"

    if [[ $(<"/sys/bus/pci/devices/$busid/vendor") == "0x10de" ]]; then
        printf 'options vfio-pci ids=%s\nsoftdep nvidia pre: vfio-pci\n' "$hwids" | \
            sudo tee $VFIO_CONF_PATH >/dev/null
    else
        printf 'options vfio-pci ids=%s\n' "$hwids" | sudo tee $VFIO_CONF_PATH >/dev/null
    fi
}

configure_bootloader() {
    local cpu_vendor kernel_opts boot_mode=""

    case "$VENDOR_ID" in
        *AuthenticAMD*) cpu_vendor="amd" ;;
        *GenuineIntel*) cpu_vendor="intel" ;;
        *) fmtr::error "Unknown CPU Vendor ID."; return 1 ;;
    esac
    kernel_opts="${cpu_vendor}_iommu=on iommu=pt vfio-pci.ids=${hwids}"

    if [[ -f "/etc/default/grub" ]]; then
        boot_mode="grub"
        fmtr::log "Configuring GRUB"
        sudo cp /etc/default/grub{,.bak}
        if ! grep -q "${kernel_opts}" /etc/default/grub; then
            sudo sed -i "s|\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)|\1 ${kernel_opts}|" /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg || fmtr::warn "Manual GRUB update may be required."
        else
            fmtr::log "Kernel options already present in GRUB config."
        fi
        export BOOTLOADER_TYPE="grub"
        return 0
    fi

    for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
        [[ -d "$location" ]] || continue
        local config_file
        config_file=$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)
        [[ -z "$config_file" ]] && fmtr::warn "No configuration file found in $location" && continue

        fmtr::log "Modifying systemd-boot config: $config_file"

        # Remove any vfio/iommu params from all options lines
        sudo sed -i -E \
            -e '/^options /s/(amd_iommu=on|intel_iommu=on|iommu=pt|vfio-pci.ids=[^ ]*)//g' \
            -e '/^options[[:space:]]*$/d' \
            "$config_file"

        # Add vfio options on a new line, if not already present
        if ! grep -q "^options[[:space:]]\+${kernel_opts}" "$config_file"; then
            echo "options ${kernel_opts}" | sudo tee -a "$config_file" >/dev/null
        fi

        if [[ -f "/boot/loader/loader.conf" ]]; then
            sudo sed -i "s/^default.*/default $(basename "$config_file")/" /boot/loader/loader.conf
        fi
        export BOOTLOADER_TYPE="systemd-boot"
        return 0
    done

    fmtr::warn "No bootloader configuration found."
    export BOOTLOADER_TYPE=""
    return 1
}

rebuild_boot_configs() {
    if [[ "$BOOTLOADER_TYPE" != "grub" ]]; then
        fmtr::log "Bootloader config rebuild not required for non-GRUB bootloaders."
        return 0
    fi

    fmtr::log "Updating bootloader configuration for GRUB-based system ($DISTRO)."
    case "$DISTRO" in
        Arch)
            sudo grub-mkconfig -o /boot/grub/grub.cfg &>> "$LOG_FILE" && fmtr::log "Bootloader configuration updated."
            ;;
        Debian)
            sudo update-grub &>> "$LOG_FILE" && fmtr::log "Bootloader configuration updated."
            ;;
        Fedora|openSUSE)
            if command -v grub2-mkconfig &>/dev/null; then
                sudo grub2-mkconfig -o /boot/grub2/grub.cfg &>> "$LOG_FILE" && fmtr::log "Bootloader configuration updated."
            elif command -v grub-mkconfig &>/dev/null; then
                sudo grub-mkconfig -o /boot/grub/grub.cfg &>> "$LOG_FILE" && fmtr::log "Bootloader configuration updated."
            fi
            ;;
        *)
            fmtr::error "Unsupported distro for bootloader config rebuild: $DISTRO"
            return 1
            ;;
    esac
    return 0
}

revert_vfio() {
    if [[ -f "$VFIO_CONF_PATH" ]]; then
        sudo rm -v "$VFIO_CONF_PATH" | tee -a &>> "$LOG_FILE"
    else
        fmtr::log "$VFIO_CONF_PATH doesn't exist; nothing to remove."
    fi

    if [[ -f "/etc/default/grub" ]]; then
        sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/s/\(amd_iommu\|intel_iommu\|iommu\|vfio-pci.ids\)=[^ "]*//g' /etc/default/grub
    else
        for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            [[ -d "$location" ]] || continue
            local config_file
            config_file=$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)
            [[ -z "$config_file" ]] && continue
            sudo sed -i -e '/options/ s/\(amd_iommu\|intel_iommu\|iommu\|vfio-pci.ids\)=[^ ]*//g' \
                        -e '/^options[[:space:]]*$/d' "$config_file"
        done
    fi
}

# ----- PROMPTS -----

fmtr::warn "DISCLAIMER: This VFIO script automates GPU isolation, bootloader reconfiguration, and
      ramdisk regeneration. Due to potential IOMMU grouping issues on some motherboards, this
      process may not execute correctly and could mess up your system. So I highly encourage
      you to double check the work automated for your systems safety! Make sure the vendor and
      device ids of your selected GPU are matching the ones set in the following config files:

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

# Prompt 3: Proceed with updating bootloader config?
if prmt::yes_or_no "$(fmtr::ask 'Proceed with rebuilding bootloader config?')"; then
    if ! rebuild_boot_configs; then
        fmtr::log "Failed to update bootloader configuration."
        exit 1
    fi
    fmtr::warn "REBOOT required for changes to take effect"
else
    fmtr::warn "Proceeding without updating bootloader configuration."
fi
