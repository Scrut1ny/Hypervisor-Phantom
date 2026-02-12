#!/usr/bin/env bash

source ./utils.sh || { echo "Failed to load utilities module!"; exit 1; }

readonly VFIO_CONF_PATH="/etc/modprobe.d/vfio.conf"
readonly VFIO_KERNEL_OPTS_REGEX='(intel_iommu=[^ ]*|iommu=[^ ]*)'

readonly -a SDBOOT_CONF_LOCATIONS=(
    /boot/loader/entries
    /boot/efi/loader/entries
    /efi/loader/entries
)

declare -A GPU_DRIVERS=(
    ["0x10de"]="nouveau nvidia nvidia_drm"
    ["0x1002"]="amdgpu radeon"
    ["0x8086"]="i915"
)

################################################################################
# Bootloader Detection
################################################################################
detect_bootloader() {
    [[ -f /etc/default/grub ]] && BOOTLOADER_TYPE=grub || {
        for dir in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            [[ -d $dir ]] || continue
            BOOTLOADER_TYPE=systemd-boot SYSTEMD_BOOT_ENTRY_DIR=$dir
            break
        done
        [[ $SYSTEMD_BOOT_ENTRY_DIR ]] || { fmtr::error "No supported bootloader detected (GRUB or systemd-boot). Exiting."; exit 1; }
    }
}

################################################################################
# Revert VFIO Configurations
################################################################################
revert_vfio() {
    if [[ -f $VFIO_CONF_PATH ]]; then
        $ROOT_ESC rm -v "$VFIO_CONF_PATH" &>>"$LOG_FILE"
        fmtr::log "Removed VFIO Config: $VFIO_CONF_PATH"
    else
        fmtr::log "$VFIO_CONF_PATH doesn't exist; nothing to remove."
    fi

    if [[ $BOOTLOADER_TYPE == grub ]]; then
        $ROOT_ESC sed -E -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/{
            s/'"$VFIO_KERNEL_OPTS_REGEX"'//g
            s/[[:space:]]+/ /g
            s/"[[:space:]]+/"
            s/[[:space:]]+"/"/
        }' /etc/default/grub
        fmtr::log "Removed VFIO kernel opts from GRUB config."

    elif [[ $BOOTLOADER_TYPE == systemd-boot && $SYSTEMD_BOOT_ENTRY_DIR ]]; then
        local config_file
        config_file=$(
            find "$SYSTEMD_BOOT_ENTRY_DIR" -maxdepth 1 \
                -name '*.conf' ! -name '*-fallback.conf' -print -quit
        )

        if [[ -z $config_file ]]; then
            fmtr::warn "No configuration file found in $SYSTEMD_BOOT_ENTRY_DIR"
            return
        fi

        $ROOT_ESC sed -E -i "/^options / {
            s/$VFIO_KERNEL_OPTS_REGEX//g;
            s/[[:space:]]+/ /g;
            s/[[:space:]]+$//;
        }" "$config_file"
        fmtr::log "Removed VFIO kernel opts from: $config_file"
    fi
}

