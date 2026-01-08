#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils.sh"

system_info() {
    # Domain Name
    DOMAIN_NAME="Hypervisor-Phantom"

    # CPU Topology
    HOST_LOGICAL_CPUS=$(nproc --all 2>/dev/null || nproc 2>/dev/null)
    HOST_CORES_PER_SOCKET=$(LC_ALL=C lscpu | sed -n 's/^Core(s) per socket:[[:space:]]*//p')
    HOST_THREADS_PER_CORE=$(LC_ALL=C lscpu | sed -n 's/^Thread(s) per core:[[:space:]]*//p')

    # Generate a fully random, locally administered unicast MAC address.
    MAC_ADDRESS=$(printf '02%s\n' "$(hexdump -vn5 -e '5/1 ":%02x"' /dev/urandom)")

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
}

configure_xml() {
    # Check if domain already exists to prevent errors
    if $ROOT_ESC virsh dominfo "$DOMAIN_NAME" >/dev/null 2>&1; then
        fmtr::fatal "Domain '$DOMAIN_NAME' already exists. Please delete it before running this script."
        return 1
    fi

    local -a args=(
        ################################################################################
        # https://libvirt.org/formatdomain.html#element-and-attribute-overview
        #
        --connect qemu:///system
        --name "${DOMAIN_NAME}"
        --osinfo "win10"


        ################################################################################
        # https://libvirt.org/formatdomain.html#memory-allocation
        #
        --memory "${HOST_MEMORY_MIB}"


        ################################################################################
        # https://libvirt.org/formatdomain.html#operating-system-booting
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
        # https://libvirt.org/formatdomain.html#hypervisor-features
        #
        --features "hyperv.relaxed.state=off"
        --features "hyperv.vapic.state=off"
        --features "hyperv.spinlocks.state=off"
        --features "hyperv.spinlocks.retries="
        --features "hyperv.vpindex.state=off"
        --features "hyperv.runtime.state=off"
        --features "hyperv.synic.state=off"
        --features "hyperv.stimer.state=off"
        --features "hyperv.reset.state=off"

        --xml "./features/hyperv/@mode=custom"
        --xml "./features/hyperv/vendor_id/@state=on"
        --xml "./features/hyperv/vendor_id/@value=${VENDOR_ID}" # CPU Vendor ID obtained via 'main.sh'

        --features "hyperv.frequencies.state=off"
        --features "hyperv.reenlightenment.state=off"
        --features "hyperv.tlbflush.state=off"
        --features "hyperv.ipi.state=off"
        --features "hyperv.evmcs.state=off"
        --features "hyperv.avic.state=off"
        --features "hyperv.emsr_bitmap.state=off"
        --features "hyperv.xmm_input.state=off"

        --features "kvm.hidden.state=on"
        --features "pmu.state=off"
        --features "vmport.state=off"
        --features "smm.state=on"
        --features "msrs.unknown=fault"


        ################################################################################
        # https://libvirt.org/formatdomain.html#cpu-model-and-topology
        #
        --cpu "host-passthrough,topology.sockets=1,topology.cores=${HOST_CORES_PER_SOCKET},topology.threads=${HOST_THREADS_PER_CORE}"

        --xml "./cpu/@check=none"
        --xml "./cpu/@migratable=off"
        --xml "./cpu/topology/@dies=1"
        --xml "./cpu/topology/@clusters=1"
        --xml "./cpu/cache/@mode=passthrough"
        --xml "./cpu/maxphysaddr/@mode=passthrough"

        --xml "./cpu/feature[@name='svm']/@policy=require"
        --xml "./cpu/feature[@name='topoext']/@policy=require"
        --xml "./cpu/feature[@name='invtsc']/@policy=require"
        --xml "./cpu/feature[@name='hypervisor']/@policy=disable"
        --xml "./cpu/feature[@name='ssbd']/@policy=disable"
        --xml "./cpu/feature[@name='amd-ssbd']/@policy=disable"
        --xml "./cpu/feature[@name='virt-ssbd']/@policy=disable"


        ################################################################################
        # https://libvirt.org/formatdomain.html#time-keeping
        #
        --xml "./clock/@offset=localtime"
        --xml "./clock/timer[@name='tsc']/@present=yes"
        --xml "./clock/timer[@name='tsc']/@mode=native"
        --xml "./clock/timer[@name='hpet']/@present=yes"
        --xml "./clock/timer[@name='kvmclock']/@present=no"
        --xml "./clock/timer[@name='hypervclock']/@present=no"


        ################################################################################
        # https://libvirt.org/formatdomain.html#power-management
        #
        --xml "./pm/suspend-to-mem/@enabled=yes"
        --xml "./pm/suspend-to-disk/@enabled=yes"


        ################################################################################
        # https://libvirt.org/formatdomain.html#devices
        #
        --xml "./devices/emulator=/opt/Hypervisor-Phantom/emulator/bin/qemu-system-x86_64"


        ################################################################################
        # https://libvirt.org/formatdomain.html#hard-drives-floppy-disks-cdroms
        #
        --disk "size=500,bus=nvme,serial=${DRIVE_SERIAL}"
        --check "disk_size=off"
        --cdrom "$ISO_PATH"

        # TODO: Add user choice of using virtual drive, virtual drive + passthrough, complete PCI passthrough.


        ################################################################################
        # https://libvirt.org/formatdomain.html#network-interfaces
        #
        --network "default,mac=${MAC_ADDRESS}"


        ################################################################################
        # https://libvirt.org/formatdomain.html#tpm-device
        #
        --tpm "model=tpm-crb,backend.type=emulator,backend.version=2.0"


        ################################################################################
        # https://libvirt.org/formatdomain.html#graphical-framebuffers
        #
        --graphics "spice"


        ################################################################################
        # https://libvirt.org/formatdomain.html#video-devices
        #
        --video "vga"


        ################################################################################
        # https://libvirt.org/formatdomain.html#memory-balloon-device
        #
        --memballoon "none"


        ################################################################################
        # https://www.libvirt.org/kbase/qemu-passthrough-security.html
        # https://www.qemu.org/docs/master/system/qemu-manpage.html#hxtool-4
        #
        --qemu-commandline="-smbios file=/opt/Hypervisor-Phantom/firmware/smbios.bin"


        ################################################################################
        # https://libvirt.org/formatdomain.html#consoles-serial-parallel-channel-devices
        #
        --input "none"
        --console "none"
        --channel "none"
    )

    $ROOT_ESC virt-install "${args[@]}"
    virt-manager --connect qemu:///system --show-domain-console ${DOMAIN_NAME}
} &>>"$LOG_FILE"

system_info
configure_xml
