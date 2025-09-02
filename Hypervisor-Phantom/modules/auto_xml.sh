#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils/formatter.sh"
source "./utils/prompter.sh"

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

CORES=$(lscpu --json | jq -r '[.lscpu[] | select(.field=="Core(s) per socket:") | .data] | join(" ")')

THREADS=$(lscpu --json | jq -r '[.lscpu[] | select(.field=="Thread(s) per core:") | .data] | join(" ")')



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
sudo virsh define "$TMP_XML" &>> "$LOG_FILE"
rm -f "$TMP_XML"
fmtr::info "VM '$VM_NAME' defined with $VCPU vCPUs."


fmtr::info "THIS COULD BE WRONG IF YOU HAVE EFFICIENCY CORES, IF THAT'S THE CASE, GG!"




##################################################
##################################################
### SMBIOS DATA

# CPU Info
processor_output=$(sudo dmidecode -t 4)
cpu_manufacturer=${cpu_manufacturer:-$(echo "$processor_output" | grep 'Manufacturer:' | awk -F': +' '{print $2}')}

# Libvirt XML doesn't allow commas in strings unless they're escaped with another comma.
if [[ "$cpu_manufacturer" == "Advanced Micro Devices, Inc."* ]]; then
    cpu_manufacturer="Advanced Micro Devices,, Inc."
fi

cpu_version=${cpu_version:-$(echo "$processor_output" | grep 'Version:' | awk -F': +' '{print $2}')}
socket_designation=${socket_designation:-$(echo "$processor_output" | grep 'Socket Designation:' | awk -F': +' '{print $2}')}
external_clock=${external_clock:-$(echo "$processor_output" | grep 'External Clock:' | awk -F': +' '{print $2}' | awk '{print $1}')}
max_speed=${max_speed:-$(echo "$processor_output" | grep 'Max Speed:' | awk -F': +' '{print $2}' | awk '{print $1}')}
current_speed=${current_speed:-$(echo "$processor_output" | grep 'Current Speed:' | awk -F': +' '{print $2}' | awk '{print $1}')}

# Memory Info
memory_output=$(sudo dmidecode -t 17)
locator=${locator:-$(echo "$memory_output" | grep -m1 'Locator:' | awk -F': +' '{print $2}')}
bank_locator=${bank_locator:-$(echo "$memory_output" | grep -m1 'Bank Locator:' | awk -F': +' '{print $2}')}
mem_manufacturer=${mem_manufacturer:-$(echo "$memory_output" | grep -m1 'Manufacturer:' | awk -F': +' '{print $2}')}
asset_tag=${asset_tag:-$(echo "$memory_output" | grep -m1 'Asset Tag:' | awk -F': +' '{print $2}')}
part_number=${part_number:-$(echo "$memory_output" | grep -m1 'Part Number:' | awk -F': +' '{print $2}')}
speed=${speed:-$(echo "$memory_output" | grep -m1 'Speed:' | awk -F': +' '{print $2}' | awk '{print $1}')}

# UUID generation if not preset
uuid=${uuid:-$(uuidgen -r)}

# Inject SMBIOS into VM
sudo virt-xml "$VM_NAME" --edit --qemu-commandline="
    -smbios type=0,uefi='true'
    -smbios type=1,serial='To be filled by O.E.M.',uuid='$uuid'
    -smbios type=2,serial='To be filled by O.E.M.'
    -smbios type=3,serial='To be filled by O.E.M.'
    -smbios type=4,sock_pfx='$socket_designation',manufacturer='$cpu_manufacturer',version='$cpu_version',max-speed='$max_speed',current-speed='$current_speed'
    -smbios type=17,loc_pfx='Controller0-ChannelA-DIMMO',bank='BANK 0',manufacturer='${mem_manufacturer:-Samsung}',serial='Unknown',asset='${asset_tag:-Not Specified}',part='${part_number:-Not Specified}',speed='${speed:-4800}'
    -smbios type=17,loc_pfx='Controller1-ChannelA-DIMMO',bank='BANK 0',manufacturer='${mem_manufacturer:-Samsung}',serial='Unknown',asset='${asset_tag:-Not Specified}',part='${part_number:-Not Specified}',speed='${speed:-4800}'
" &>> "$LOG_FILE"





##################################################
##################################################
### MAC address randomization

# Generate a fully random, locally administered, unicast MAC address.
MAC_ADDRESS=$(printf '02%s\n' "$(hexdump -vn5 -e '5/1 ":%02x"' /dev/urandom)")

# Apply the MAC address to the default network interface using virt-xml
sudo virt-xml "$VM_NAME" --edit --network network=default,mac="$MAC_ADDRESS" &>> "$LOG_FILE"

fmtr::info "MAC address set to $MAC_ADDRESS for VM '$VM_NAME'."

fmtr::info "Done"
