#!/bin/bash


function configs() {
    echo -e "\n  [+] Available GPU/iGPU(s):"
    lspci | grep VGA | awk -F: '{print $3}' | sed 's/^ //' | nl -v 0
    echo -e "\n" && read -p "  [+] Select a #: " gpu_number

    gpu_pci_address=$(lspci | grep VGA | awk '{print $1}' | sed -n "$((gpu_number+1))p")

    iommu_group_path=$(find /sys/kernel/iommu_groups/ -type l | grep "$gpu_pci_address")
    iommu_group_number=$(echo "$iommu_group_path" | grep -oP 'iommu_groups/\K\d+')

    if [ -z "$iommu_group_number" ]; then
        echo "Could not find the IOMMU group for the selected GPU."
        exit 1
    fi

    hardware_ids=""
    for device in $(ls /sys/kernel/iommu_groups/${iommu_group_number}/devices/); do
        device_info=$(lspci -n -s $device)
        # Extracting the class code correctly
        device_class=$(echo "$device_info" | awk '{print $2}' | cut -d ':' -f 1)
        
        # Correcting the class code comparison to exclude PCI bridges (class code 0604)
        if [ "$device_class" != "0604" ]; then
            device_ids=$(echo "$device_info" | awk '{print $3}')
            hardware_ids+="${device_ids},"
        fi
    done

    hardware_ids=${hardware_ids%,}

    # Backup grub.cfg with improved safety checks
    cp /etc/default/grub /etc/default/grub.backup

    # Determine the IOMMU setting based on the CPU vendor
    cpu_vendor=$(lscpu | grep "Vendor ID" | awk '{print $3}')
    case "$cpu_vendor" in
        AuthenticAMD) iommu_setting="amd_iommu=on";;
        GenuineIntel) iommu_setting="intel_iommu=on";;
        *) echo "  [!] Warning: Unknown CPU vendor."
           return 1;;
    esac

    # Safely modify the grub configuration
    sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/c\\GRUB_CMDLINE_LINUX_DEFAULT=\"${iommu_setting} iommu=pt vfio-pci.ids=${hardware_ids}\"" /etc/default/grub

    # Create or overwrite vfio.conf with the necessary options
    echo -e "options vfio-pci ids=${hardware_ids}\nsoftdep nvidia pre: vfio-pci" > "/etc/modprobe.d/vfio.conf"

    # Handle different distributions
    case "${distro}" in
        Debian)
            clear && echo -e "\n  [+] Updating Grub Config and initramfs image"
            sudo update-grub > /dev/null 2>&1
            sudo update-initramfs -u > /dev/null 2>&1
            ;;
        Fedora)
            clear && echo -e "\n  [+] Updating Grub Config and initramfs image"
            sudo grub2-mkconfig -o /boot/grub2/grub.cfg > /dev/null 2>&1
            sudo dracut -f > /dev/null 2>&1
            ;;
        Arch)
            clear && echo -e "\n  [+] Updating Grub Config and initramfs image"
            sudo grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1
            sudo mkinitcpio -P > /dev/null 2>&1
            ;;
        *)
            clear && echo -e "\n  [!] Distribution not recognized or not supported by this script."
            return 1
            ;;
    esac
    
    echo -e "\n  [!] REBOOT for changes to take effect."
    echo -e "\n  [+] \033[0;32mDone\033[0m" && sleep 4
}



