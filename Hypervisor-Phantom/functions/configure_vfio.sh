#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && exit 1

source "./utils/formatter.sh"
source "./utils/prompter.sh"

readonly VFIO_CONF_PATH='/etc/modprobe.d/vfio.conf'
readonly SDBOOT_CONF_LOCATIONS=(
  "/boot/loader/entries"
  "/boot/efi/loader/entries"
  "/efi/loader/entries"
)

isolate_gpu() {
  while true; do
    fmtr::log "Select device type:\n\n  1) GPUs/iGPUs\n  2) NVMe SSDs\n  3) All PCI devices"
    read -rp "$(fmtr::ask 'Enter your choice (1-3): ')" choice

    if [[ ! "$choice" =~ ^[1-3]$ ]]; then
      fmtr::warn "Invalid choice. Please select a valid option."
      continue
    fi

    case "$choice" in
      1) pci_device="$(lspci | grep -iE 'vga|3d' | sort)";;
      2) pci_device="$(lspci | grep -i "Non-Volatile memory" | sort)";;
      3) pci_device="$(lspci | sort)";;
    esac

    fmtr::log "Available devices:"
    echo "" && echo "$pci_device" | nl -w2 -s') ' | sed 's/^/ /'

    read -rp "$(fmtr::ask 'Select a device by number: ')" selection
    bus_number="$(echo "$pci_device" | sed -n "${selection}p" | awk '{print $1}' | cut -d':' -f1)"

    HWID="$(lspci -nn | grep -E "^${bus_number}:[0-9a-f]{2}.[0-9a-f]" | sed -n 's/.*\[\([0-9a-f:]*\)\].*/\1/p' | paste -sd, -)"

    echo -e "options vfio-pci ids=${HWID}\nsoftdep nvidia pre: vfio-pci" | sudo tee -a "$VFIO_CONF_PATH" &>> "$LOG_FILE"
    fmtr::log "Configured '/etc/modprobe.d/vfio.conf'"

    #if ! prmt::yes_or_no "$(fmtr::ask 'Would you like to passthrough more PCI devices?')"; then
    #  break
    #fi

    break
  done
}

configure_bootloader() {
  fmtr::log "Configuring the bootloader entry config"

  declare -r CPU_VENDOR=$(case "$VENDOR_ID" in
    AuthenticAMD) IOMMU_SETTING="amd_iommu=on" ;;
    GenuineIntel) IOMMU_SETTING="intel_iommu=on" ;;
    *) fmtr::error "Unknown CPU vendor."; exit 1 ;;
  esac)

  if [ -f "/etc/default/grub" ]; then
    fmtr::log "GRUB detected."
    sudo cp /etc/default/grub /etc/default/grub.bak
    sudo sed -i "/etc/default/grub" -f - <<EOF
s#^\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"\$#\1 ${IOMMU_SETTING} iommu=pt vfio-pci.ids=${HWID} "#
EOF
    sudo update-grub || fmtr::warn "You have to manually update the GRUB config!"
    fmtr::log "GRUB configuration modified successfully."
  else
    for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
      if sudo [ -d "$location" ]; then
        fmtr::log "Systemd-boot detected at '${location}'."

        local config_file="$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)"

        if [ -z "$config_file" ]; then
          fmtr::warn "No non-fallback configuration file found in '${location}'."
          return 1
        fi

        sudo cp "$config_file" "${config_file}.bak"
        fmtr::log "Modifying file: ${config_file}"
        echo "options ${IOMMU_SETTING} iommu=pt vfio-pci.ids=${HWID}" | sudo tee -a "$config_file" &>> "$LOG_FILE"
        fmtr::log "Systemd-boot configuration updated successfully."

        # Set the modified config as default in /boot/loader/loader.conf
        if sudo [ -f "/boot/loader/loader.conf" ]; then
          sudo sed -i "/^default/c\default $(basename "$config_file")" /boot/loader/loader.conf
          fmtr::log "Set $(basename "$config_file") as the default boot entry in loader.conf."
        fi

        return 0
      fi
    done
    fmtr::warn "No recognized bootloader configuration found."
    return 1
  fi
}

regenerate_ramdisks() {
  fmtr::log "Updating bootloader config and ramdisk."

  case "$DISTRO" in
    Arch)
      sudo grub-mkconfig -o /boot/grub/grub.cfg &>> "$LOG_FILE" # Grub
      sudo mkinitcpio -P &>> "$LOG_FILE" # Systemd
      sudo reinstall-kernels &>> "$LOG_FILE" # EndeavourOS
      ;;
    Debian)
      sudo update-grub &>> "$LOG_FILE"
      sudo update-initramfs -u &>> "$LOG_FILE"
      ;;
    Fedora)
      sudo grub2-mkconfig -o /boot/grub2/grub.cfg &>> "$LOG_FILE"
      sudo dracut -f &>> "$LOG_FILE"
      ;;
    *)
      fmtr::error "Distribution not recognized or not supported by this script."
      return 1
      ;;
  esac
}

revert_vfio() {
  if [ -f "$VFIO_CONF_PATH" ]; then
    sudo rm "$VFIO_CONF_PATH"
    fmtr::log "Deleted '${VFIO_CONF_PATH}'"
  else
    fmtr::log "'${VFIO_CONF_PATH}' has already been deleted."
  fi

  if [ -f "/etc/default/grub" ]; then
    fmtr::log "GRUB detected."
    sudo sed -i '/etc/default/grub' -f - <<EOF
/GRUB_CMDLINE_LINUX_DEFAULT/\
s/\(amd_iommu\|intel_iommu\|iommu\|vfio-pci.ids\)=[^ ]*//g
EOF
    fmtr::log "Removed config from '/etc/default/grub'."
  else
    for location in "${SDBOOT_CONF_LOCATIONS[@]}"; do
      if sudo [ -d "$location" ]; then
        fmtr::log "Systemd-boot detected at '${location}'."
        local config_file="$(sudo find "$location" -maxdepth 1 -name '*.conf' ! -name '*-fallback.conf' -print -quit)"

        if [ -z "$config_file" ]; then
          fmtr::warn "No non-fallback configuration file found in '${location}'."
          return 1
        fi

        fmtr::log "Modifying file: ${config_file}"
        sudo sed -i '/options/ {/amd_iommu\|intel_iommu\|iommu\|vfio-pci.ids/d}' "$config_file"
        fmtr::log "Systemd-boot configuration updated successfully."
      fi
    done
  fi

  # Disable early loading of VFIO driver
  local initramfs_file
  for initramfs_file in /boot/initramfs-*; do
    if [[ -f "$initramfs_file" ]]; then
      sudo sed -i '/vfio-pci/d' "$initramfs_file"
    fi
  done

  regenerate_ramdisks
}

# Main logic
if prmt::yes_or_no "$(fmtr::ask 'Do you want to remove VFIO configs? (undo PCI passthrough)')"; then
  revert_vfio
  if prmt::yes_or_no "$(fmtr::ask 'Do you want to re-configure VFIO now?')"; then
    isolate_gpu
    configure_bootloader
    regenerate_ramdisks
  else
    fmtr::log 'Skipping VFIO configuration.'
  fi
else
  isolate_gpu
  configure_bootloader
  regenerate_ramdisks
fi

fmtr::warn "REBOOT for vfio-pci Kernel driver to take effect."
