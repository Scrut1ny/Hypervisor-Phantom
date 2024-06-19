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
                sudo pip install tomli
                sudo apt install -y git python3-venv libglib2.0-0 flex bison
                sudo apt install -y binutils-mingw-w64 binutils-mingw-w64-i686 binutils-mingw-w64-x86-64 clang g++-mingw-w64 g++-mingw-w64-i686 g++-mingw-w64-x86-64 gcc-mingw-w64 gcc-mingw-w64-i686 gcc-mingw-w64-x86-64 git git-email gnutls-bin libaio-dev libbluetooth-dev libbrlapi-dev libbz2-dev libcacard-dev libcap-dev libcap-ng-dev libcurl4-gnutls-dev libfdt-dev libglib2.0-dev libgtk-3-dev libibverbs-dev libiscsi-dev libjpeg8-dev liblzo2-dev libncurses5-dev libncursesw5-dev libnfs-dev libnuma-dev libpam0g-dev libpixman-1-dev librbd-dev librdmacm-dev libseccomp-dev libsnappy-dev libsasl2-dev libsdl1.2-dev libsdl2-dev libsdl2-image-dev libspice-protocol-dev libspice-server-dev libusb-1.0-0-dev libusb-dev libusbredirparser-dev libusbredirparser1 libvde-dev libvdeplug-dev libvirglrenderer-dev libvte-2.91-dev libxen-dev libxml2-dev libz-mingw-w64-dev libzstd-dev ninja-build valgrind win-iconv-mingw-w64-dev xfslibs-dev zlib1g-dev
                sudo apt install -y virt-manager libvirt-clients libvirt-daemon-system libvirt-daemon-config-network bridge-utils ovmf
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
    
    # Spoofing all USB serial numbers
    echo -e "\n  [+] Spoofing all serial numbers\n"
    find "$(pwd)/hw/usb" -type f -exec grep -l '\[STR_SERIALNUMBER\]' {} + | while IFS= read -r file; do
        NEW_SERIAL=$(tr -dc 'A-Z0-9' </dev/urandom | head -c 10)
        sed -i "s/\(\[STR_SERIALNUMBER\] *= *\"\)[^\"]*/\1$NEW_SERIAL/" "$file"
        echo -e "\e[32m  Modified:\e[0m '$file' with new serial: \e[32m$NEW_SERIAL\e[0m"
    done

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


