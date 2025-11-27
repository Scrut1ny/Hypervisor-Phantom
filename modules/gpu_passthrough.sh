#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils/formatter.sh"
source "./utils/prompter.sh"

readonly VFIO_CONF_PATH="/etc/modprobe.d/vfio.conf"
readonly VFIO_KERNEL_OPTS_REGEX='(intel_iommu=[^ ]*|iommu=[^ ]*|vfio-pci.ids=[^ ]*|kvm.ignore_msrs=[^ ]*)'
readonly -a SDBOOT_CONF_LOCATIONS=(/boot/loader/entries /boot/efi/loader/entries /efi/loader/entries)

# Global variables (need to persist across functions)
hwids=""
declare -A SOFTDEPS=(
    ["0x10de"]="nouveau nvidia nvidia_drm drm drm_kms_helper"
    ["0x1002"]="amdgpu radeon drm drm_kms_helper"
    ["0x8086"]="i915 drm drm_kms_helper"
)

################################################################################
# Bootloader Detection
################################################################################
detect_bootloader() {
    if [[ -f /etc/default/grub ]]; then
        BOOTLOADER_TYPE="grub"
    else
        for dir in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            if [[ -d $dir ]]; then
                BOOTLOADER_TYPE="systemd-boot"
                SYSTEMD_BOOT_ENTRY_DIR=$dir
                break
            fi
        done
        [[ -z $SYSTEMD_BOOT_ENTRY_DIR ]] && { fmtr::error "No supported bootloader detected (GRUB or systemd-boot). Exiting."; exit 1; }
    fi
    export BOOTLOADER_TYPE SYSTEMD_BOOT_ENTRY_DIR
}

