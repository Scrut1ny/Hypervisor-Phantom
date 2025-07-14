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

revert_vfio() {
    if [[ -f "$VFIO_CONF_PATH" ]]; then
        sudo rm -v "$VFIO_CONF_PATH" | tee -a &>> "$LOG_FILE"
    else
        fmtr::log "$VFIO_CONF_PATH doesn't exist; nothing to remove."
    fi

    if [[ -f "/etc/default/grub" ]]; then
        sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/s/\(amd_iommu\|intel_iommu\|iommu\|vfio-pci.ids\|kvm.ignore_msrs\)=[^ "]*//g' /etc/default/grub
    else
        for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            [[ -d "$location" ]] || continue
            local config_file
            config_file=$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)
            [[ -z "$config_file" ]] && continue
            sudo sed -i -E \
                -e '/options/ s/(amd_iommu=on|intel_iommu=on|iommu=pt|vfio-pci.ids=[^ ]*|kvm.ignore_msrs=1)//g' \
                -e '/^options[[:space:]]*$/d' \
                "$config_file"
        done
    fi
}

configure_vfio() {
    local gpus sel busid group

    mapfile -t gpus < <(for d in /sys/bus/pci/devices/*; do
        [[ $(<"$d/class") == 0x03* ]] &&
        printf '%s %s\n' "$d" "$(lspci -s ${d##*/} | grep -oP '\[\K[^\]]+(?=\])')"
    done)

    while true; do
        for i in "${!gpus[@]}"; do
            printf '\n  %d) %s\n' $((i+1)) "${gpus[i]#* }"
        done
        read -rp "$(fmtr::ask 'Select device number: ')" sel; ((sel--))
        if (( sel >= 0 && sel < ${#gpus[@]} )); then
            break
        fi
        fmtr::error "Invalid selection. Please choose a valid number."
    done

    busid="$(basename "${gpus[sel]%% *}")"
    group="$(basename "$(readlink -f "/sys/bus/pci/devices/$busid/iommu_group")")"

    hwids=; for d in /sys/kernel/iommu_groups/$group/devices/*; do
        read -r v < "$d/vendor"; read -r i < "$d/device"
        hwids+="${v:2}:${i:2},"
    done; hwids="${hwids%,}"

    fmtr::log "Modifying VFIO config: $VFIO_CONF_PATH"

    if [[ -f "/sys/bus/pci/devices/$busid/vendor" ]]; then
        vendor=$(<"/sys/bus/pci/devices/$busid/vendor")

        case "$vendor" in
            "0x10de")  # NVIDIA
                printf 'options vfio-pci ids=%s\nsoftdep nvidia pre: vfio-pci\nsoftdep nouveau pre: vfio-pci\nsoftdep drm pre: vfio-pci\nsoftdep drm_kms_helper pre: vfio-pci\n' "$hwids" | sudo tee "$VFIO_CONF_PATH" &>> "$LOG_FILE"
                ;;
            "0x1002")  # AMD
                printf 'options vfio-pci ids=%s\nsoftdep amdgpu pre: vfio-pci\nsoftdep radeon pre: vfio-pci\nsoftdep drm pre: vfio-pci\nsoftdep drm_kms_helper pre: vfio-pci\n' "$hwids" | sudo tee "$VFIO_CONF_PATH" &>> "$LOG_FILE"
                ;;
            "0x8086")  # Intel
                printf 'options vfio-pci ids=%s\nsoftdep i915 pre: vfio-pci\nsoftdep drm pre: vfio-pci\nsoftdep drm_kms_helper pre: vfio-pci\n' "$hwids" | sudo tee "$VFIO_CONF_PATH" &>> "$LOG_FILE"
                ;;
            *)  # Unknown, just add VFIO IDs
                printf 'options vfio-pci ids=%s\n' "$hwids" | sudo tee "$VFIO_CONF_PATH" &>> "$LOG_FILE"
                ;;
        esac
    fi
}

configure_bootloader() {
    local cpu_vendor kernel_opts boot_mode=""
    case "$VENDOR_ID" in
        *AuthenticAMD*) cpu_vendor="amd";;
        *GenuineIntel*) cpu_vendor="intel";;
        *) fmtr::error "Unknown CPU Vendor ID."; return 1;;
    esac
    kernel_opts="${cpu_vendor}_iommu=on iommu=pt vfio-pci.ids=${hwids} kvm.ignore_msrs=1"

    if [[ -f "/etc/default/grub" ]]; then
        boot_mode="grub"
        fmtr::log "Configuring GRUB"
        sudo cp /etc/default/grub{,.bak}
        if ! grep -q "${kernel_opts}" /etc/default/grub; then
            sudo sed -i "s|\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)|\1 ${kernel_opts}|" /etc/default/grub
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

        sudo sed -i -E \
            -e '/^options /s/(amd_iommu=on|intel_iommu=on|iommu=pt|vfio-pci.ids=[^ ]*)//g' \
            -e '/^options[[:space:]]*$/d' \
            "$config_file"
        echo "options ${kernel_opts}" | sudo tee -a "$config_file" &>> "$LOG_FILE"
    done
}

rebuild_bootloader() {
    if [[ "$BOOTLOADER_TYPE" != "grub" ]]; then
        fmtr::log "Bootloader config rebuild not required for non-GRUB bootloaders."
        return 0
    fi

    fmtr::log "Updating bootloader configuration for GRUB."

    for prefix in "" "2"; do
        if command -v grub${prefix}-mkconfig &>> "$LOG_FILE"; then
            sudo grub${prefix}-mkconfig -o /boot/grub${prefix}/grub.cfg &>> "$LOG_FILE" && fmtr::log "Bootloader configuration updated."
            return 0
        fi
    done

    fmtr::error "No known GRUB configuration command found on this system."
    return 1
}

rebuild_initramfs() {
    if command -v update-initramfs &>> "$LOG_FILE"; then
        sudo update-initramfs -u &>> "$LOG_FILE" && fmtr::log "initramfs updated."
    elif command -v dracut &>> "$LOG_FILE"; then
        sudo dracut -f &>> "$LOG_FILE" && fmtr::log "initramfs updated."
    elif command -v mkinitcpio &>> "$LOG_FILE"; then
        sudo mkinitcpio -P &>> "$LOG_FILE" && fmtr::log "initramfs updated."
    elif command -v mkinitrd &>> "$LOG_FILE"; then
        sudo mkinitrd &>> "$LOG_FILE" && fmtr::log "initramfs updated."
    else
        fmtr::error "Could not detect initramfs tool - please rebuild manually."
        return 1
    fi
}

# ----- PROMPTS -----

# Prompt 1 - Acknowledge agreement?
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

# Prompt 2 - Remove VFIO config?
if prmt::yes_or_no "$(fmtr::ask 'Remove VFIO configs? (undo PCI passthrough)')"; then
    revert_vfio
fi

# Prompt 3 - Configure VFIO config?
if prmt::yes_or_no "$(fmtr::ask 'Configure VFIO now?')"; then
    if ! configure_vfio; then
        fmtr::log "Configuration aborted during device selection."
        exit 1
    fi
    if ! configure_bootloader; then
        fmtr::log "Bootloader configuration aborted."
        exit 1
    fi
fi

# Prompt 4 - Rebuild bootloader config?
if prmt::yes_or_no "$(fmtr::ask 'Proceed with rebuilding bootloader config?')"; then
    if ! rebuild_bootloader; then
        fmtr::log "Failed to update bootloader configuration."
        exit 1
    fi
    fmtr::warn "REBOOT required for changes to take effect"
else
    fmtr::warn "Proceeding without updating bootloader configuration."
fi

# Prompt 5 - Rebuild initramfs?
if prmt::yes_or_no "$(fmtr::ask 'Proceed with rebuilding initramfs?')"; then
    if ! rebuild_initramfs; then
        fmtr::log "Failed to rebuild initramfs."
        exit 1
    fi
    fmtr::warn "REBOOT required for changes to take effect"
else
    fmtr::warn "Proceeding without updating initramfs."
fi
