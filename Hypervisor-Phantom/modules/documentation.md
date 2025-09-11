# EDK2 / OVMF / Firmware

- https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions
- https://github.com/tianocore/tianocore.github.io/wiki/How-to-build-OVMF
- https://github.com/tianocore/edk2/tree/master/OvmfPkg

#### NVRAM Template:

```
sudo pacman -S edk2-ovmf
```

```
usr/share/edk2/x64/MICROVM.4m.fd
usr/share/edk2/x64/OVMF.4m.fd
usr/share/edk2/x64/OVMF_CODE.4m.fd
usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd
usr/share/edk2/x64/OVMF_VARS.4m.fd
```

#### STORAGE:

```
/var/lib/libvirt/images/
```

#### Generated firmware from template that is writable:

```
/var/lib/libvirt/qemu/nvram
```

---

# QEMU / Emulator


