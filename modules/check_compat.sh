#!/usr/bin/env bash

source "./utils.sh"

check_virtualization() {
  fmtr::info "Checking CPU Virtualization Support..."
  
  if grep -E -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
    fmtr::log "CPU supports virtualization (VT-x/AMD-V)."
  else
    fmtr::error "CPU does NOT support virtualization or it is disabled in BIOS."
    return 1
  fi
  
  if lsmod | grep -q kvm; then
    fmtr::log "KVM module is loaded."
  else
    fmtr::warn "KVM module is NOT loaded. It may be loaded automatically later, but check BIOS settings."
  fi
}

check_iommu() {
  fmtr::info "Checking IOMMU Support..."
  
  if [[ -d /sys/kernel/iommu_groups ]]; then
    fmtr::log "IOMMU is enabled and groups are active."
  else
    fmtr::warn "IOMMU does not appear to be enabled. Passthrough will not work without it."
    fmtr::info "Ensure 'intel_iommu=on' or 'amd_iommu=on' is in your kernel boot args."
  fi
}

check_tools() {
  fmtr::info "Checking Essential Tools..."
  
  local tools=(git curl python3 tar make gcc)
  local missing=()
  
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      missing+=("$tool")
    fi
  done
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    fmtr::warn "Missing tools: ${missing[*]}"
    fmtr::info "These will be installed by the setup scripts, but it's good to know."
  else
    fmtr::log "All essential tools found."
  fi
}

main() {
  fmtr::box_text "System Compatibility Check"
  
  check_virtualization
  check_iommu
  check_tools
  
  echo ""
  prmt::quick_prompt "$(fmtr::info 'Press any key to return to menu...')"
}

main