################################################################################
# Configure VFIO
################################################################################
configure_vfio() {
    local dev bdf desc sel target_bdf iommu_group vendor_id device_id pci_vendor bad=0
    local -a gpus=() badf=() ids=()

    # Discover GPUs
    for dev in /sys/bus/pci/devices/*; do
        [[ $(<"$dev/class") == 0x03* ]] || continue
        bdf=${dev##*/}
        desc=$(lspci -s "$bdf" 2>/dev/null) || continue
        desc=${desc##*[}; desc=${desc%%]*}
        gpus+=("$bdf|$desc")
    done

    (( ${#gpus[@]} )) || { fmtr::error "No GPUs detected!"; exit 1; }
    (( ${#gpus[@]} == 1 )) && fmtr::warn "Only one GPU detected! Passing it through will leave the host without display output."

    # GPU selection
    while :; do
        for dev in "${!gpus[@]}"; do printf '\n  %d) %s\n' "$((dev+1))" "${gpus[dev]#*|}"; done
        read -rp "$(fmtr::ask 'Select device number: ')" sel
        (( sel >= 1 && sel <= ${#gpus[@]} )) 2>/dev/null && break
        fmtr::error "Invalid selection. Please choose a valid number."
    done

    target_bdf=${gpus[sel-1]%%|*}
    iommu_group=$(readlink -f "/sys/bus/pci/devices/$target_bdf/iommu_group")
    iommu_group=${iommu_group##*/}

    # Collect device IDs & validate IOMMU group isolation
    for dev in "/sys/kernel/iommu_groups/$iommu_group/devices/"*; do
        bdf=${dev##*/}
        read -r vendor_id < "$dev/vendor"
        read -r device_id < "$dev/device"
        ids+=("${vendor_id#0x}:${device_id#0x}")
        [[ $bdf == "${target_bdf%.*}".* ]] || { bad=1; badf+=("$bdf"); }
    done

    if (( bad )); then
        fmtr::error "Detected poor IOMMU grouping! IOMMU group #$iommu_group contains:\n
$(printf '  [%s]\n' "${badf[@]}")"
        fmtr::warn "VFIO PT requires full group isolation. Possible solutions:
      BIOS update, ACS override kernel patch, or new motherboard."
        return 1
    fi

    # Write VFIO config
    fmtr::log "Modifying VFIO config: $VFIO_CONF_PATH"
    read -r pci_vendor < "/sys/bus/pci/devices/$target_bdf/vendor" || return 1

    {
        printf 'options vfio-pci ids=%s disable_vga=1\n' "$(IFS=,; echo "${ids[*]}")"
        for soft in ${GPU_DRIVERS[$pci_vendor]:-}; do printf 'softdep %s pre: vfio-pci\n' "$soft"; done
    } | $ROOT_ESC tee "$VFIO_CONF_PATH" >> "$LOG_FILE"

    # sudo sed -i 's/^MODULES=()$/MODULES=(vfio vfio_iommu_type1 vfio_pci)/' /etc/mkinitcpio.conf
    # sudo mkinitcpio -P
}

################################################################################
# Bootloader Configuration
################################################################################
configure_bootloader() {
    local -a kernel_opts
    kernel_opts=( "iommu=pt" )
    [[ "$CPU_VENDOR_ID" == "GenuineIntel" ]] && kernel_opts=( "intel_iommu=on" "${kernel_opts[@]}" )

    local kernel_opts_str="${kernel_opts[*]}"

    if [[ "$BOOTLOADER_TYPE" == "grub" ]]; then
        fmtr::log "Configuring GRUB config: /etc/default/grub"

        $ROOT_ESC sed -E -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ {
            s/^GRUB_CMDLINE_LINUX_DEFAULT=//;
            s/^\"//; s/\"$//;
            s/$VFIO_KERNEL_OPTS_REGEX//g;
            s/[[:space:]]+/ /g;
            s/[[:space:]]+$//;
            s|^|GRUB_CMDLINE_LINUX_DEFAULT=\"|;
            s|$| ${kernel_opts_str}\"|;
        }" /etc/default/grub

        export BOOTLOADER_CHANGED=1

    elif [[ "$BOOTLOADER_TYPE" == "systemd-boot" ]]; then
        [[ -z "$SYSTEMD_BOOT_ENTRY_DIR" || ! -d "$SYSTEMD_BOOT_ENTRY_DIR" ]] && {
            fmtr::error "Systemd-boot entry directory is not set or doesn't exist."
            return 1
        }

        local config_file
        config_file=$(find "$SYSTEMD_BOOT_ENTRY_DIR" -maxdepth 1 -type f -name '*.conf' ! -name '*-fallback.conf' -print -quit)

        [[ -z "$config_file" ]] && {
            fmtr::warn "No configuration file found in $SYSTEMD_BOOT_ENTRY_DIR"
            return 0
        }

        fmtr::log "Configuring systemd-boot config: $config_file"

        $ROOT_ESC sed -E -i "/^options / {
            s/$VFIO_KERNEL_OPTS_REGEX//g;
            s/[[:space:]]+/ /g;
            s/[[:space:]]+$//;
            s/$/ ${kernel_opts_str}/;
        }" "$config_file"
    fi
}

################################################################################
# Rebuild Bootloader Configuration
################################################################################
rebuild_bootloader() {
    fmtr::log "Updating bootloader configuration for GRUB."

    local cmd prefix
    for prefix in "" 2; do
        cmd="grub${prefix}-mkconfig"
        command -v "$cmd" &>>"$LOG_FILE" || continue
        $ROOT_ESC "$cmd" -o "/boot/grub${prefix}/grub.cfg" &>>"$LOG_FILE" && { fmtr::log "Bootloader configuration updated."; return; }
    done

    fmtr::error "No known GRUB configuration command found on this system."
    return 1
}

################################################################################
# Main Script
################################################################################
detect_bootloader

# Prompt 1 - Remove VFIO config?
prmt::yes_or_no "$(fmtr::ask 'Remove GPU PT/VFIO configs?')" && revert_vfio

# Prompt 2 - Configure VFIO config?
if prmt::yes_or_no "$(fmtr::ask 'Configure GPU PT/VFIO now?')"; then
    configure_vfio || { fmtr::log "Configuration aborted during device selection."; exit 1; }
    configure_bootloader || { fmtr::log "Bootloader configuration aborted."; exit 1; }
fi

# Prompt 3 - Rebuild bootloader config?
if [[ "$BOOTLOADER_TYPE" == "grub" && "$BOOTLOADER_CHANGED" == "1" ]]; then
    if prmt::yes_or_no "$(fmtr::ask 'Proceed with rebuilding GRUB bootloader config?')"; then
        rebuild_bootloader || { fmtr::log "Failed to update GRUB configuration."; exit 1; }
        fmtr::warn "REBOOT required for changes to take effect"
    else
        fmtr::warn "Proceeding without updating GRUB bootloader."
    fi
elif [[ "$BOOTLOADER_TYPE" == "grub" ]]; then
    fmtr::log "No changes detected in GRUB config; skipping rebuild prompt."
else
    fmtr::log "Detected systemd-boot; no bootloader rebuild required."
fi
