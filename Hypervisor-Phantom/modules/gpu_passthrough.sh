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
  mapfile -t gpus < <(for d in /sys/bus/pci/devices/*; do
    [[ $(<"$d/class") == 0x03* ]] &&
      printf '%s %s\n' "$d" \
        "$(lspci -s ${d##*/} | grep -oP '\[\K[^\]]+(?=\])')"
  done)

  for i in "${!gpus[@]}"; do
    printf '  %d) %s\n' $((i+1)) "${gpus[i]#* }"
  done
  read -rp "$(fmtr::ask 'Select device number: ')" sel; ((sel--))

  local busid=${gpus[sel]%% *}; busid=${busid##*/}
  local group=$(basename "$(readlink -f /sys/bus/pci/devices/$busid/iommu_group)")

  local hwids=$(for d in /sys/kernel/iommu_groups/$group/devices/*; do
            ven=$(<"$d/vendor"); dev=$(<"$d/device")
            printf '%s:%s,' "${ven#0x}" "${dev#0x}"
          done); hwids=${hwids%,}

  printf 'options vfio-pci ids=%s\nsoftdep nvidia pre: vfio-pci\n' "$hwids" | \
    sudo tee $VFIO_CONF_PATH >/dev/null

  export hwids; readonly hwids
}

configure_bootloader() {
    declare -r CPU_VENDOR=$(case "$VENDOR_ID" in
        *AuthenticAMD*) echo "amd" ;;
        *GenuineIntel*) echo "intel" ;;
        *) fmtr::error "Unknown CPU Vendor ID."; exit 1 ;;
    esac)

    if [[ -f "/etc/default/grub" ]]; then
        fmtr::log "Configuring GRUB"
        sudo cp /etc/default/grub{,.bak}
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/& ${CPU_VENDOR}_iommu=on iommu=pt vfio-pci.ids=$hwids /" /etc/default/grub
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
            echo "options ${CPU_VENDOR}_iommu=on iommu=pt vfio-pci.ids=$hwids" | sudo tee -a "$config_file" &>> "$LOG_FILE"

            if [[ -f "/boot/loader/loader.conf" ]]; then
                sudo sed -i "s/^default.*/default $(basename "$config_file")/" /boot/loader/loader.conf
            fi
            return 0
        done
        fmtr::warn "No bootloader configuration found."
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

revert_vfio() {
    if [[ -f "$VFIO_CONF_PATH" ]]; then
        sudo rm -v "$VFIO_CONF_PATH" | tee -a &>> "$LOG_FILE"
    else
        fmtr::log "$VFIO_CONF_PATH doesn't exist; nothing to remove."
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

# Prompt 0: Important disclaimer
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
