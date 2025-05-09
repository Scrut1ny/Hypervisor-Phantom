

processor_output=$(sudo dmidecode -t 4)
manufacturer=$(echo "$processor_output" | grep 'Manufacturer:' | awk -F': +' '{print $2}')
processor_version=$(echo "$processor_output" | grep 'Version:' | awk -F': +' '{print $2}')
socket_designation=$(echo "$processor_output" | grep 'Socket Designation' | awk -F': +' '{print $2}')
external_clock=$(echo "$processor_output" | grep 'External Clock' | awk -F': +' '{print $2}' | awk '{print $1}')
max_speed=$(echo "$processor_output" | grep 'Max Speed' | awk -F': +' '{print $2}' | awk '{print $1}')
current_speed=$(echo "$processor_output" | grep 'Current Speed' | awk -F': +' '{print $2}' | awk '{print $1}')

memory_output=$(sudo dmidecode -t 17)
locator=$(echo "$memory_output" | grep -m1 '  Locator:' | awk -F': +' '{print $2}')
bank_locator=$(echo "$memory_output" | grep -m1 'Bank Locator:' | awk -F': +' '{print $2}')
manufacturer=$(echo "$memory_output" | grep -m1 'Manufacturer:' | awk -F': +' '{print $2}')
serial=$(echo "$memory_output" | grep -m1 'Serial Number:' | awk -F': +' '{print $2}')
asset_tag=$(echo "$memory_output" | grep -m1 'Asset Tag:' | awk -F': +' '{print $2}')
part_number=$(echo "$memory_output" | grep -m1 'Part Number:' | awk -F': +' '{print $2}')
speed=$(echo "$memory_output" | grep -m1 'Speed:' | awk -F': +' '{print $2}' | awk '{print $1}') # Remove MT/s suffix

uuid=$(uuidgen -r)

sudo virt-xml win10 --edit --qemu-commandline="
    -smbios type=0,uefi='true'
    -smbios type=1,serial='To be filled by 0.E.M.',uuid='$uuid'
    -smbios type=2,serial='To be filled by 0.E.M.'
    -smbios type=3,serial='To be filled by 0.E.M.'
    -smbios type=4,sock_pfx='$socket_designation',manufacturer='$manufacturer',version='$processor_version',max-speed='$max_speed',current-speed='$current_speed'
    -smbios type=17,loc_pfx='Controller0-ChannelA-DIMMO',bank='BANK 0',manufacturer='Samsung',serial='Unknown',asset='Not Specified',part='Not Specified',speed='4800'
    -smbios type=17,loc_pfx='Controller1-ChannelA-DIMMO',bank='BANK 0',manufacturer='Samsung',serial='Unknown',asset='Not Specified',part='Not Specified',speed='4800'
"