function QEMU() {

    clear && echo -e "\n  [+] Installing QEMU Dependencies"

    # Handle different distributions
    case "${distro}" in
        Debian)
            {
                sudo apt install -y git python3-venv python3-pip libglib2.0-0 flex bison
                sudo apt install -y binutils-mingw-w64 binutils-mingw-w64-i686 binutils-mingw-w64-x86-64 clang g++-mingw-w64 g++-mingw-w64-i686 g++-mingw-w64-x86-64 gcc-mingw-w64 gcc-mingw-w64-i686 gcc-mingw-w64-x86-64 git git-email gnutls-bin libaio-dev libbluetooth-dev libbrlapi-dev libbz2-dev libcacard-dev libcap-dev libcap-ng-dev libcurl4-gnutls-dev libfdt-dev libglib2.0-dev libgtk-3-dev libibverbs-dev libiscsi-dev libjpeg8-dev liblzo2-dev libncurses5-dev libncursesw5-dev libnfs-dev libnuma-dev libpam0g-dev libpixman-1-dev librbd-dev librdmacm-dev libseccomp-dev libsnappy-dev libsasl2-dev libsdl1.2-dev libsdl2-dev libsdl2-image-dev libspice-protocol-dev libspice-server-dev libusb-1.0-0-dev libusb-dev libusbredirparser-dev libusbredirparser1 libvde-dev libvdeplug-dev libvirglrenderer-dev libvte-2.91-dev libxen-dev libxml2-dev libz-mingw-w64-dev libzstd-dev ninja-build valgrind win-iconv-mingw-w64-dev xfslibs-dev zlib1g-dev
                sudo apt install -y virt-manager libvirt-clients libvirt-daemon-system libvirt-daemon-config-network bridge-utils ovmf
                pip install tomli
                sudo usermod -a -G kvm,libvirt $(whoami)
                sudo systemctl enable libvirtd && sudo systemctl start libvirtd
                sudo virsh net-autostart default
            } >/dev/null 2>&1
            ;;
        Fedora)
            # Dependencies & Prerequisites
            echo "  [!] Distribution not supported yet, in progress."
            # yum install virt-manager
            ;;
        Arch)
            # Dependencies & Prerequisites
            echo "  [!] Distribution not supported yet, in progress."
            # sudo pacman -S git wget base-devel glib2 ninja python
            ;;
        *)
            echo "  [!] Distribution not recognized or not supported by this script."
            return 1
            ;;
    esac

    # Downloading QEMU & Applying custom patch
    echo -e "\n  [+] Downloading QEMU Source"
    {
        git clone https://gitlab.com/qemu-project/qemu.git/
        cd qemu/ && curl https://raw.githubusercontent.com/Scrut1ny/Hypervisor-Phantom/main/master.patch -o master.patch && git apply --reject master.patch
    } >/dev/null 2>&1
    echo -e "\n  [+] Applying Custom QEMU Patch"
    

    ##################################################
    ## Spoofing USB Serial Number Strings
    ## 
    ## qemu/hw/usb/*
    ##################################################


    echo -e "\n  [+] Spoofing all serial numbers\n"

    # Find files and process them
    find "$(pwd)/hw/usb" -type f -exec grep -l '\[STR_SERIALNUMBER\]' {} + | while IFS= read -r file; do
        # Generate a new random serial number
        NEW_SERIAL=$(head /dev/urandom | tr -dc 'A-Z0-9' | head -c 10)

        # Replace all serial number strings in the files
        sed -i -E "s/(\[STR_SERIALNUMBER\] *= *\")[^\"]*/\1$NEW_SERIAL/" "$file"

        # Print the modification information
        echo -e "\e[32m  Modified:\e[0m '$file' with new serial: \e[32m$NEW_SERIAL\e[0m"
    done


    ##################################################
    ## Spoofing MAC Address
    ## 
    ## 
    ##################################################
    




    ##################################################
    ## Spoofing Drive Serial Number String
    ##
    ## qemu/hw/ide/core.c
    ##################################################


    # Define the core file path
    core_file="$(pwd)/hw/ide/core.c"

    # Generate a new random serial number
    NEW_SERIAL=$(head /dev/urandom | tr -dc 'A-Z0-9' | head -c 15)

    # Arrays of model strings
    IDE_CD_MODELS=(
        "HL-DT-ST BD-RE WH16NS60"
        "HL-DT-ST DVDRAM GH24NSC0"
        "HL-DT-ST BD-RE BH16NS40"
        "HL-DT-ST DVD+-RW GT80N"
        "HL-DT-ST DVD-RAM GH22NS30"
        "HL-DT-ST DVD+RW GCA-4040N"
        "Pioneer BDR-XD07B"
        "Pioneer DVR-221LBK"
        "Pioneer BDR-209DBK"
        "Pioneer DVR-S21WBK"
        "Pioneer BDR-XD05B"
        "ASUS BW-16D1HT"
        "ASUS DRW-24B1ST"
        "ASUS SDRW-08D2S-U"
        "ASUS BC-12D2HT"
        "ASUS SBW-06D2X-U"
        "Samsung SH-224FB"
        "Samsung SE-506BB"
        "Samsung SH-B123L"
        "Samsung SE-208GB"
        "Samsung SN-208DB"
        "Sony NEC Optiarc AD-5280S"
        "Sony DRU-870S"
        "Sony BWU-500S"
        "Sony NEC Optiarc AD-7261S"
        "Sony AD-7200S"
        "Lite-On iHAS124-14"
        "Lite-On iHBS112-04"
        "Lite-On eTAU108"
        "Lite-On iHAS324-17"
        "Lite-On eBAU108"
        "HP DVD1260i"
        "HP DVD640"
        "HP BD-RE BH30L"
        "HP DVD Writer 300n"
        "HP DVD Writer 1265i"
    )

    IDE_CFATA_MODELS=(
        "SanDisk Ultra microSDXC UHS-I"
        "SanDisk Extreme microSDXC UHS-I"
        "SanDisk High Endurance microSDXC"
        "SanDisk Industrial microSD"
        "SanDisk Mobile Ultra microSDHC"
        "Samsung EVO Select microSDXC"
        "Samsung PRO Endurance microSDHC"
        "Samsung PRO Plus microSDXC"
        "Samsung EVO Plus microSDXC"
        "Samsung PRO Ultimate microSDHC"
        "Kingston Canvas React Plus microSD"
        "Kingston Canvas Go! Plus microSD"
        "Kingston Canvas Select Plus microSD"
        "Kingston Industrial microSD"
        "Kingston Endurance microSD"
        "Lexar Professional 1066x microSDXC"
        "Lexar High-Performance 633x microSDHC"
        "Lexar PLAY microSDXC"
        "Lexar Endurance microSD"
        "Lexar Professional 1000x microSDHC"
        "PNY Elite-X microSD"
        "PNY PRO Elite microSD"
        "PNY High Performance microSD"
        "PNY Turbo Performance microSD"
        "PNY Premier-X microSD"
        "Transcend High Endurance microSDXC"
        "Transcend Ultimate microSDXC"
        "Transcend Industrial Temp microSD"
        "Transcend Premium microSDHC"
        "Transcend Superior microSD"
        "ADATA Premier Pro microSDXC"
        "ADATA XPG microSDXC"
        "ADATA High Endurance microSDXC"
        "ADATA Premier microSDHC"
        "ADATA Industrial microSD"
        "Toshiba Exceria Pro microSDXC"
        "Toshiba Exceria microSDHC"
        "Toshiba M203 microSD"
        "Toshiba N203 microSD"
        "Toshiba High Endurance microSD"
    )

    DEFAULT_MODELS=(
        "Samsung SSD 970 EVO 1TB"
        "Samsung SSD 860 QVO 2TB"
        "Samsung SSD 850 PRO 512GB"
        "Samsung SSD T7 Touch 1TB"
        "Samsung SSD 840 EVO 250GB"
        "WD Blue SN570 NVMe SSD 1TB"
        "WD Black SN850 NVMe SSD 2TB"
        "WD Green 240GB SSD"
        "WD My Passport SSD 1TB"
        "WD Blue 3D NAND 500GB SSD"
        "Seagate BarraCuda SSD 500GB"
        "Seagate FireCuda 520 SSD 1TB"
        "Seagate One Touch SSD 1TB"
        "Seagate IronWolf 110 SSD 960GB"
        "Seagate Fast SSD 2TB"
        "Crucial MX500 1TB 3D NAND SSD"
        "Crucial P5 Plus NVMe SSD 2TB"
        "Crucial BX500 480GB 3D NAND SSD"
        "Crucial X8 Portable SSD 1TB"
        "Crucial P3 1TB PCIe 3.0 3D NAND NVMe SSD"
        "Kingston A2000 NVMe SSD 1TB"
        "Kingston KC2500 NVMe SSD 2TB"
        "Kingston A400 SSD 480GB"
        "Kingston HyperX Savage SSD 960GB"
        "Kingston DataTraveler Vault Privacy 3.0 64GB"
        "SanDisk Ultra 3D NAND SSD 1TB"
        "SanDisk Extreme Portable SSD V2 1TB"
        "SanDisk SSD PLUS 480GB"
        "SanDisk Ultra 3D 2TB NAND SSD"
        "SanDisk Extreme Pro 1TB NVMe SSD"
    )

    # Function to get a random element from an array
    get_random_element() {
        local array=("$@")
        echo "${array[RANDOM % ${#array[@]}]}"
    }

    # Select random models
    NEW_IDE_CD_MODEL=$(get_random_element "${IDE_CD_MODELS[@]}")
    NEW_IDE_CFATA_MODEL=$(get_random_element "${IDE_CFATA_MODELS[@]}")
    NEW_DEFAULT_MODEL=$(get_random_element "${DEFAULT_MODELS[@]}}")

    # Replace the "QM" string with the new serial number in core.c
    sed -i -E "s/\"[^\"]*%05d\", s->drive_serial\);/\"$NEW_SERIAL%05d\", s->drive_serial\);/" "$core_file"

    # Spoof the IDE_CD drive model string
    sed -i -E "s/\"HL-DT-ST BD-RE WH16NS60\"/\"$NEW_IDE_CD_MODEL\"/" "$core_file"

    # Spoof the IDE_CFATA drive model string
    sed -i -E "s/\"MicroSD J45S9\"/\"$NEW_IDE_CFATA_MODEL\"/" "$core_file"

    # Spoof the default drive model string
    sed -i -E "s/\"Samsung SSD 980 500GB\"/\"$NEW_DEFAULT_MODEL\"/" "$core_file"

    # Print the modification information
    echo -e "\e[32m  Modified:\e[0m '$core_file' with new serial: \e[32m$NEW_SERIAL\e[0m"
    echo -e "\e[32m  Modified:\e[0m '$core_file' with new IDE_CD model: \e[32m$NEW_IDE_CD_MODEL\e[0m"
    echo -e "\e[32m  Modified:\e[0m '$core_file' with new IDE_CFATA model: \e[32m$NEW_IDE_CFATA_MODEL\e[0m"
    echo -e "\e[32m  Modified:\e[0m '$core_file' with new default model: \e[32m$NEW_DEFAULT_MODEL\e[0m"


    ##################################################
    ## Spoofing ACPI Table Strings
    ##
    ## qemu/include/hw/acpi/aml-build.h
    ##################################################


    # Array of ACPI Pairs
    pairs=(
        'DELL  ' 'Dell Inc' # Dell
        'ALASKA' 'A M I '   # AMD
        'INTEL ' 'U Rvp   ' # Intel
        ' ASUS ' 'Notebook' # Asus
        'MSI NB' 'MEGABOOK' # MSI
        'LENOVO' 'TC-O5Z  ' # Lenovo
        'LENOVO' 'CB-01   ' # Lenovo
        'SECCSD' 'LH43STAR' # ???
        'LGE   ' 'ICL     ' # LG
    )

    # Generate a random index to select a pair
    total_pairs=$((${#pairs[@]} / 2))
    random_index=$((RANDOM % total_pairs * 2))

    # Extract the randomly selected pair
    appname6=${pairs[$random_index]}
    appname8=${pairs[$random_index + 1]}

    # Replace the "BOCHS" "BXPC" strings in aml-build.h
    file="$(pwd)/include/hw/acpi/aml-build.h"
    sed -i "s/^#define ACPI_BUILD_APPNAME6 \".*\"/#define ACPI_BUILD_APPNAME6 \"$appname6\"/" "$file"
    sed -i "s/^#define ACPI_BUILD_APPNAME8 \".*\"/#define ACPI_BUILD_APPNAME8 \"$appname8\"/" "$file"

    # Print the modifications
    echo -e "\e[32m  Modified:\e[0m '$file' with new values:"
    echo -e "  \e[32m#define ACPI_BUILD_APPNAME6 \"$appname6\"\e[0m"
    echo -e "  \e[32m#define ACPI_BUILD_APPNAME8 \"$appname8\"\e[0m"


    ##################################################
    ## Spoofing CPUID Manufacturer Signature Strings
    ## https://en.wikipedia.org/wiki/CPUID
    ## qemu/target/i386/kvm/kvm.c
    ##################################################


    # Define the file path
    kvm_file="$(pwd)/target/i386/kvm/kvm.c"

    # Array of possible signatures
    signatures=("AuthenticAMD" "GenuineIntel")

    # Generate a random index to select a signature
    random_index=$((RANDOM % ${#signatures[@]}))
    NEW_SIGNATURE=${signatures[$random_index]}

    # Replace the signature strings in kvm.c
    sed -i -E "s/(memcpy\(signature, \")[^\"]*(\", 12\);)/\1$NEW_SIGNATURE\2/" "$kvm_file"

    # Print the modification information
    echo -e "\e[32m  Modified:\e[0m '$kvm_file' with new signature: \e[32m$NEW_SIGNATURE\e[0m"


    ##################################################


    # Building & Installing QEMU
    echo -e "\n  [+] Building & Installing QEMU"
    {
        cd .. && mkdir qemu_build && cd qemu_build && ../qemu/configure --target-list=x86_64-softmmu,x86_64-linux-user --prefix=/usr && make -j $(nproc) && sudo make install
    } >/dev/null 2>&1

    # Cleanup
    echo -e "\n  [+] Cleaning up"
    cd .. && sudo rm -rf qemu qemu_build

    # Message
    echo -e "\n  [!] Logout for changes to take effect."
    echo -e "\n  [+] \033[0;32mDone\033[0m" && sleep 4
}



function Looking_Glass() {

    clear && echo -e "\n  [+] Installing Looking Glass Dependencies"

    # Handle different distributions
    case "${distro}" in
        Debian)
            {
                sudo apt install -y binutils-dev cmake fonts-dejavu-core libfontconfig-dev gcc g++ pkg-config libegl-dev libgl-dev libgles-dev libspice-protocol-dev nettle-dev libx11-dev libxcursor-dev libxi-dev libxinerama-dev libxpresent-dev libxss-dev libxkbcommon-dev libwayland-dev wayland-protocols libpipewire-0.3-dev libpulse-dev libsamplerate0-dev > /dev/null 2>&1
            } >/dev/null 2>&1
            ;;
        Fedora)
            echo -e "\n  [!] Distribution not supported yet, in progress."
            ;;
        Arch)
            echo -e "\n  [!] Distribution not supported yet, in progress."
            ;;
        *)
            echo -e "\n  [!] Distribution not recognized or not supported by this script."
            return 1
            ;;
    esac
    
    # Download Latest LG Version
    echo -e "\n  [+] Installing Looking Glass"
    {
        curl -sSL https://looking-glass.io/artifact/stable/source -o latest.tar.gz && tar -zxvf latest.tar.gz && rm -rf latest.tar.gz
    } >/dev/null 2>&1
            
    # Build & Install LG
    echo -e "\n  [+] Building & Installing Looking Glass"
    {
        cd looking-glass-* && mkdir client/build && cd client/build && cmake ../ && make -j $(nproc) && sudo make install
    } >/dev/null 2>&1
            
    # Cleanup
    echo -e "\n  [+] Cleaning up"
    cd ../../../ && sudo rm -rf looking-glass-*
            
    # Make & configure LG config file
    echo -e "\n  [+] Creating '10-looking-glass.conf'"
    CONF_FILE="/etc/tmpfiles.d/10-looking-glass.conf"
    USERNAME=${SUDO_USER:-$(whoami)}
            
    {
        echo "f /dev/shm/looking-glass 0660 $USERNAME kvm -" | sudo tee "$CONF_FILE" > /dev/null
    } >/dev/null

    # Grant LG permissions
    echo -e "\n  [+] Granting Looking Glass Permissions"
    {
        touch /dev/shm/looking-glass && sudo chown $USER:kvm /dev/shm/looking-glass && chmod 660 /dev/shm/looking-glass
    } >/dev/null

    # Command to append to .bashrc
    entry_to_add=$(cat <<'EOF'

# Alias lg for Looking Glass shared memory setup
# This command sequence sets up /dev/shm/looking-glass with the appropriate permissions.
alias lg='if [ ! -e /dev/shm/looking-glass ]; then \
    touch /dev/shm/looking-glass; \
    sudo chown $USER:kvm /dev/shm/looking-glass; \
    chmod 660 /dev/shm/looking-glass; \
    /usr/local/bin/looking-glass-client -S -K -1; \
else \
    /usr/local/bin/looking-glass-client -S -K -1; \
fi'

EOF
    )

    # Check if the alias already exists in .bashrc to avoid duplicates
    if grep -q "alias lg=" ~/.bashrc; then
        echo -e "\n  [*] The lg alias already exists in .bashrc."
    else
        # Append the formatted entry to .bashrc
        echo "$entry_to_add" >> ~/.bashrc
    fi

    # Apply bashrc changes
    source ~/.bashrc

    # Message for user
    echo -e "\n  [+] A new bashrc entry was made for launching Looking Glass.\n      Just type 'lg' in the terminal."
    echo -e "\n  [+] \033[0;32mDone\033[0m" && sleep 4
}



function Kernal_Patch() {

    clear && echo -e "\n  [+] Installing Linux Kernal Compiling Dependencies"
    
    case "${distro}" in
        Debian)
            {
                sudo apt install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev
            } >/dev/null 2>&1
            ;;
        Fedora)
            {
                echo -e "\n  [!] Distribution not supported yet, in progress."
            } >/dev/null 2>&1
            ;;
        Arch)
            {
                echo -e "\n  [!] Distribution not supported yet, in progress."
            } >/dev/null 2>&1
            ;;
        *)
            clear && echo -e "\n  [!] Distribution not recognized or not supported by this script."
            return 1
            ;;
    esac
    
    # Get the Kernel Source
    echo -e "\n  [+] Downloading Linux Kernal"
    git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
    cd linux
    git checkout v$(uname -r)

    # Prepare the Kernel Configuration
    echo -e "\n  [+] Copied current kernel config"
    cp /boot/config-$(uname -r) .config

    # Apply Your Custom Patches
    echo -e "\n  [+] Applying custom patch"
    patch -p1 < /path/to/svm.patch
    patch -p1 < /path/to/vmx.patch

    # Build the Kernel
    echo -e "\n  [+] Building the Kernal"
    make -j$(nproc) > /dev/null 2>&1

    # Install the Kernel Modules & the Kernel
    echo -e "\n  [+] Installing/Applying Kernal patches"
    sudo make modules_install && sudo make install
}



