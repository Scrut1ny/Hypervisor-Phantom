configure_vfio() {
    local gpus sel="" pci_bdf group class pci_vendor pci_device_id \
          bad_group=0 bad_functions=()

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

    for dev in /sys/kernel/iommu_groups/$group/devices/*; do
        func=${dev##*/}
        read -r ven_id < "$dev/vendor"
        read -r dev_id < "$dev/device"
        hwids+=("${ven_id:2}:${dev_id:2}")

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
