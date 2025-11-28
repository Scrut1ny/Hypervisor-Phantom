# EDK2 / OVMF / Firmware

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
  --define TPM1_ENABLE=TRUE \
  --define TPM2_ENABLE=TRUE \
  --define SMM_REQUIRE=TRUE
```

QEMU XML:
```xml
  <features>
    <acpi/>
    <apic/>
    <smm state="on"/>
  </features>
...
    <tpm model="tpm-crb">
      <backend type="emulator" version="2.0"/>
    </tpm>
```

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


---

# QEMU / Emulator

#### evdev

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