system_check() {
    clear

    if [ -f /etc/debian_version ]; then
        echo -e "\n  Distro Detected: \033[32mDebian\033[0m\n  ---------------------------"
        distro="Debian"
    elif [ -f /etc/fedora-release ]; then
        echo -e "\n  Distro Detected: \033[32mFedora\033[0m\n  ---------------------------"
        distro="Fedora"
    elif [ -f /etc/arch-release ]; then
        echo -e "\n  Distro Detected: \033[32mArch\033[0m\n  ---------------------------"
        distro="Arch"
    else
        echo -e "\n  [!] Your distribution is not specifically supported by this script."
    fi

    echo -e "  CPU(s): \033[32m$(LC_ALL=C lscpu | awk '/^CPU\(s\):/ {print $2}')\033[0m"

    echo -e "  Vendor ID: \033[32m$(LC_ALL=C lscpu | grep 'Vendor ID' | awk '{print $3}')\033[0m"
    vendor_id=$(LC_ALL=C lscpu | grep 'Vendor ID' | awk '{print $3}')

    # echo -e "  [+] Virtualization: \033[32m$(LC_ALL=C lscpu | grep 'Virtualization' | awk '{print $2}')\033[0m"

    virtualization_status=$(LC_ALL=C lscpu | grep 'Virtualization' | awk '{print $2}')

    if [ -z "$virtualization_status" ]; then
        echo -e "  [!] Virtualization: \033[31mNot enabled. Please go to the UEFI/BIOS settings and enable Virtualization!\033[0m"
    else
        echo -e "  Virtualization: \033[32m$virtualization_status\033[0m"
    fi

    echo -e "  ---------------------------\n"
}



menu() {
    while true; do
        clear && system_check
        echo "  [1] Auto [grub.cfg + vfio.conf]"
        echo "  [2] Auto [QEMU + Virt-Manager]"
        echo "  [3] Auto [RDTSC Kernel Patch]"
        echo "  [4] Auto [Looking Glass]"
        echo -e "\n  [0] Exit\n"
        
        read -p "  Enter your choice [1-4 or 0 to exit]: " choice
        
        case $choice in
            1)
                clear && configs
                ;;
            2)
                clear && QEMU
                ;;
            3)
                clear && echo -e "\n  [!] Not supported yet, in progress."
                # Kernal_Patch
                ;;
            4)
                clear && Looking_Glass
                ;;
            0)
                clear && exit 0
                ;;
            *)
                echo -e "\n  [-] Invalid option, please try again."
                ;;
        esac
    done
}


menu


