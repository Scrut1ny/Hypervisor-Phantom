#!/bin/bash
source "./utils/formatter.sh"
source "./utils/prompter.sh"
source "./utils/packages.sh"
set -e


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

if [[ -z "$CORES" ]]; then
    fmtr::ask "Enter number of CPU cores (e.g. 6):"
    read CORES
fi
if [[ -z "$THREADS" ]]; then
    fmtr::ask "Enter number of CPU threads per core (e.g. 2):"
    read THREADS
fi

VCPU=$((CORES * THREADS))
fmtr::info "Configuring VM with ${VCPU} vCPUs..."

# (continues with rest of your script...)



# Calculate vcpu count = cores * threads
VCPU=$((CORES * THREADS))



# Prepare updated XML with VM name and CPU topology
TMP_XML=$(mktemp)
cp "$TEMPLATE_FILE" "$TMP_XML"

# Inject or replace <name> tag
if grep -q '<name>.*</name>' "$TMP_XML"; then
    sed -i "s|<name>.*</name>|<name>$VM_NAME</name>|" "$TMP_XML"
else
    sed -i "0,/<domain[^>]*>/s|<domain[^>]*>|&\n  <name>$VM_NAME</name>|" "$TMP_XML"
fi

# Replace or add <vcpu> tag
if grep -q '<vcpu.*>.*</vcpu>' "$TMP_XML"; then
    sed -i "s|<vcpu.*>.*</vcpu>|<vcpu placement=\"static\">$VCPU</vcpu>|" "$TMP_XML"
else
    # Insert after <name> tag
    sed -i "0,/<name>.*<\/name>/s|</name>|</name>\n  <vcpu placement=\"static\">$VCPU</vcpu>|" "$TMP_XML"
fi

# Replace or add <topology sockets=... dies=... cores=... threads=... />
if grep -q '<topology[^>]*/>' "$TMP_XML"; then
    # We assume sockets=1 and dies=1 fixed, replace cores and threads
    sed -i "s|<topology[^>]*/>|<topology sockets=\"1\" dies=\"1\" cores=\"$CORES\" threads=\"$THREADS\"/>|" "$TMP_XML"
else
    # Insert topology after <vcpu> tag
    sed -i "0,/<vcpu.*>.*<\/vcpu>/s|</vcpu>|</vcpu>\n  <topology sockets=\"1\" dies=\"1\" cores=\"$CORES\" threads=\"$THREADS\"/>|" "$TMP_XML"
fi



# Define VM using updated XML
sudo virsh define "$TMP_XML" &>> "$LOG_FILE"
rm -f "$TMP_XML"
fmtr::info "VM '$VM_NAME' defined with $VCPU vCPUs."





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
serial=${serial:-$(echo "$memory_output" | grep -m1 'Serial Number:' | awk -F': +' '{print $2}')}
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
    -smbios type=17,loc_pfx='Controller0-ChannelA-DIMMO',bank='BANK 0',manufacturer='${mem_manufacturer:-Samsung}',serial='${serial:-Unknown}',asset='${asset_tag:-Not Specified}',part='${part_number:-Not Specified}',speed='${speed:-4800}'
    -smbios type=17,loc_pfx='Controller1-ChannelA-DIMMO',bank='BANK 0',manufacturer='${mem_manufacturer:-Samsung}',serial='${serial:-Unknown}',asset='${asset_tag:-Not Specified}',part='${part_number:-Not Specified}',speed='${speed:-4800}'
" &>> "$LOG_FILE"





##################################################
##################################################
### MAC address randomization

# Generate a fully random, locally administered, unicast MAC address if not preset already.
if [[ -z "$MAC_ADDRESS" ]]; then
    MAC_ADDRESS=$(printf '02:%02X:%02X:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
fi

# Apply the MAC address to the default network interface using virt-xml
sudo virt-xml "$VM_NAME" --edit --network network=default,mac="$MAC_ADDRESS" &>> "$LOG_FILE"

fmtr::info "MAC address set to $MAC_ADDRESS for VM '$VM_NAME'."

fmtr::info "Done"
