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

readonly VFIO_KERNEL_OPTS_REGEX='(intel_iommu=[^ ]*|iommu=[^ ]*|vfio-pci.ids=[^ ]*|kvm.ignore_msrs=[^ ]*)'

detect_bootloader() {
    if [[ -f /etc/default/grub ]]; then
        BOOTLOADER_TYPE="grub"
    else
        for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            if [[ -d "$location" ]]; then
                BOOTLOADER_TYPE="systemd-boot"
                export BOOTLOADER_TYPE
                return 0
            fi
        done
        BOOTLOADER_TYPE="unknown"
    fi
    export BOOTLOADER_TYPE
}

detect_bootloader
if [[ "$BOOTLOADER_TYPE" == "unknown" ]]; then
    fmtr::error "No supported bootloader detected (GRUB or systemd-boot). Exiting."
    exit 1
fi
fmtr::log "Detected bootloader: $BOOTLOADER_TYPE"

revert_vfio() {
    if [[ -f "$VFIO_CONF_PATH" ]]; then
        sudo rm -v "$VFIO_CONF_PATH" | tee -a &>> "$LOG_FILE"
        fmtr::log "Removed VFIO Config: $VFIO_CONF_PATH"
    else
        fmtr::log "$VFIO_CONF_PATH doesn't exist; nothing to remove."
    fi

    if [[ -f "/etc/default/grub" ]]; then
        sudo sed -E -i \
            -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ {
                    s/($VFIO_KERNEL_OPTS_REGEX)//g;
                    s/[[:space:]]+/ /g;
                    s/\"[[:space:]]+/\"/;
                    s/[[:space:]]+\"/\"/
                }" \
            /etc/default/grub
        fmtr::log "Removed VFIO kernel opts from GRUB config."
    else
        for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            [[ -d "$location" ]] || continue
            local config_file
            config_file=$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)
            [[ -z "$config_file" ]] && continue

            sudo sed -E -i \
                -e "/^options / {
                        s/($VFIO_KERNEL_OPTS_REGEX)//g;   # remove old managed options
                        s/[[:space:]]+/ /g;               # normalize whitespace
                        s/ options /options /;            # ensure 'options ' prefix correct
                        s/[[:space:]]+$//;                # trim trailing space
                    }" \
                "$config_file"

            fmtr::log "Removed VFIO kernel opts from: $config_file"
        done
    fi
}

configure_vfio() {
    local gpus sel="" pci_bdf group pci_bus_dev bad_group=0 bad_functions=()

    # Collect GPU candidates (PCI class 0x03* = display controllers)
    mapfile -t gpus < <(
        for dev in /sys/bus/pci/devices/*; do
            [[ -r "$dev/class" && $(<"$dev/class") == 0x03* ]] || continue
            local bdf pci_desc
            bdf=${dev##*/}
            pci_desc=$(lspci -s "$bdf")
            pci_desc=${pci_desc##*[}
            pci_desc=${pci_desc%%]*}
            printf '%s %s\n' "$dev" "$pci_desc"
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

    pci_bdf="${gpus[sel]%% *}"
    pci_bdf="${pci_bdf##*/}"
    group=$(basename "$(readlink -f /sys/bus/pci/devices/$pci_bdf/iommu_group)")
    pci_bus_dev="${pci_bdf%.*}"

    hwids=($(for dev in /sys/kernel/iommu_groups/$group/devices/*; do
        func=${dev##*/}
        read -r ven_id < "$dev/vendor"
        read -r dev_id < "$dev/device"
        printf '%s:%s ' "${ven_id:2}" "${dev_id:2}"

        [[ ${func%.*} != $pci_bus_dev ]] && { bad_group=1; bad_functions+=("$func"); }
    done))
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

        export VFIO_CONF_CHANGED=1
    fi
}

configure_bootloader() {
    local kernel_opts kernel_opts_str
    kernel_opts=( "iommu=pt" "vfio-pci.ids=${hwids}" "kvm.ignore_msrs=1" )
    [[ "$VENDOR_ID" == *GenuineIntel* ]] && kernel_opts=( "intel_iommu=on" "${kernel_opts[@]}" )
    kernel_opts_str="${kernel_opts[*]}"

    if [[ "$BOOTLOADER_TYPE" == "grub" ]]; then
        fmtr::log "Configuring GRUB"

        if ! sudo grep -q -F "$kernel_opts_str" /etc/default/grub; then
            sudo sed -E -i \
                -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ {
                        s/^[^=]+=//; s/^\"//; s/\"$//;
                        s/($VFIO_KERNEL_OPTS_REGEX)//g; s/[[:space:]]+/ /g;
                        s/^/GRUB_CMDLINE_LINUX_DEFAULT=\"/;
                        s/$/ ${kernel_opts_str}\"/
                    }" \
                /etc/default/grub
            fmtr::log "Inserted new kernel opts into GRUB config."
            export BOOTLOADER_CHANGED=1
        else
            fmtr::log "Kernel opts already present in GRUB config. Skipping."
        fi
    elif [[ "$BOOTLOADER_TYPE" == "systemd-boot" ]]; then
        for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
            [[ -d "$location" ]] || continue
            local config_file
            config_file=$(sudo find "$location" -maxdepth 1 -type f -name '*.conf' ! -name '*-fallback.conf' -print -quit)
            [[ -z "$config_file" ]] && fmtr::warn "No configuration file found in $location" && continue

            fmtr::log "Modifying systemd-boot config: $config_file"

            sudo sed -E -i \
                -e "/^options / {
                        s/($VFIO_KERNEL_OPTS_REGEX)//g;
                        s/[[:space:]]+/ /g;
                        s/ options /options /;
                        s/[[:space:]]+$//
                    }" \
                "$config_file"

            if ! sudo grep -q -E "^options .*${kernel_opts[0]}" "$config_file"; then
                sudo sed -E -i -e "/^options / s/$/ ${kernel_opts_str}/" "$config_file"
                fmtr::log "Updated kernel opts in systemd-boot config."
            else
                fmtr::log "Kernel opts already present in systemd-boot config. Skipping append."
            fi
        done
    fi
}

rebuild_bootloader() {
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

# ----- MAIN PROMPTS -----

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

# Prompt 3 - Rebuild bootloader config? (only for GRUB)
if [[ "$BOOTLOADER_TYPE" == "grub" && "$BOOTLOADER_CHANGED" == "1" ]]; then
    if prmt::yes_or_no "$(fmtr::ask 'Proceed with rebuilding GRUB bootloader config?')"; then
        if ! rebuild_bootloader; then
            fmtr::log "Failed to update GRUB configuration."
            exit 1
        fi
        fmtr::warn "REBOOT required for changes to take effect"
    else
        fmtr::warn "Proceeding without updating GRUB bootloader."
    fi
elif [[ "$BOOTLOADER_TYPE" == "grub" ]]; then
    fmtr::log "No changes detected in GRUB config; skipping rebuild prompt."
else
    fmtr::log "Detected systemd-boot; no bootloader rebuild required."
fi
