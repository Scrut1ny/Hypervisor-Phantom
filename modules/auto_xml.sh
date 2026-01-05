#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils.sh"

PRESET_FILE="preset.txt"

fmtr::log "Checking for preset file..."

if [[ -f "$PRESET_FILE" ]]; then
    fmtr::log "Loading presets from ${PRESET_FILE}..."
    source "$PRESET_FILE"
fi

##################################################
##################################################
### CPU Vendor Check

if [[ "$VENDOR_ID" != "GenuineIntel" && "$VENDOR_ID" != "AuthenticAMD" ]]; then
    fmtr::error  "Unsupported CPU vendor: $VENDOR_ID"
    exit 1
fi

fmtr::log "Detected supported CPU vendor: $VENDOR_ID"

##################################################
##################################################
### VM Name Prompt

if [[ -z "$VM_NAME" ]]; then
    fmtr::ask "Enter the name of the new VM:"
    read VM_NAME
fi

##################################################
##################################################
### Template Selection

if [[ "$VENDOR_ID" == "GenuineIntel" ]]; then
    TEMPLATE_FILE="./xml/template/template-intel.xml"
else
    TEMPLATE_FILE="./xml/template/template-amd.xml"
fi
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    error "Template file '${TEMPLATE_FILE}' not found."
    exit 1
fi

fmtr::info "Using template: $TEMPLATE_FILE"

##################################################
##################################################
### CPU Topology

CORES=$(LC_ALL=C lscpu | sed -n 's/^Core(s) per socket:[[:space:]]*//p')
THREADS=$(LC_ALL=C lscpu | sed -n 's/^Thread(s) per core:[[:space:]]*//p')

# Calculate vcpu count = cores * threads
VCPU=$((CORES * THREADS))
fmtr::info "Configuring VM with ${VCPU} vCPUs..."

# Prepare updated XML with VM name and CPU topology
TMP_XML=$(mktemp)
cp "$TEMPLATE_FILE" "$TMP_XML"

# Replace VM name placeholder
sed -i "s|@VM_NAME@|$VM_NAME|g" "$TMP_XML"
fmtr::log "Name set to : $VM_NAME"

# Replace total number of vCPUs
sed -i "s|@TOTAL_NUMBER_OF_CORES@|$VCPU|g" "$TMP_XML"
fmtr::log "Total core set to : $VCPU"

# Replace number of cores per socket
sed -i "s|@NUMBER_OF_CORES@|$CORES|g" "$TMP_XML"
fmtr::log "Number of cores set to : $CORES"

# Replace number of threads per core
sed -i "s|@NUMBER_OF_THREADS@|$THREADS|g" "$TMP_XML"
fmtr::log "Number of threads set to : $THREADS"



# Define VM using updated XML
$ROOT_ESC virsh define "$TMP_XML" &>> "$LOG_FILE"
rm -f "$TMP_XML"
fmtr::info "VM '$VM_NAME' defined with $VCPU vCPUs."
fmtr::info "THIS COULD BE WRONG IF YOU HAVE EFFICIENCY CORES, IF THAT'S THE CASE, GG!"

##################################################
##################################################
### MAC address randomization

# Generate a fully random, locally administered, unicast MAC address.
MAC_ADDRESS=$(printf '02%s\n' "$(hexdump -vn5 -e '5/1 ":%02x"' /dev/urandom)")

# Change the path to the compiled OVMF output/NVRAM + random MAC
$ROOT_ESC virt-xml "$VM_NAME" \
  --edit \
  --xml ./os/nvram/@template="/opt/Hypervisor-Phantom/firmware/OVMF_VARS.qcow2" \
  --xml ./os/loader="/opt/Hypervisor-Phantom/firmware/OVMF_CODE.qcow2" \
  --xml ./devices/interface/mac/@address="$MAC_ADDRESS" &>> "$LOG_FILE"

fmtr::info "MAC address set to $MAC_ADDRESS for VM '$VM_NAME'."

fmtr::info "Done"
