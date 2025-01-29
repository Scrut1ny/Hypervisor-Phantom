#!/usr/bin/env bash
[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "./utils/formatter.sh"
source "./utils/prompter.sh"

readonly VFIO_CONF_PATH="/etc/modprobe.d/vfio.conf"

declare -a SDBOOT_CONF_LOCATIONS=(
    "/boot/loader/entries"
    "/boot/efi/loader/entries"
    "/efi/loader/entries"
)

# Device categories with corresponding grep patterns
declare -A DEVICE_TYPES=(
    [1]='vga|3d'
    [2]='Non-Volatile memory'
    [3]='.*'
)

isolate_gpu() {
    while true; do
        fmtr::log "Select device type:\n\n  1) GPUs/iGPUs\n  2) NVMe SSDs\n  3) All PCI devices\n  4) Cancel"
        read -rp "$(fmtr::ask 'Enter choice (1-4): ')" choice

        [[ ! "$choice" =~ ^[1-4]$ ]] && { fmtr::warn "Invalid choice"; continue; }

        case "$choice" in
            4)
                fmtr::log "Device selection cancelled."
                return 1
                ;;
            *)
                pci_device=$(lspci | grep -iE "${DEVICE_TYPES[$choice]}" | sort)
                fmtr::log "Available devices:\n"
                echo "$pci_device" | nl -w2 -s') ' | sed 's/^/ /'

                read -rp "$(fmtr::ask 'Select device number: ')" selection
                bus_number=$(echo "$pci_device" | sed -n "${selection}p" | awk '{print $1}' | cut -d: -f1)
                HWID=$(lspci -nn | grep "^${bus_number}:" | sed -E 's/.*\[([0-9a-f:]+)\].*/\1/' | paste -sd, -)

                echo -e "options vfio-pci ids=$HWID\nsoftdep nvidia pre: vfio-pci" | \
                    sudo tee -a "$VFIO_CONF_PATH" &>> "$LOG_FILE"
                fmtr::log "Configured $VFIO_CONF_PATH"
                break
                ;;
        esac
    done
}

configure_bootloader() {
    local CPU_VENDOR IOMMU_SETTING
    case "$VENDOR_ID" in
        *AuthenticAMD*) IOMMU_SETTING="amd_iommu=on" ;;
        *GenuineIntel*) IOMMU_SETTING="intel_iommu=on" ;;
        *) fmtr::error "Unknown CPU vendor"; exit 1 ;;
    esac

    if [[ -f "/etc/default/grub" ]]; then
        fmtr::log "Configuring GRUB"
        sudo cp /etc/default/grub{,.bak}
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/& $IOMMU_SETTING iommu=pt vfio-pci.ids=$HWID /" \
            /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg || fmtr::warn "Manual GRUB update required"
    else
        for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            [[ -d "$location" ]] || continue

            local config_file=$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)
            [[ -z "$config_file" ]] && { fmtr::warn "No config in $location"; return 1; }

            fmtr::log "Modifying systemd-boot: $config_file"
            sudo cp "$config_file" "${config_file}.bak"
            echo "options $IOMMU_SETTING iommu=pt vfio-pci.ids=$HWID" | \
                sudo tee -a "$config_file" &>> "$LOG_FILE"

            [[ -f "/boot/loader/loader.conf" ]] && \
                sudo sed -i "s/^default.*/default $(basename "$config_file")/" /boot/loader/loader.conf
            return 0
        done
        fmtr::warn "No bootloader config found"
        return 1
    fi
}

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
        Fedora)
            sudo grub2-mkconfig -o /boot/grub2/grub.cfg
            sudo dracut -f &>> "$LOG_FILE"
            ;;
        *) fmtr::error "Unsupported distro"; return 1 ;;
    esac
}

revert_vfio() {
    [[ -f "$VFIO_CONF_PATH" ]] && sudo rm -v "$VFIO_CONF_PATH" | tee -a "$LOG_FILE"

    if [[ -f "/etc/default/grub" ]]; then
        sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/s/\(amd_iommu\|intel_iommu\|iommu\|vfio-pci.ids\)=[^ "]*//g' \
            /etc/default/grub
    else
        for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            [[ -d "$location" ]] || continue

            local config_file=$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)
            [[ -z "$config_file" ]] && continue

            sudo sed -i -e '/options/ s/\(amd_iommu\|intel_iommu\|iommu\|vfio-pci.ids\)=[^ ]*//g' \
                        -e '/^options[[:space:]]*$/d' "$config_file"
        done
    fi

    regenerate_ramdisks
}

# Main execution flow
if prmt::yes_or_no "$(fmtr::ask 'Remove VFIO configs? (undo PCI passthrough)')"; then
    revert_vfio
    if prmt::yes_or_no "$(fmtr::ask 'Re-configure VFIO now?')"; then
        isolate_gpu && {
            configure_bootloader
            regenerate_ramdisks
        } || fmtr::log "Configuration aborted."
    fi
else
    isolate_gpu && {
        configure_bootloader
        regenerate_ramdisks
    } || fmtr::log "Configuration aborted."
fi

fmtr::warn "REBOOT required for changes to take effect"
