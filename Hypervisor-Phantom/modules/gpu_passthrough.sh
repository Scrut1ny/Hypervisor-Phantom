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
    local gpus sel="" pci_bdf group class pci_vendor pci_device_id \
          bad_group=0 bad_functions=() pci_desc

    # Collect GPU candidates (PCI class 0x03* = all display controllers)
    mapfile -t gpus < <(
        for devpath in /sys/bus/pci/devices/*; do
            [[ -r "$devpath/class" ]] || continue
            [[ $(<"$devpath/class") == 0x03* ]] || continue
            pci_bdf=${devpath##*/} # Full BDF, e.g. "01:00.0"
            pci_desc=$(lspci -s "$pci_bdf")
            pci_desc=${pci_desc##*[}; pci_desc=${pci_desc%%]*}
            printf '%s %s\n' "$devpath" "$pci_desc"
        done
    )

    if (( ${#gpus[@]} == 0 )); then
        fmtr::error "No GPUs detected! Exiting."
        exit 1
    elif (( ${#gpus[@]} == 1 )); then
        fmtr::warn "Only one GPU detected! Passing through your only GPU will leave the host with no display output.
      It is strongly recommended to have a separate dedicated or integrated GPU for the host system."
    fi

    # User chooses GPU
    while :; do
        printf '\n'
        for i in "${!gpus[@]}"; do
            printf '  %d) %s\n' "$((i + 1))" "${gpus[i]#* }"
        done

        read -rp "$(fmtr::ask 'Select device number: ')" sel

        if [[ ! $sel =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#gpus[@]} )); then
            fmtr::error "Invalid selection. Please choose a valid number."
            continue
        fi

        (( sel-- ))
        break
    done

    pci_bdf="${gpus[sel]%% *}"        # e.g. "0000:01:00.0"
    pci_bdf="${pci_bdf##*/}"          # Strip domain → "01:00.0"
    group=$(readlink -f "/sys/bus/pci/devices/$pci_bdf/iommu_group")
    group=${group##*/}

    pci_bus_dev="${pci_bdf%.*}"       # Bus:Device only, e.g. "01:00"
    hwids=""
    for devpath in /sys/kernel/iommu_groups/$group/devices/*; do
        pci_func_bdf="${devpath##*/}" # e.g. "01:00.1"
        pci_vendor=$(<"$devpath/vendor")
        pci_device_id=$(<"$devpath/device")
        hwids+="${pci_vendor:2}:${pci_device_id:2},"

        pci_bus_dev_current="${pci_func_bdf%.*}"
        if [[ $pci_bus_dev_current != "$pci_bus_dev" ]]; then
            bad_group=1
            bad_functions+=("$pci_func_bdf")
        fi
    done
    hwids="${hwids%,}"

    if (( bad_group )); then
        fmtr::error "Bad IOMMU grouping detected - IOMMU group #$group contains incorrect device(s):"; echo ""
        for pci_func_bdf in "${bad_functions[@]}"; do
            pci_desc=$(lspci -s "$pci_func_bdf" -nn)
            echo "  [$pci_func_bdf] = $pci_desc"
        done
        fmtr::warn "VFIO PT requires the entire IOMMU group for isolation. Recommended possible solutions:
      (1) ACS override, (2) Update firmware, (3) Use hardware with proper IOMMU support."
        exit 1
    fi

    fmtr::log "Modifying VFIO config: $VFIO_CONF_PATH"

    if [[ -f "/sys/bus/pci/devices/$pci_bdf/vendor" ]]; then
        pci_vendor=$(<"/sys/bus/pci/devices/$pci_bdf/vendor")

        case "$pci_vendor" in
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

# Prompt 1 - Remove VFIO config?
if prmt::yes_or_no "$(fmtr::ask 'Remove VFIO configs? (undo PCI passthrough)')"; then
    revert_vfio
fi

# Prompt 2 - Configure VFIO config?
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

# Prompt 3 - Rebuild bootloader config?
if prmt::yes_or_no "$(fmtr::ask 'Proceed with rebuilding bootloader config?')"; then
    if ! rebuild_bootloader; then
        fmtr::log "Failed to update bootloader configuration."
        exit 1
    fi
    fmtr::warn "REBOOT required for changes to take effect"
else
    fmtr::warn "Proceeding without updating bootloader configuration."
fi

# Prompt 4 - Rebuild initramfs?
if prmt::yes_or_no "$(fmtr::ask 'Proceed with rebuilding initramfs?')"; then
    if ! rebuild_initramfs; then
        fmtr::log "Failed to rebuild initramfs."
        exit 1
    fi
    fmtr::warn "REBOOT required for changes to take effect"
else
    fmtr::warn "Proceeding without updating initramfs."
fi
