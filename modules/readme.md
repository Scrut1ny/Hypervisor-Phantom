# EDK2 / OVMF / Firmware

<details>
<summary>Expand for details...</summary>





- https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions
- https://github.com/tianocore/tianocore.github.io/wiki/How-to-build-OVMF
- https://github.com/tianocore/edk2/tree/master/OvmfPkg

## NVRAM Template:

```
sudo pacman -S edk2-ovmf
```

```
/usr/share/edk2/x64/MICROVM.4m.fd
/usr/share/edk2/x64/OVMF.4m.fd
/usr/share/edk2/x64/OVMF_CODE.4m.fd
/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd
/usr/share/edk2/x64/OVMF_VARS.4m.fd
```

## BmpImageDecoder (BMP Validator)

- https://github.com/tianocore/edk2/blob/master/BaseTools/Source/Python/AutoGen/GenC.py#L1892
  - File Type: Bytes `0–1` must be `0x42 0x4D`
  - Bit Depth: Must be `1`, `4`, `8`, or `24`
  - Compression: Must be `0`
  - Width/Height: `≤65535x65535`

## OVMF MOR/MORLock support:
- https://github.com/tianocore/edk2/blob/master/OvmfPkg/README#L160
- https://github.com/tianocore/tianocore.github.io/wiki/How-to-Enable-Security
- https://github.com/tianocore/edk2/tree/master/SecurityPkg/Tcg/MemoryOverwriteControl
- https://github.com/tianocore/edk2/tree/master/SecurityPkg/Tcg/MemoryOverwriteRequestControlLock
- https://github.com/tianocore/edk2/blob/master/OvmfPkg/Include/Dsc/MorLock.dsc.inc
- https://github.com/tianocore/edk2/blob/master/OvmfPkg/Include/Fdf/MorLock.fdf.inc

## OVMF TPM support:
- https://github.com/tianocore/edk2/blob/master/OvmfPkg/OvmfPkgX64.dsc#L39
- https://github.com/tianocore/edk2/blob/master/OvmfPkg/Include/Dsc/OvmfTpmDefines.dsc.inc

OVMF Build Args:
```
build -a X64 -p OvmfPkg/OvmfPkgX64.dsc -b RELEASE -t GCC5 -n 0 -s \
  --define SECURE_BOOT_ENABLE=TRUE \
  --define SMM_REQUIRE=TRUE \
  --define TPM1_ENABLE=TRUE \
  --define TPM2_ENABLE=TRUE \
```

QEMU XML:
```xml
  <features>
    <smm state="on"/>
  </features>
...
    <tpm model="tpm-crb">
      <backend type="emulator" version="2.0"/>
    </tpm>
```

## Last BIOS time: 0.0
#### Add FPDT module to OVMF
- ```MdeModulePkg/Universal/Acpi/FirmwarePerformanceDataTableDxe/FirmwarePerformanceDxe.c```
- ```OvmfPkg/OvmfPkgX64.dsc```
```
  #
  # ACPI Support
  #
  MdeModulePkg/Universal/Acpi/AcpiTableDxe/AcpiTableDxe.inf
  OvmfPkg/AcpiPlatformDxe/AcpiPlatformDxe.inf
!if $(STANDALONE_MM_ENABLE) != TRUE
  MdeModulePkg/Universal/Acpi/S3SaveStateDxe/S3SaveStateDxe.inf
  MdeModulePkg/Universal/Acpi/BootScriptExecutorDxe/BootScriptExecutorDxe.inf
!endif
  MdeModulePkg/Universal/Acpi/BootGraphicsResourceTableDxe/BootGraphicsResourceTableDxe.inf
  MdeModulePkg/Universal/Acpi/FirmwarePerformanceDataTableDxe/FirmwarePerformanceDxe.inf     <---- Add
```
- ```OvmfPkg/Library/QemuBootOrderLib/QemuBootOrderLib.c```
  - Search for function: `GetFrontPageTimeoutFromQemu`

## Secure Boot

