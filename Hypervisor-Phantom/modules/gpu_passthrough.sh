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

    # Collect GPU candidates (PCI class 0x03* = display controllers)
    mapfile -t gpus < <(
        for dev in /sys/bus/pci/devices/*; do
            [[ -r $dev/class && $(<"$dev/class") == 0x03* ]] || continue
            bdf=${dev##*/}
            desc=$(lspci -s "$bdf"); desc=${desc##*[}; desc=${desc%%]*}
            printf '%s %s\n' "$dev" "$desc"
        done
    )

    (( ${#gpus[@]} )) || { fmtr::error "No GPUs detected!"; exit 1; }
    (( ${#gpus[@]} == 1 )) && fmtr::warn "Only one GPU detected! Passing it through will leave the host without display output."

    while :; do
        for i in "${!gpus[@]}"; do
            printf '  %d) %s\n' "$((i+1))" "${gpus[i]#* }"
        done
        read -rp "$(fmtr::ask 'Select device number: ')" sel
        if [[ $sel =~ ^[0-9]+$ && sel -ge 1 && sel -le ${#gpus[@]} ]]; then
            sel=$((sel-1))
            break
        fi
        fmtr::error "Invalid selection. Please choose a valid number."
    done

    pci_bdf="${gpus[sel]%% *}"        # "0000:01:00.0"
    pci_bdf="${pci_bdf##*/}"          # → "01:00.0"
    group=$(basename "$(realpath /sys/bus/pci/devices/$pci_bdf/iommu_group)")
    pci_bus_dev="${pci_bdf%.*}"       # e.g. "01:00"

    for dev in /sys/kernel/iommu_groups/$group/devices/*; do
        func=${dev##*/}
        read -r ven < "$dev/vendor"
        read -r dev_id < "$dev/device"
        hwids+=("${ven:2}:${dev_id:2}")

        [[ ${func%.*} != $pci_bus_dev ]] && { bad_group=1; bad_functions+=("$func"); }
    done
    hwids=$(IFS=,; echo "${hwids[*]}")

    if (( bad_group )); then
        fmtr::error "Bad IOMMU grouping - group #$group contains:"
        printf '\n'
        for f in "${bad_functions[@]}"; do
            printf '  [%s] = %s\n' "$f" "$(lspci -s "$f" -nn)"
        done
        fmtr::warn "VFIO PT requires full group isolation. Possible fixes: ACS override, firmware update, or proper hardware support."
        exit 1
    fi

    fmtr::log "Modifying VFIO config: $VFIO_CONF_PATH"

    if [[ -f /sys/bus/pci/devices/$pci_bdf/vendor ]]; then
        read -r pci_vendor < "/sys/bus/pci/devices/$pci_bdf/vendor"
        declare -A softdeps=(
            ["0x10de"]="nvidia nouveau drm drm_kms_helper" # NVIDIA
            ["0x1002"]="amdgpu radeon drm drm_kms_helper"  # AMD
            ["0x8086"]="i915 drm drm_kms_helper"           # Intel
        )

        {
            printf 'options vfio-pci ids=%s\n' "$hwids"
            for dep in ${softdeps[$pci_vendor]}; do
                printf 'softdep %s pre: vfio-pci\n' "$dep"
            done
        } | sudo tee "$VFIO_CONF_PATH" >>"$LOG_FILE"
    fi
}

configure_bootloader() {
    local cpu_vendor kernel_opts boot_mode="" opts_regex="" config_file

    case "$VENDOR_ID" in
        *AuthenticAMD*) cpu_vendor="amd";;
        *GenuineIntel*) cpu_vendor="intel";;
        *) fmtr::error "Unknown CPU Vendor ID."; return 1;;
    esac

    kernel_opts="${cpu_vendor}_iommu=on iommu=pt vfio-pci.ids=${hwids} kvm.ignore_msrs=1"
    opts_regex='(amd_iommu=on|intel_iommu=on|iommu=pt|vfio-pci.ids=[^ ]*|kvm.ignore_msrs=1)'

    if [[ -f "/etc/default/grub" ]]; then
        boot_mode="grub"
        fmtr::log "Configuring GRUB"
        sudo cp /etc/default/grub{,.bak}

        if ! grep -q "${kernel_opts}" /etc/default/grub; then
            fmtr::log "Cleaning old kernel options from GRUB config..."
            sudo sed -i -E \
                -e "s/(GRUB_CMDLINE_LINUX_DEFAULT=\")([^\"]*)\"/\1\2 /" \
                -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/${opts_regex}//g" \
                -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/  */ /g" \
                -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"[[:space:]]/\"/" \
                /etc/default/grub

            sudo sed -i -E \
                "s|(GRUB_CMDLINE_LINUX_DEFAULT=\")([^\"]*)\"|\1\2 ${kernel_opts}\"|" \
                /etc/default/grub

            fmtr::log "Inserted new kernel options into GRUB config."
        else
            fmtr::log "Kernel options already present in GRUB config. Skipping."
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

        # 1) Remove only the managed opts from the options line(s)
        sudo sed -i -E \
            -e "/^options / s/${opts_regex}//g" \
            -e "/^options / s/  +/ /g" \
            -e "/^options / s/[[:space:]]+$//" \
            "$config_file"

        # 2) Append our clean kernel_opts back to the same options line(s) if missing
        if ! grep -q "^options .*(${cpu_vendor}_iommu=on|iommu=pt|vfio-pci.ids=${hwids}|kvm.ignore_msrs=1)" "$config_file"; then
            sudo sed -i -E \
                -e "/^options / s/$/ ${kernel_opts}/" \
                -e "/^options / s/  +/ /g" \
                "$config_file"
            fmtr::log "Updated kernel options in systemd-boot config."
        else
            fmtr::log "Kernel options already present in systemd-boot config. Skipping append."
        fi
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
