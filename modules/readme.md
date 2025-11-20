# EDK2 / OVMF / Firmware

- https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions
- https://github.com/tianocore/tianocore.github.io/wiki/How-to-build-OVMF
- https://github.com/tianocore/edk2/tree/master/OvmfPkg

#### NVRAM Template:

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

#### BmpImageDecoder (BMP Validator)

- https://github.com/tianocore/edk2/blob/master/BaseTools/Source/Python/AutoGen/GenC.py#L1892
  - File Type: Bytes `0–1` must be `0x42 0x4D`
  - Bit Depth: Must be `1`, `4`, `8`, or `24`
  - Compression: Must be `0`
  - Width/Height: `≤65535x65535`

#### virt-fw-vars

- [virt-fw-vars - man page](https://man.archlinux.org/man/extra/virt-firmware/virt-fw-vars.1.en)
- [json support for efi - python script](https://gitlab.com/kraxel/virt-firmware/-/blob/master/virt/firmware/efi/efijson.py)

#### Secure Boot

- [https://github.com/microsoft/secureboot_objects](https://github.com/microsoft/secureboot_objects)
  - PostSignedObjects
    - [DBXUpdate.bin](https://github.com/microsoft/secureboot_objects/blob/main/PostSignedObjects/DBX/amd64/DBXUpdate.bin)
  - PreSignedObjects
    - [PK,KEK,DB.der](https://github.com/microsoft/secureboot_objects/blob/main/PreSignedObjects)

#### Generated firmware from template that is writable:

```
/var/lib/libvirt/qemu/nvram
```

#### STORAGE:

```
/var/lib/libvirt/images/
```


---

# QEMU / Emulator

#### evdev

- [Input devices](https://libvirt.org/formatdomain.html#input-devices)

| Category             | Attribute       | Value / Options                                                                  |
|----------------------|-----------------|----------------------------------------------------------------------------------|
| **Keyboards**        | grab            | all                                                                              |
|                      | grabToggle      | shift-shift                                                                      |
|                      | repeat          | on                                                                               |
| **Mice**             | grabToggle      | shift-shift                                                                      |
| **evdev attributes** | grab            | all                                                                              |
|                      | repeat          | on / off                                                                         |
|                      | grabToggle      | ctrl-ctrl, alt-alt, shift-shift, meta-meta, scrolllock, ctrl-scrolllock          |