- [https://github.com/microsoft/secureboot_objects](https://github.com/microsoft/secureboot_objects)
  - PostSignedObjects
    - [DBXUpdate.bin](https://github.com/microsoft/secureboot_objects/blob/main/PostSignedObjects/DBX/amd64/DBXUpdate.bin)
  - PreSignedObjects
    - [PK,KEK,DB.der](https://github.com/microsoft/secureboot_objects/blob/main/PreSignedObjects)

## virt-fw-vars
- [uefi-variable-store](https://www.qemu.org/docs/master/interop/qemu-qmp-ref.html#uefi-variable-store)
- [virt-fw-vars - man page](https://man.archlinux.org/man/extra/virt-firmware/virt-fw-vars.1.en)
- [json support for efi - python script](https://gitlab.com/kraxel/virt-firmware/-/blob/master/virt/firmware/efi/efijson.py)

## Generated firmware from template that is writable:

```
/var/lib/libvirt/qemu/nvram
```

## STORAGE:

```
/var/lib/libvirt/images/
```

</details>












---

# QEMU / Emulator

<details>
<summary>Expand for details...</summary>

## evdev

#### References
- [Libvirt - Input devices](https://libvirt.org/formatdomain.html#input-devices)
- [Arch Wiki - Passing keyboard/mouse via Evdev](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev)
- [Guide - "Evdev Passthrough Explained — Cheap, Seamless VM Input"](https://passthroughpo.st/using-evdev-passthrough-seamless-vm-input/)

| **Category**              | **Attribute**   | **Value / Options**                                                       |
|---------------------------|-----------------|---------------------------------------------------------------------------|
| **Keyboards**             | grab            | all                                                                       |
|                           | grabToggle      | shift-shift                                                               |
|                           | repeat          | on                                                                        |
| **Mice**                  | grabToggle      | shift-shift                                                               |
| **evdev Attributes**      | grab            | all                                                                       |
|                           | grabToggle      | ctrl-ctrl, alt-alt, shift-shift, meta-meta, scrolllock, ctrl-scrolllock   |
|                           | repeat          | on, off                                                                   |

#### Automated Libvirt XML evdev bash script:
```bash
for kbd in /dev/input/by-id/*-event-kbd; do
    [ -e "$kbd" ] || continue
    cat << EOF
    <input type="evdev">
      <source dev="$kbd" grab="all" grabToggle="shift-shift" repeat="on"/>
    </input>
EOF
done

for pointer in /dev/input/by-id/*-event-mouse; do
    [ -e "$pointer" ] || continue
    cat << EOF
    <input type="evdev">
      <source dev="$pointer" grabToggle="shift-shift"/>
    </input>
EOF
done
```

</details>








---

# XML

<details>
<summary>Expand for details...</summary>

### AMD Libvirt XML Reference:

<details>
<summary>Expand for XML...</summary>

```xml
<!--
  ******************************************************************************
  *                              IMPORTANT NOTICE                              *
  ******************************************************************************
  *                                                                            *
  *  DO NOT BLINDLY COPY AND PASTE THIS CONFIGURATION.                         *
  *                                                                            *
  *  This XML configuration is provided as a template and should be carefully  *
  *  reviewed and adjusted to match your specific system requirements.         *
  *                                                                            *
  *  Always work section by section, ensuring that each parameter is           *
  *  appropriate for your environment. Blindly copying and pasting may lead    *
  *  to misconfigurations, security vulnerabilities, or system instability.    *
  *                                                                            *
  *  Take the time to understand each setting and modify it as needed.         *
  *                                                                            *
  ******************************************************************************
-->

<domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm"> <!-- Don't forget XMLNS! -->
  <uuid>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX</uuid> <!-- FYI: This is NOT the guest system's UUID in SMBIOS! -->

  <memory unit="G">16</memory>  <!-- Utilize realistic memory amounts, such as 8, 16, 32, and 64. -->
  <currentMemory unit="G">16</currentMemory>





  <!--
  <> https://libvirt.org/formatdomain.html#operating-system-booting



  -->
  <os>
    <type arch="x86_64" machine="pc-q35-10.2">hvm</type>
    <loader readonly="yes" secure="yes" type="pflash" format="qcow2">/opt/Hypervisor-Phantom/firmware/OVMF_CODE.qcow2</loader>
    <nvram template="/opt/Hypervisor-Phantom/firmware/OVMF_VARS.qcow2" format="qcow2"></nvram>
    <bootmenu enable="yes"/>
    <smbios mode="host"/> <!-- Remove if 'smbios.bin' is being passed through -->
  </os>





  <!-- 
  <> https://libvirt.org/formatdomain.html#hypervisor-features


 
  -->
  <features>
    <acpi/>
    <apic/>
    <!-- Disable all enlightenments if Hyper-V method is NOT used.
    Enlightenments on "bare-metal" are flagged / extremely suspicious! -->
    <hyperv mode="custom">
      <relaxed state="off"/>
      <vapic state="off"/>
      <spinlocks state="off"/>
      <vpindex state="off"/>
      <runtime state="off"/>
      <synic state="off"/>
      <stimer state="off"/>
      <reset state="off"/>
      <vendor_id state="on" value="AuthenticAMD"/> <!-- KVM patch NOT present | Apply to fix NVIDIA (Code 43) error -->
      <vendor_id state="off"/>                     <!-- KVM patch IS present -->
      <frequencies state="off"/>
      <reenlightenment state="off"/>
      <tlbflush state="off"/>
      <ipi state="off"/>
      <evmcs state="off"/>
      <avic state="off"/>
      <emsr_bitmap state="off"/>
      <xmm_input state="off"/>
    </hyperv>
    <kvm>
      <hidden state="on"/> <!-- CONCEALMENT: Hide the KVM hypervisor from standard MSR based discovery (CPUID Bitset) -->
    </kvm>
    <pmu state="off"/> <!-- CONCEALMENT: Disables the Performance Monitoring Unit (PMU) -->
    <vmport state="off"/> <!-- CONCEALMENT: Disables the VMware I/O port backdoor (VMPort, 0x5658) in the guest | FYI: ACE AC looks for this -->
    <smm state="on"/>
    <msrs unknown="fault"/> <!-- CONCEALMENT: Injects a #GP(0) into the guest on RDMSR/WRMSR to an unhandled/unknown MSR -->
  </features>





  <!--
  <> https://libvirt.org/formatdomain.html#cpu-model-and-topology


 
  -->
  <cpu mode="host-passthrough" check="none" migratable="off">
    <topology sockets="1" dies="1" clusters="1" cores="8" threads="2"/>
    <cache mode="passthrough"/>
    <maxphysaddr mode="passthrough"/>
   
    <!-- Performance Features -->
    <feature policy="require" name="svm"/>        <!-- OPTIMIZATION: Requires AMD SVM (hardware virtualization) to be exposed to the guest (needed for nested virtualization) -->
    <feature policy="require" name="topoext"/>    <!-- OPTIMIZATION: Requires AMD topology extensions (more accurate core/thread/cache topology reporting to the guest) -->
    <feature policy="require" name="invtsc"/>     <!-- OPTIMIZATION: Requires invariant TSC (stable time-stamp counter rate across P-states/C-states) for more consistent guest timekeeping -->
   
    <!-- Hypervisor Detection -->
    <feature policy="disable" name="hypervisor"/> <!-- CONCEALMENT: Clears CPUID.1:ECX[31] (Hypervisor Present bit) -->
   
    <!-- Speculative Execution Mitigations -->
    <feature policy="disable" name="ssbd"/>       <!-- CONCEALMENT: Disables Speculative Store Bypass Disable flag -->
    <feature policy="disable" name="amd-ssbd"/>   <!-- CONCEALMENT: Disables AMD's Speculative Store Bypass Disable flag -->
    <feature policy="disable" name="virt-ssbd"/>  <!-- CONCEALMENT: Disables virtualized speculative store bypass mitigation -->
   
    <!-- Timing Features -->
    <feature policy="disable" name="rdtscp"/>     <!-- Disables the RDTSCP instruction (Use if using patched kernel) -->
  </cpu>





  <!--
  <> https://libvirt.org/formatdomain.html#time-keeping

 
 
  -->
  <clock offset="localtime">
    <timer name="tsc" present="yes" mode="native"/>
    <timer name="kvmclock" present="no"/>    <!-- CONCEALMENT: Disable KVM paravirtual clock source -->
    <timer name="hypervclock" present="no"/> <!-- CONCEALMENT: Disable Hyper-V paravirtual clock source -->
  </clock>





  <!--
  <> https://libvirt.org/formatdomain.html#power-management

  Guest power-management sleep states
  -->
  <pm>
    <suspend-to-mem enabled="yes"/>  <!-- CONCEALMENT: Enables S3 ACPI sleep state (suspend-to-RAM) support in the guest -->
    <suspend-to-disk enabled="yes"/> <!-- CONCEALMENT: Enables S4 ACPI sleep state (suspend-to-disk/hibernate) support in the guest -->
  </pm>





  <devices>
    <emulator>/opt/Hypervisor-Phantom/emulator/bin/qemu-system-x86_64</emulator> <!-- 'qemu-system-x86_64' binary location. -->
    




    <!--
    <> https://libvirt.org/formatdomain.html#hard-drives-floppy-disks-cdroms

    If you have a spare physical NVMe SSD, use that instead by doing PCI passthrough via libvirt.
    -->
    <disk type="file" device="disk"> <!-- Use block devices (partitons) for better performance -->
      <driver name="qemu" type="raw" cache="none" io="native" discard="unmap"/> <!-- use io="threads" in block mode -->
      <source file="/var/lib/libvirt/images/win10.img"/>
      <target dev="sdd" bus="nvme"/> <!-- Switch to '<source dev="/dev/sdb"/>' for using a host SATA drive. -->
      <serial>????????????????????</serial> <!-- Serial number -->
      <boot order="1"/>
      <address type="drive" controller="0" bus="0" target="0" unit="0"/>
    </disk>




 
    <!--
    <> https://libvirt.org/formatdomain.html#network-interfaces

   
    -->
    <interface type="network">
      <mac address="XX:XX:XX:XX:XX:XX"/> <!-- Randomize MAC address! -->
      <source network="default"/> <!-- DO NOT USE "VirtIO" -->
    </interface>





    <!--
    <> https://libvirt.org/formatdomain.html#tpm-device

    TPM emulation requires the 'swtpm' package to function properly.
    -->
    <tpm model="tpm-crb">
      <backend type="emulator" version="2.0"/>
    </tpm>





    <!--
    <> https://libvirt.org/formatdomain.html#memory-balloon-device

    Disables the virtio memory balloon device (no ballooning / dynamic RAM adjustment)
    -->
    <memballoon model="none"/>





    <!--
    <> https://libvirt.org/formatdomain.html#video-devices

    Set the video model to "none" to prevent detection of a virtualized environment.
    Virtualized video devices can be a giveaway of a hypervisor, especially if the vendor ID is not spoofed.
    
    Setting the video model to "none" ensures that no virtual video device is presented to the guest, which
    can help avoid detection of the underlying hypervisor.
    
    Additionally, if you're using the Looking Glass shared-memory-device program, setting the video model to
    "none" is necessary to ensure proper functionality, as Looking Glass relies on a direct framebuffer access method.
    -->
    <video>
      <model type="none"/>
    </video>





    <!--
    <> https://libvirt.org/formatdomain.html#shared-memory-device
    <> https://looking-glass.io/docs/B7/install/#ivshmem

    +----------------------+------------------------+----------------------------+
    | Resolution           | Standard Dynamic Range | High Dynamic Range (HDR) * |
    +----------------------+------------------------+----------------------------+
    | 1920x1080 (1080p)    | 32                     | 64                         |
    | 1920x1200 (1200p)    | 32                     | 64                         |
    | 2560x1440 (1440p)    | 64                     | 128                        |
    | 3840x2160 (2160p/4K) | 128                    | 256                        |
    +----------------------+------------------------+----------------------------+
    -->
    <shmem name="looking-glass">
      <model type="ivshmem-plain"/>
      <size unit="M">32</size>
    </shmem>
  </devices>





  <!--
  <> https://www.qemu.org/docs/master/system/qemu-manpage.html#hxtool-4
  <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.9.0.pdf

  
  -->
  <qemu:commandline>

    <!-- Spoofs ACPI table data (Battery) -->
    <qemu:arg value="-acpitable"/>
    <qemu:arg value="file=/opt/Hypervisor-Phantom/firmware/SSDT*-battery.aml"/>
   
    <!-- Spoofs the entire SMBIOS using a host dump -->
    <qemu:arg value="-smbios"/>
    <qemu:arg value="file=/opt/Hypervisor-Phantom/firmware/smbios.bin"/>
   
    <!-- Spoofs the SMBIOS DMI Type 1, 2, 3, 4 and 17 HWIDs
    Type 0 (BIOS / Firmware) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A74%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C260%2C0%5D
    Type 1 (System Information) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A85%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C212%2C0%5D
    Type 2 (Baseboard / Motherboard) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A91%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C206%2C0%5D
    Type 3 (Chassis / Computer Case) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A99%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C178%2C0%5D
    Type 4 (Processor / CPU) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A114%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C583%2C0%5D
    Type 17 (Memory / RAM) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A258%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C597%2C0%5D
    -->
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=0,version=XXXXXXX,date=XX/XX/XXXX,uefi=true"/> <!-- Explicitly marks the BIOS as UEFI-compliant -->
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=1,serial=To be filled by O.E.M.,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"/>  <!-- UUID Spoofer; You can spoof this UUID to any UUID -->
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=2,serial=To be filled by O.E.M."/>
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=3,serial=To be filled by O.E.M."/>
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=4,sock_pfx={Your socket designation},manufacturer=Advanced Micro Devices,, Inc.,version={Your CPU model name},max-speed={X},current-speed={X}"/>
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=17,loc_pfx=Controller0-ChannelA-DIMM0,bank=BANK 0,manufacturer=Samsung,serial=Unknown,asset=Not Specified,part=Not Specified,speed=4800"/>

    <!-- IVSHMEM with the KVMFR module
    The kernel module implements a basic interface to the IVSHMEM device for Looking Glass allowing DMA GPU transfers.
    -->
    <qemu:arg value="-device"/>
    <qemu:arg value="{'driver':'ivshmem-plain','id':'shmem0','memdev':'looking-glass'}"/>
    <qemu:arg value="-object"/>
    <qemu:arg value="{'qom-type':'memory-backend-file','id':'looking-glass','mem-path':'/dev/kvmfr0','size':33554432,'share':true}"/>
   
  </qemu:commandline>





  <!--
  <> https://libvirt.org/formatdomain.html#hard-drives-floppy-disks-cdroms
  <> https://libvirt.org/drvqemu.html#overriding-properties-of-qemu-devices

  TL;DR - Only use this if your host is SSD-backed and you're using virtual storage (Ex. .qcow) for guest.
 
  Use override for SATA device properties to optimize discard handling and rotation settings for SSD-backed qcow virtual storage.
  This configuration allows you to specify advanced disk properties that help optimize performance for SSD-backed virtual disks,
  particularly with regard to discard operations and rotation rate. The properties below control specific QEMU disk device features:

  - `rotation_rate`: Sets the rotation rate of the virtual disk. A value of `1` indicates that the disk is an
                     SSD (solid-state drive), optimizing I/O behavior for non-rotational storage.

  - `discard_granularity`: Controls the granularity of discard operations. Setting this value to `0` can optimize how the
                           guest OS handles the discard requests, affecting the performance of SSD-backed virtual disks.

  This setup is recommended for systems using SSD-backed virtual storage in qcow format, as it improves compatibility and
  performance when using discard operations and better reflects the behavior of SSD storage.
  -->
  <qemu:override>
    <qemu:device alias="sata0-0-0">
      <qemu:frontend>
        <qemu:property name="rotation_rate" type="unsigned" value="1"/>
        <qemu:property name="discard_granularity" type="unsigned" value="0"/>
      </qemu:frontend>
    </qemu:device>
  </qemu:override>
</domain>
```

</details>


### Intel Libvirt XML Reference:

<details>
<summary>Expand for XML...</summary>

```xml
<!--
  ******************************************************************************
  *                              IMPORTANT NOTICE                              *
  ******************************************************************************
  *                                                                            *
  *  DO NOT BLINDLY COPY AND PASTE THIS CONFIGURATION.                         *
  *                                                                            *
  *  This XML configuration is provided as a template and should be carefully  *
  *  reviewed and adjusted to match your specific system requirements.         *
  *                                                                            *
  *  Always work section by section, ensuring that each parameter is           *
  *  appropriate for your environment. Blindly copying and pasting may lead    *
  *  to misconfigurations, security vulnerabilities, or system instability.    *
  *                                                                            *
  *  Take the time to understand each setting and modify it as needed.         *
  *                                                                            *
  ******************************************************************************
-->

<domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm"> <!-- Don't forget XMLNS! -->
  <uuid>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX</uuid> <!-- FYI: This is NOT the guest system's UUID in SMBIOS! -->

  <memory unit="G">16</memory>  <!-- Utilize realistic memory amounts, such as 8, 16, 32, and 64. -->
  <currentMemory unit="G">16</currentMemory>





  <!--
  <> https://libvirt.org/formatdomain.html#operating-system-booting

 
  -->
  <os>
    <type arch="x86_64" machine="pc-q35-10.2">hvm</type>
    <loader readonly="yes" secure="yes" type="pflash" format="qcow2">/opt/Hypervisor-Phantom/firmware/OVMF_CODE.qcow2</loader>
    <nvram template="/opt/Hypervisor-Phantom/firmware/OVMF_VARS.qcow2" format="qcow2"></nvram>
    <bootmenu enable="yes"/>
    <smbios mode="host"/> <!-- Remove if 'smbios.bin' is being passed through -->
  </os>





  <!-- 
  <> https://libvirt.org/formatdomain.html#hypervisor-features

 
  -->
  <features>
    <acpi/>
    <apic/>
    <!-- Disable all enlightenments, if Hyper-V method is not used.
    Enlightenments on "bare-metal" are extremely suspicious -->
    <hyperv mode="custom">
      <relaxed state="off"/>
      <vapic state="off"/>
      <spinlocks state="off"/>
      <vpindex state="off"/>
      <runtime state="off"/>
      <synic state="off"/>
      <stimer state="off"/>
      <reset state="off"/>
      <vendor_id state="on" value="GenuineIntel"/> <!-- KVM patch NOT present | Apply to fix NVIDIA (Code 43) error -->
      <vendor_id state="off"/>                     <!-- KVM patch IS present -->
      <frequencies state="off"/>
      <reenlightenment state="off"/>
      <tlbflush state="off"/>
      <ipi state="off"/>
      <evmcs state="off"/>
      <avic state="off"/>
      <emsr_bitmap state="off"/>
      <xmm_input state="off"/>
    </hyperv>
    <kvm>
      <hidden state="on"/> <!-- CONCEALMENT: Hide the KVM hypervisor from standard MSR based discovery (CPUID Bitset) -->
    </kvm>
    <pmu state="off"/> <!-- CONCEALMENT: Disables the Performance Monitoring Unit (PMU) -->
    <vmport state="off"/> <!-- CONCEALMENT: Disables the VMware I/O port backdoor (VMPort, 0x5658) in the guest | FYI: ACE AC looks for this -->
    <smm state="on"/>
    <msrs unknown="fault"/> <!-- CONCEALMENT: Injects a #GP(0) into the guest on RDMSR/WRMSR to an unhandled/unknown MSR -->
  </features>





  <!--
  <> https://libvirt.org/formatdomain.html#cpu-model-and-topology

 
  -->
  <cpu mode="host-passthrough" check="none" migratable="off">
    <topology sockets="1" dies="1" clusters="1" cores="8" threads="2"/>
    <cache mode="passthrough"/>
    <maxphysaddr mode="passthrough"/>
    
    <!-- Performance Features -->
    <feature policy="require" name="vmx"/>        <!-- OPTIMIZATION: Requires Intel VT-x (hardware virtualization) to be exposed to the guest (needed for nested virtualization) -->
    <feature policy="require" name="invtsc"/>     <!-- OPTIMIZATION: Requires invariant TSC (stable time-stamp counter rate across P-states/C-states) for more consistent guest timekeeping -->
  
    <!-- Hypervisor Detection -->
    <feature policy="disable" name="hypervisor"/> <!-- CONCEALMENT: Clears CPUID.1:ECX[31] (Hypervisor Present bit) -->
   
    <!-- Speculative Execution Mitigations -->
    <feature policy="disable" name="ssbd"/>       <!-- CONCEALMENT: Disables Speculative Store Bypass Disable flag -->
    <feature policy="disable" name="virt-ssbd"/>  <!-- CONCEALMENT: Disables virtualized speculative store bypass mitigation -->
   
    <!-- Timing Features -->
    <feature policy="disable" name="rdtscp"/>     <!-- Disables the RDTSCP instruction (Use if using patched kernel) -->
  </cpu>





  <!--
  <> https://libvirt.org/formatdomain.html#time-keeping

 
  -->
  <clock offset="localtime">
    <timer name="tsc" present="yes" mode="native"/>
    <timer name="kvmclock" present="no"/>    <!-- CONCEALMENT: Disable KVM paravirtual clock source -->
    <timer name="hypervclock" present="no"/> <!-- CONCEALMENT: Disable Hyper-V paravirtual clock source -->
  </clock>





  <!--
  <> https://libvirt.org/formatdomain.html#power-management

  Guest power-management sleep states
  -->
  <pm>
    <suspend-to-mem enabled="yes"/>  <!-- CONCEALMENT: Enables S3 ACPI sleep state (suspend-to-RAM) support in the guest -->
    <suspend-to-disk enabled="yes"/> <!-- CONCEALMENT: Enables S4 ACPI sleep state (suspend-to-disk/hibernate) support in the guest -->
  </pm>





  <devices>
    <emulator>/opt/Hypervisor-Phantom/emulator/bin/qemu-system-x86_64</emulator> <!-- 'qemu-system-x86_64' binary location. -->





    <!--
    <> https://libvirt.org/formatdomain.html#hard-drives-floppy-disks-cdroms

    If you have a spare physical NVMe SSD, use that instead by doing PCI passthrough via libvirt.
    -->
    <disk type="file" device="disk"> <!-- Use block devices (partitons) for better performance -->
      <driver name="qemu" type="raw" cache="none" io="native" discard="unmap"/> <!-- use io="threads" in block mode -->
      <source file="/var/lib/libvirt/images/win10.img"/>
      <target dev="sdd" bus="nvme"/> <!-- Switch to '<source dev="/dev/sdb"/>' for using a host SATA drive. -->
      <serial>????????????????????</serial> <!-- Serial number -->
      <boot order="1"/>
      <address type="drive" controller="0" bus="0" target="0" unit="0"/>
    </disk>





    <!--
    <> https://libvirt.org/formatdomain.html#network-interfaces

   
    -->
    <interface type="network">
      <mac address="XX:XX:XX:XX:XX:XX"/> <!-- Randomize MAC address! -->
      <source network="default"/> <!-- DO NOT USE "VirtIO" -->
    </interface>





    <!--
    <> https://libvirt.org/formatdomain.html#tpm-device

    TPM emulation requires the 'swtpm' package to function properly.
    -->
    <tpm model="tpm-crb">
      <backend type="emulator" version="2.0"/>
    </tpm>





    <!--
    <> https://libvirt.org/formatdomain.html#memory-balloon-device

    Disables the virtio memory balloon device (no ballooning / dynamic RAM adjustment)
    -->
    <memballoon model="none"/>





    <!--
    <> https://libvirt.org/formatdomain.html#video-devices

    Set the video model to "none" to prevent detection of a virtualized environment.
    Virtualized video devices can be a giveaway of a hypervisor, especially if the vendor ID is not spoofed.
    
    Setting the video model to "none" ensures that no virtual video device is presented to the guest, which
    can help avoid detection of the underlying hypervisor.
    
    Additionally, if you're using the Looking Glass shared-memory-device program, setting the video model to
    "none" is necessary to ensure proper functionality, as Looking Glass relies on a direct framebuffer access method.
    -->
    <video>
      <model type="none"/>
    </video>





    <!--
    <> https://libvirt.org/formatdomain.html#shared-memory-device
    <> https://looking-glass.io/docs/B7/install/#ivshmem

    +----------------------+------------------------+----------------------------+
    | Resolution           | Standard Dynamic Range | High Dynamic Range (HDR) * |
    +----------------------+------------------------+----------------------------+
    | 1920x1080 (1080p)    | 32                     | 64                         |
    | 1920x1200 (1200p)    | 32                     | 64                         |
    | 2560x1440 (1440p)    | 64                     | 128                        |
    | 3840x2160 (2160p/4K) | 128                    | 256                        |
    +----------------------+------------------------+----------------------------+
    -->
    <shmem name="looking-glass">
      <model type="ivshmem-plain"/>
      <size unit="M">32</size>
    </shmem>
  </devices>





  <!--
  <> https://www.qemu.org/docs/master/system/qemu-manpage.html#hxtool-4
  <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.9.0.pdf

 
  -->
  <qemu:commandline>

    <!-- Spoofs ACPI table data (Battery) -->
    <qemu:arg value="-acpitable"/>
    <qemu:arg value="file=/opt/Hypervisor-Phantom/firmware/SSDT*-battery.aml"/>
   
    <!-- Spoofs the entire SMBIOS using a host dump -->
    <qemu:arg value="-smbios"/>
    <qemu:arg value="file=/opt/Hypervisor-Phantom/firmware/smbios.bin"/>
   
    <!-- Spoofs the SMBIOS DMI Type 1, 2, 3, 4 and 17 HWIDs
    Type 0 (BIOS / Firmware) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A74%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C260%2C0%5D
    Type 1 (System Information) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A85%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C212%2C0%5D
    Type 2 (Baseboard / Motherboard) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A91%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C206%2C0%5D
    Type 3 (Chassis / Computer Case) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A99%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C178%2C0%5D
    Type 4 (Processor / CPU) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A114%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C583%2C0%5D
    Type 17 (Memory / RAM) <> https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf#%5B%7B%22num%22%3A258%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70%2C597%2C0%5D
    -->
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=0,version=XXXXXXX,date=XX/XX/XXXX,uefi=true"/> <!-- Explicitly marks the BIOS as UEFI-compliant -->
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=1,serial=To be filled by O.E.M.,uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"/>  <!-- UUID Spoofer; You can spoof this UUID to any UUID -->
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=2,serial=To be filled by O.E.M."/>
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=3,serial=To be filled by O.E.M."/>
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=4,sock_pfx={Your socket designation},manufacturer=Intel(R) Corporation,version={Your CPU model name},max-speed={X},current-speed={X}"/>
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=17,loc_pfx=Controller0-ChannelA-DIMM0,bank=BANK 0,manufacturer=Samsung,serial=Unknown,asset=Not Specified,part=Not Specified,speed=4800"/>

    <!-- IVSHMEM with the KVMFR module
    The kernel module implements a basic interface to the IVSHMEM device for Looking Glass allowing DMA GPU transfers.
    -->
    <qemu:arg value="-device"/>
    <qemu:arg value="{'driver':'ivshmem-plain','id':'shmem0','memdev':'looking-glass'}"/>
    <qemu:arg value="-object"/>
    <qemu:arg value="{'qom-type':'memory-backend-file','id':'looking-glass','mem-path':'/dev/kvmfr0','size':33554432,'share':true}"/>
   
  </qemu:commandline>





  <!--
  <> https://libvirt.org/formatdomain.html#hard-drives-floppy-disks-cdroms
  <> https://libvirt.org/drvqemu.html#overriding-properties-of-qemu-devices

  TL;DR - Only use this if your host is SSD-backed and you're using virtual storage (Ex. .qcow) for guest.
 
  Use override for SATA device properties to optimize discard handling and rotation settings for SSD-backed qcow virtual storage.
  This configuration allows you to specify advanced disk properties that help optimize performance for SSD-backed virtual disks,
  particularly with regard to discard operations and rotation rate. The properties below control specific QEMU disk device features:

  - `rotation_rate`: Sets the rotation rate of the virtual disk. A value of `1` indicates that the disk is an
                     SSD (solid-state drive), optimizing I/O behavior for non-rotational storage.

  - `discard_granularity`: Controls the granularity of discard operations. Setting this value to `0` can optimize how the
                           guest OS handles the discard requests, affecting the performance of SSD-backed virtual disks.

  This setup is recommended for systems using SSD-backed virtual storage in qcow format, as it improves compatibility and
  performance when using discard operations and better reflects the behavior of SSD storage.
  -->
  <qemu:override>
    <qemu:device alias="sata0-0-0">
      <qemu:frontend>
        <qemu:property name="rotation_rate" type="unsigned" value="1"/>
        <qemu:property name="discard_granularity" type="unsigned" value="0"/>
      </qemu:frontend>
    </qemu:device>
  </qemu:override>
</domain>
```

</details>




</details>
