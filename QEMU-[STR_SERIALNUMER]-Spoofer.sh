#!/bin/bash

generate_random_serial() {
    echo $(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 10 | head -n 1)
}

DIRECTORY="$HOME/Downloads/qemu/hw/usb"

find "$DIRECTORY" -type f -exec grep -l '\[STR_SERIALNUMBER\]' {} \; | while read -r file; do
    NEW_SERIAL=$(generate_random_serial)
    sed -i "s/\(\[STR_SERIALNUMBER\] *= *\"\)[^\"]*/\1$NEW_SERIAL/" "$file"
    echo -e "\e[32m + Modified:\e[0m '$file' with new serial: \e[32m$NEW_SERIAL\e[0m"
done

