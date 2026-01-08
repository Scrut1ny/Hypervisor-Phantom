#!/usr/bin/env bash

[[ -z "$DISTRO" || -z "$LOG_FILE" ]] && { echo "Required environment variables not set."; exit 1; }

source "./utils.sh"

system_info() {
    # CPU Topology
    HOST_LOGICAL_CPUS=$(nproc --all 2>/dev/null || nproc 2>/dev/null)
    HOST_CORES_PER_SOCKET=$(LC_ALL=C lscpu | sed -n 's/^Core(s) per socket:[[:space:]]*//p')
    HOST_THREADS_PER_CORE=$(LC_ALL=C lscpu | sed -n 's/^Thread(s) per core:[[:space:]]*//p')

    # Generate a fully random, locally administered unicast MAC address.
    MAC_ADDRESS=$(printf '02%s\n' "$(hexdump -vn5 -e '5/1 ":%02x"' /dev/urandom)")

    # Random 20-char hex serial (A-F0-9)
    DRIVE_SERIAL="$(LC_ALL=C tr -dc 'A-F0-9' </dev/urandom | head -c 20)"

    # ISO Selection
    ISO_PATH=""
    while :; do
        read -r -p "$(fmtr::ask_inline "Enter absolute path to your Windows ISO (.iso): ")" ISO_PATH
        printf '%s\n' "$ISO_PATH" >>"$LOG_FILE"

        [[ "$ISO_PATH" = /* ]] || { fmtr::warn "Path must be absolute (start with /)."; continue; }
        [[ -f "$ISO_PATH" ]]   || { fmtr::warn "ISO not found: $ISO_PATH"; continue; }

        shopt -s nocasematch
        if [[ "$ISO_PATH" != *.iso ]]; then
            shopt -u nocasematch
            fmtr::warn "File must end with .iso"
            continue
        fi
        shopt -u nocasematch

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
        --name "Hypervisor-Phantom"
        --osinfo "win10"


        ################################################################################
        # https://libvirt.org/formatdomain.html#memory-allocation
        #
        --memory "16384"


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
        --xml "./features/hyperv/vendor_id/@value=${VENDOR_ID}" # Obtained via 'main.sh'

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


        ################################################################################
        # Console behavior
        #
        --autoconsole graphical
        --wait -1
    )

    $ROOT_ESC virt-install "${args[@]}"
} &>>"$LOG_FILE"

system_info
configure_xml