################################################################################
# Revert VFIO Configurations
################################################################################
revert_vfio() {
    if [[ -f $VFIO_CONF_PATH ]]; then
        rm -v "$VFIO_CONF_PATH" &>> "$LOG_FILE"
        fmtr::log "Removed VFIO Config: $VFIO_CONF_PATH"
    else
        fmtr::log "$VFIO_CONF_PATH doesn't exist; nothing to remove."
    fi

    if [[ $BOOTLOADER_TYPE == "grub" ]]; then
        sed -E -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ {
            s/$VFIO_KERNEL_OPTS_REGEX//g;
            s/[[:space:]]+/ /g;
            s/\"[[:space:]]+/\"/;
            s/[[:space:]]+\"/\"/;
        }" /etc/default/grub

        fmtr::log "Removed VFIO kernel opts from GRUB config."

    elif [[ $BOOTLOADER_TYPE == "systemd-boot" && -n $SYSTEMD_BOOT_ENTRY_DIR ]]; then
        local config_file
        config_file=$(find "$SYSTEMD_BOOT_ENTRY_DIR" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)

        [[ -z $config_file ]] && {
            fmtr::warn "No configuration file found in $SYSTEMD_BOOT_ENTRY_DIR"
            return
        }

        sed -E -i "/^options / {
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
    local -a gpus
    local sel pci_bdf group pci_bus_dev bad_group=0 pci_vendor
    local -a bad_functions=() local_hwids=()

    # Detect all GPUs - optimized with single pass
    mapfile -t gpus < <(
        for dev in /sys/bus/pci/devices/*; do
            [[ -r "$dev/class" ]] || continue
            local class=$(<"$dev/class")
            [[ $class == 0x03* ]] || continue

            local bdf=${dev##*/}
            local pci_desc
            pci_desc=$(lspci -s "$bdf" 2>/dev/null) || continue
            pci_desc=${pci_desc##*[}
            pci_desc=${pci_desc%%]*}
            printf '%s %s\n' "$dev" "$pci_desc"
        done
    )

    (( ${#gpus[@]} )) || { fmtr::error "No GPUs detected!"; exit 1; }
    (( ${#gpus[@]} == 1 )) && fmtr::warn "Only one GPU detected! Passing it through will leave the host without display output."

    # Prompt user to select GPU
    while :; do
        for i in "${!gpus[@]}"; do
            printf '  %d) %s\n' "$((i+1))" "${gpus[i]#* }"
        done
        read -rp "$(fmtr::ask 'Select device number: ')" sel
        if [[ $sel =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#gpus[@]} )); then
            break
        fi
        fmtr::error "Invalid selection. Please choose a valid number."
    done
    sel=$((sel - 1))

    # Extract PCI BDF, IOMMU group, and gather devices
    pci_bdf="${gpus[sel]%% *}"; pci_bdf="${pci_bdf##*/}"
    group=$(basename "$(readlink -f "/sys/bus/pci/devices/$pci_bdf/iommu_group")")
    pci_bus_dev="${pci_bdf%.*}"

    # Gather all devices in the IOMMU group
    for dev in /sys/kernel/iommu_groups/$group/devices/*; do
        local func=${dev##*/}
        local ven_id dev_id
        ven_id=$(<"$dev/vendor")
        dev_id=$(<"$dev/device")
        local_hwids+=("${ven_id:2}:${dev_id:2}")

        [[ "${func%.*}" != "$pci_bus_dev" ]] && {
            bad_group=1
            bad_functions+=("$func")
        }
    done

    # Validate group isolation
    if (( bad_group )); then
        fmtr::error "Bad IOMMU grouping - group #$group contains:\n$(printf '  [%s]\n' "${bad_functions[@]}")"
        fmtr::warn "VFIO PT requires full group isolation. Fix with ACS override, firmware update, or proper hardware support."
        return 1
    fi

    fmtr::log "Modifying VFIO config: $VFIO_CONF_PATH"

    # Get vendor ID and build hwids
    [[ -f /sys/bus/pci/devices/$pci_bdf/vendor ]] || return 1
    read -r pci_vendor < "/sys/bus/pci/devices/$pci_bdf/vendor"
    hwids=$(IFS=,; echo "${local_hwids[*]}")

    # Generate VFIO configuration
    {
        printf 'options vfio-pci ids=%s\n' "$hwids"
        local softdep_list=${SOFTDEPS[$pci_vendor]}
        [[ -n $softdep_list ]] && for dep in $softdep_list; do
            printf 'softdep %s pre: vfio-pci\n' "$dep"
        done
    } | tee "$VFIO_CONF_PATH" >> "$LOG_FILE"

    export VFIO_CONF_CHANGED=1
}

################################################################################
# Bootloader Configuration
################################################################################
configure_bootloader() {
    local -a kernel_opts
    kernel_opts=( "iommu=pt" "vfio-pci.ids=${hwids}" "kvm.ignore_msrs=1" )
    [[ "$VENDOR_ID" == *GenuineIntel* ]] && kernel_opts=( "intel_iommu=on" "${kernel_opts[@]}" )

    local kernel_opts_str="${kernel_opts[*]}"

    if [[ "$BOOTLOADER_TYPE" == "grub" ]]; then
        fmtr::log "Configuring GRUB"

        if ! grep -Eq "^GRUB_CMDLINE_LINUX_DEFAULT=.*${kernel_opts[1]}" /etc/default/grub; then
            sed -E -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/ {
                s/^GRUB_CMDLINE_LINUX_DEFAULT=//;
                s/^\"//; s/\"$//;
                s/$VFIO_KERNEL_OPTS_REGEX//g;
                s/[[:space:]]+/ /g;
                s/[[:space:]]+$//;
                s|^|GRUB_CMDLINE_LINUX_DEFAULT=\"|;
                s|$| ${kernel_opts_str}\"|;
            }" /etc/default/grub

            fmtr::log "Inserted new VFIO kernel opts into GRUB config."
            export BOOTLOADER_CHANGED=1
        else
            fmtr::log "VFIO kernel opts already present in GRUB config. Skipping."
        fi

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

        fmtr::log "Modifying systemd-boot config: $config_file"

        sed -E -i "/^options / {
            s/$VFIO_KERNEL_OPTS_REGEX//g;
            s/[[:space:]]+/ /g;
            s/[[:space:]]+$//;
        }" "$config_file"

        if ! grep -q -E "^options .*${kernel_opts[1]}" "$config_file"; then
            sed -E -i -e "/^options / s/$/ ${kernel_opts_str}/" "$config_file"
            fmtr::log "Appended VFIO kernel opts to systemd-boot config."
        else
            fmtr::log "VFIO kernel opts already present in systemd-boot config. Skipping append."
        fi
    fi
}

################################################################################
# Rebuild Bootloader Configuration
################################################################################
rebuild_bootloader() {
    fmtr::log "Updating bootloader configuration for GRUB."

    local cmd prefix
    for prefix in "" "2"; do
        cmd="grub${prefix}-mkconfig"
        if command -v "$cmd" &>> "$LOG_FILE"; then
            "$cmd" -o /boot/grub${prefix}/grub.cfg &>> "$LOG_FILE" && {
                fmtr::log "Bootloader configuration updated."
                return 0
            }
        fi
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
