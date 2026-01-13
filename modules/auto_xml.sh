#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils.sh"

system_info() {
    # Domain Name
    DOMAIN_NAME="Hypervisor-Phantom"

    # Sets CPU Virtualization
    if [[ "$VENDOR_ID" == *AuthenticAMD* ]]; then
        CPU_VENDOR="svm"
    elif [[ "$VENDOR_ID" == *GenuineIntel* ]]; then
        CPU_VENDOR="vmx"
    else
        CPU_VENDOR="unknown"
    fi

    # CPU Topology
    HOST_LOGICAL_CPUS=$(nproc --all 2>/dev/null || nproc 2>/dev/null)
    HOST_CORES_PER_SOCKET=$(LC_ALL=C lscpu | sed -n 's/^Core(s) per socket:[[:space:]]*//p')
    HOST_THREADS_PER_CORE=$(LC_ALL=C lscpu | sed -n 's/^Thread(s) per core:[[:space:]]*//p')

    # Generate a fully random, locally administered unicast MAC address.
    MAC_ADDRESS=$(printf '02%s\n' "$(hexdump -vn5 -e '5/1 ":%02x"' /dev/urandom)")

    # TODO: Add nmcli detection of default interface and use it to get mac address first 3 octets

    # Random 20-char hex serial (A-F0-9)
    DRIVE_SERIAL="$(LC_ALL=C tr -dc 'A-F0-9' </dev/urandom | head -c 20)"

    # Memory selection (MiB)
    local mem_choice
    while :; do
        fmtr::log "Memory allocation:

  1) 8  GiB (8192  MiB)
  2) 16 GiB (16384 MiB)
  3) 32 GiB (32768 MiB)
  4) 64 GiB (65536 MiB)"

        read -r -p "$(fmtr::ask_inline "Choose an option [1-4]: ")" mem_choice
        printf '%s\n' "$mem_choice" >>"$LOG_FILE"

        case "$mem_choice" in
            1) HOST_MEMORY_MIB=8192  ;;
            2) HOST_MEMORY_MIB=16384 ;;
            3) HOST_MEMORY_MIB=32768 ;;
            4) HOST_MEMORY_MIB=65536 ;;
            *) fmtr::warn "Invalid option. Please choose 1, 2, 3, or 4."; continue ;;
        esac

        fmtr::info "Selected #$mem_choice (${HOST_MEMORY_MIB} MiB)"
        break
    done

    # ISO Selection (from /var/lib/libvirt/images)
    ISO_DIR="/var/lib/libvirt/images"
    ISO_PATH=""

    mapfile -d '' -t ISO_FILES < <(find "$ISO_DIR" -maxdepth 1 -type f -iname '*.iso' -print0 | sort -z)

    (( ${#ISO_FILES[@]} )) || { fmtr::fatal "No .iso files found in $ISO_DIR"; exit 1; }

    while :; do
        menu="Available ISOs ($ISO_DIR)\n"
        for i in "${!ISO_FILES[@]}"; do
            menu+="\n  $((i+1))) $(basename -- "${ISO_FILES[$i]}")"
        done
        fmtr::log "$menu"

        read -r -p "$(fmtr::ask_inline "Choose an ISO [1-${#ISO_FILES[@]}]: ")" ISO_CHOICE
        printf '%s\n' "$ISO_CHOICE" >>"$LOG_FILE"

        [[ "$ISO_CHOICE" =~ ^[0-9]+$ ]] || { fmtr::warn "Please enter a number."; continue; }
        (( ISO_CHOICE >= 1 && ISO_CHOICE <= ${#ISO_FILES[@]} )) || { fmtr::warn "Choice out of range."; continue; }

        ISO_PATH="${ISO_FILES[$((ISO_CHOICE-1))]}"
        fmtr::info "Selected ISO #$ISO_CHOICE: $(basename -- "$ISO_PATH")"
        break
    done

    # Windows ISO Version Detection
    if grep -a -m1 -q '10\.0\.22' "$ISO_PATH"; then
        WIN_VERSION="win11"
    else
        WIN_VERSION="win10"
    fi
    fmtr::info "Detected Windows ISO version: $WIN_VERSION"
}

configure_xml() {
    if $ROOT_ESC virsh dominfo "$DOMAIN_NAME" >/dev/null 2>&1; then
        fmtr::fatal "Domain '$DOMAIN_NAME' already exists. Please delete it before running this script."
        return 1
    fi

    local -a args=(
        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#element-and-attribute-overview
        #

        --connect qemu:///system
        --name "${DOMAIN_NAME}"
        --osinfo "${WIN_VERSION}"





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#memory-allocation
        #
        # Allocate realistic memory amounts, such as 8, 16, 32, and 64.
        #

        --memory "${HOST_MEMORY_MIB}"





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#operating-system-booting
        #

        --boot "menu=on"
        --xml "./os/loader/@readonly=yes"
        --xml "./os/loader/@secure=yes"
        --xml "./os/loader/@type=pflash"
        --xml "./os/loader/@format=qcow2"
        --xml "./os/loader=/opt/Hypervisor-Phantom/firmware/OVMF_CODE.qcow2"
        --xml "./os/nvram/@template=/opt/Hypervisor-Phantom/firmware/OVMF_VARS.qcow2"
        --xml "./os/nvram/@format=qcow2"





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#hypervisor-features
        #

        --features "kvm.hidden.state=on" # CONCEALMENT: Hide the KVM hypervisor from standard MSR based discovery (CPUID Bitset)
        --features "pmu.state=off"       # CONCEALMENT: Disables the Performance Monitoring Unit (PMU)
        --features "vmport.state=off"    # CONCEALMENT: Disables the VMware I/O port backdoor (VMPort, 0x5658) in the guest | FYI: ACE AC looks for this
        --features "smm.state=on"        #
        --features "msrs.unknown=fault"  # CONCEALMENT: Injects a #GP(0) into the guest on RDMSR/WRMSR to an unhandled/unknown MSR





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#cpu-model-and-topology
        #

        --cpu "host-passthrough,topology.sockets=1,topology.cores=${HOST_CORES_PER_SOCKET},topology.threads=${HOST_THREADS_PER_CORE}"

        --xml "./cpu/@check=none"
        --xml "./cpu/@migratable=off"
        --xml "./cpu/topology/@dies=1"
        --xml "./cpu/topology/@clusters=1"
        --xml "./cpu/cache/@mode=passthrough"
        --xml "./cpu/maxphysaddr/@mode=passthrough"

        # TODO: Make this change based on if user is on AMD or Intel

        --xml "./cpu/feature[@name='${CPU_VENDOR}']/@policy=require" # OPTIMIZATION: Enables AMD SVM (CPUID.80000001:ECX[2])
        --xml "./cpu/feature[@name='topoext']/@policy=require"       # OPTIMIZATION: Exposes extended topology (CPUID.80000001:ECX[22], CPUID.8000001E)
        --xml "./cpu/feature[@name='invtsc']/@policy=require"        # OPTIMIZATION: Provides invariant TSC (CPUID.80000007:EDX[8])
        --xml "./cpu/feature[@name='hypervisor']/@policy=disable"    # CONCEALMENT: Clears Hypervisor Present bit (CPUID.1:ECX[31])
        --xml "./cpu/feature[@name='ssbd']/@policy=disable"          # CONCEALMENT: Clears Speculative Store Bypass Disable (CPUID.7.0:EDX[31])
        --xml "./cpu/feature[@name='amd-ssbd']/@policy=disable"      # CONCEALMENT: Clears AMD SSBD flag (CPUID.80000008:EBX[25])
        --xml "./cpu/feature[@name='virt-ssbd']/@policy=disable"     # CONCEALMENT: Clears virtual SSBD exposure (CPUID.7.0:EDX[31])





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#time-keeping
        #

        --xml "./clock/@offset=localtime"
        --xml "./clock/timer[@name='tsc']/@present=yes"
        --xml "./clock/timer[@name='tsc']/@mode=native"
        --xml "./clock/timer[@name='hpet']/@present=yes"
        --xml "./clock/timer[@name='kvmclock']/@present=no"    # CONCEALMENT: Disable KVM paravirtual clock source
        --xml "./clock/timer[@name='hypervclock']/@present=no" # CONCEALMENT: Disable Hyper-V paravirtual clock source





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#power-management
        #

        --xml "./pm/suspend-to-mem/@enabled=yes"  # CONCEALMENT: Enables S3 ACPI sleep state (suspend-to-RAM) support in the guest
        --xml "./pm/suspend-to-disk/@enabled=yes" # CONCEALMENT: Enables S4 ACPI sleep state (suspend-to-disk/hibernate) support in the guest





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#devices
        #
        # 'qemu-system-x86_64' binary path
        #

        --xml "./devices/emulator=/opt/Hypervisor-Phantom/emulator/bin/qemu-system-x86_64"





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#hard-drives-floppy-disks-cdroms
        #

        # --disk type=block,device=disk,source=/dev/nvme0n1,driver.name=qemu,driver.type=raw,driver.cache=none,driver.io=native,target.dev=nvme0,target.bus=nvme,serial=1233659 \

        --disk "size=500,bus=nvme,serial=${DRIVE_SERIAL}"
        --check "disk_size=off"
        --cdrom "$ISO_PATH"

        # TODO: Add user choice of using virtual drive, virtual drive + passthrough, complete PCI passthrough.





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#network-interfaces
        #

        --network "default,mac=${MAC_ADDRESS}"





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#tpm-device
        #
        # TPM emulation requires the 'swtpm' package to function properly.
        #
        # TODO: Add option for user to passthrough TPM or emulate it
        #

        --tpm "model=tpm-crb,backend.type=emulator,backend.version=2.0"





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#graphical-framebuffers
        #
        # TODO: Set to 'none' once using external display method.
        #

        --graphics "spice"





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#video-devices
        #
        # TODO: Set to 'none' once using external display method.
        #

        --video "vga"





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#memory-balloon-device
        #
        # The VirtIO memballoon device enables the host to dynamically reclaim memory from your VM by growing the
        # balloon inside the guest, reserving reclaimed memory. Libvirt adds this device to guests by default.
        #
        # However, this device causes major performance issues with VFIO passthrough setups, and should be disabled.
        #

        --memballoon "none"





        ################################################################################
        #
        # Documentation:
        #   - https://www.libvirt.org/kbase/qemu-passthrough-security.html
        #   - https://www.qemu.org/docs/master/system/qemu-manpage.html#hxtool-4
        #
        #
        #

        --qemu-commandline="-smbios file=/opt/Hypervisor-Phantom/firmware/smbios.bin"





        ################################################################################
        #
        # Documentation:
        #   - https://libvirt.org/formatdomain.html#consoles-serial-parallel-channel-devices
        #

        --input "none"
        --console "none"
        --channel "none"
    )

    # https://man.archlinux.org/man/virt-install.1

    $ROOT_ESC virt-install "${args[@]}" && \
    virt-manager --connect qemu:///system --show-domain-console ${DOMAIN_NAME}
} &>>"$LOG_FILE"

system_info
configure_xml
