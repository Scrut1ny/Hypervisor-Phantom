## Info & Guide
<details>
<summary>Proctoring Software</summary>

| Software | Browser Extension | System Test | Bypassed | Difficulty |
| - | - | - | - | - |
| Pafish |  | [Link](https://github.com/a0rtega/pafish/releases/download/v0.6/pafish64.exe) | ✅ | 🤬 |
| Al-Khaser |  | [Link](https://github.com/LordNoteworthy/al-khaser) | ❔ | 🤬 |
| Safe Exam Browser |  | [Link](https://github.com/SafeExamBrowser/seb-win-refactoring) | ✅ | 😤 |
| Pearson VUE |  | [Link](https://system-test.onvue.com/system_test?customer=pearson_vue) | ✅ | 🤬 |
| ProctorU | ✅ | [FF Addon](https://s3-us-west-2.amazonaws.com/proctoru-assets/extension/firefox-extension-latest.xpi) or [Chrome Addon](https://chrome.google.com/webstore/detail/proctoru/goobgennebinldhonaajgafidboenlkl) | ✅ | 🤨 |
| ProctorU: Guardian Browser |  | [Link](https://guardian.meazurelearning.com/) | ✅ | 😤 |
| Proctorio | ✅ | [Link](https://getproctorio.com/) | ✅ | 😂 |
| Examity |  |  | ❔ |  |
| Respondus (LockDown Browser) | ✅ | [Link](https://download.respondus.com/lockdown/download.php) | ❔ |  |
| Kryterion |  |  | ❔ |  |
| Honorlock | ✅ | [Link](https://app.honorlock.com/install/extension) | ✅ | 😂 |

</details>

<details>
<summary>QEMU Anti Detection</summary>

| Type | Engine | Bypassed |
|-|-|-|
| **Anti-Cheat** | Anti Cheat Expert(ACE) | ✅ |
| **Anti-Cheat** | BattlEye (BE) | ✅ |
| **Anti-Cheat** | Easy Anti-Cheat(EAC) | ✅ |
| **Anti-Cheat** | Gepard Shield | ✅ (With RDTSC VM Force Exit Kernal Patch) |
| **Anti-Cheat** | Mhyprot | ✅ |
| **Anti-Cheat** | nProtect GameGuard(NP) | ✅ |
| **Anti-Cheat** | Roblex | ‼️(The application encountered an unrecoverable error) |
| **Anti-Cheat** | Vanguard | ‼️(1: Incorrect function) |
| **Encrypt** | Enigma Protector | ✅ |
| **Encrypt** | Safegine Shielden | ✅ |
| **Encrypt** | Themida | ✅ |
| **Encrypt** | VMProtect | ✅ |
| **Encrypt** | VProtect | ✅ |

- ‼️ Some games cannot run under this environment, but I'm not sure whether qemu has been detected. The game doesn't say "Virtual machine detected" specifically.

</details>

<details>
<summary>Proctoring Functions</summary>
<details>
<summary>Honorlock</summary>
    
| **Function** | **Description** |
|-|-|
| Record Webcam | Record student's testing enviroment using webcam |
| Record Screen | Record student's screen during exam |
| Record Web Traffic | Log student's internet activity |
| Room Scan | Record a 360 degree enviroment scan before the assessment begins |
| Disable Copy/Paste | Block clipboard actions |
| Disable Printing | Block printing exam content |
| Browser Guard | Limit browser activity to exam content and allowed site URLs only |
| Allowed Site URLs | Allow access to specific websites during an exam session |
| Student Photo | Capture student photo before the assessment begins |
| Student ID | Capture ID photo before the assessment begins |
  
</details>

<details>
<summary>Proctorio</summary>
  
| **Recording Settings** | **Verification Settings** | **Lock Down Settings** |
|-|-|-|
| Record Video | Verify Video | Force Full Screen |
| Record Audio | Verify Audio | Only One Screen |
| Record Screen | Verify Identity | Disable New Tabs |
| Record Web Traffic | Verify Desktop | Close Open Tabs |
| Record Desk | Verify Signature | Disable Printing |
|  |  | Disable Clipboard |
|  |  | Clear Cache |
|  |  | Disable Right Click |
|  |  | Prevent Re-Entry |

</details>
</details>

<details>
<summary>Hypervisor Setup Guide</summary>
<details>
<summary>VirtualBox</summary>

### Virtual Box - VBoxManage Tool Location:
```
Linux: /usr/bin/VBoxManage
Mac OS X: /Applications/VirtualBox.app/Contents/MacOS/VBoxManage
Oracle Solaris: /opt/VirtualBox/bin/VBoxManage
Windows: C:\Program Files\Oracle\VirtualBox\VBoxManage.exe
```

### Run these scripts:
* Configure the VM: `VM-External-Modifer.ps1`
* Spoof Windows: `VM-Internal-Modifier.ps1`

### ExecutionPolicy Modifier:
```
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

</details>

<details>
<summary>VMware</summary>

### VMware PRO License Key:
```
MC60H-DWHD5-H80U9-6V85M-8280D
```

### Patching BIOS ROM
1. Locate file `BIOS.440.ROM` within `%PROGRAMFILES(X86)%\VMware\VMware Workstation\x64`.
2. Utilize [Phoenix BIOS Editor](https://mega.nz/file/cek3ARwR#0L3mXNAlknF0zJQPOmtqPoyAvF5exviI3zw_BfRixOk) to modify compromising DMI Strings, like `VMware` or `Virtual Platform`.
3. Once completed, go to `File` then `Build BIOS` and save the patched BIOS somewhere. **Don't overwrite the original file!**
4. Now within the `*.vmx` config file, make sure to add the new patched BIOS location for the `bios440.filename` argument line.

### Set Custom CPUID (optional)
![image](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/fed4e5e8-4ea3-4001-80f3-e84fce123c8e)

### Add the following into your *.vmx
```
bios440.filename = "C:\<path_to_your_bios_file>\BIOS.440.PATCH.ROM"
hypervisor.cpuid.v0 = "FALSE"
smbios.reflectHost = "TRUE"
ethernet0.address = "00:C0:CA:A7:2B:9E"
isolation.tools.getPtrLocation.disable = "TRUE"
isolation.tools.setPtrLocation.disable = "TRUE"
isolation.tools.setVersion.disable = "TRUE"
isolation.tools.getVersion.disable = "TRUE"
monitor_control.restrict_backdoor = "TRUE"
monitor_control.virtual_rdtsc = "FALSE"
```

### **IMPORTANT**
* `smbios.reflectHost` will NOT fully function properly if UEFI firmware is used without the BIOS ROM patch. If you use BIOS firmware instead, you don't have to worry about doing the BIOS ROM patch (you can still do it if you want though).

### Run these scripts:
* Spoof Windows: `VM-Internal-Modifier.ps1`

### ExecutionPolicy Modifier:
```
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

</details>

<details>
<summary>QEMU</summary>

* [Domain XML format](https://libvirt.org/formatdomain.html)

## QEMU + Virt-Manager Setup
```
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean -y
sudo apt install qemu-system-x86 libvirt-clients libvirt-daemon-system libvirt-daemon-config-network bridge-utils virt-manager ovmf
sudo usermod -a -G kvm,libvirt $(whoami)
sudo systemctl enable libvirtd && sudo systemctl start libvirtd && sudo groups $(whoami)
sudo virsh net-autostart default && sudo virsh net-start default
virt-manager
```

## QEMU Strings Patch [smbios, ACPI Tables, USB, etc...]
* [qemu-patch-bypass](https://github.com/zhaodice/qemu-anti-detection)

### Installing Dependancies:
```
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt install -y binutils-mingw-w64 binutils-mingw-w64-i686 binutils-mingw-w64-x86-64 build-essential clang g++-mingw-w64 g++-mingw-w64-i686 g++-mingw-w64-x86-64 gcc-mingw-w64 gcc-mingw-w64-i686 gcc-mingw-w64-x86-64 git git-email gnutls-bin libaio-dev libbluetooth-dev libbrlapi-dev libbz2-dev libcacard-dev libcap-dev libcap-ng-dev libcurl4-gnutls-dev libfdt-dev libglib2.0-dev libgtk-3-dev libibverbs-dev libiscsi-dev libjpeg8-dev liblzo2-dev libncurses5-dev libncursesw5-dev libnfs-dev libnuma-dev libpam0g-dev libpixman-1-dev librbd-dev librdmacm-dev libseccomp-dev libsnappy-dev libsasl2-dev libsdl1.2-dev libsdl2-dev libsdl2-image-dev libspice-protocol-dev libspice-server-dev libusb-1.0-0-dev libusb-dev libusbredirparser-dev libusbredirparser1 libvde-dev libvdeplug-dev libvirglrenderer-dev libvte-2.91-dev libxen-dev libxml2-dev libz-mingw-w64-dev libzstd-dev ninja-build valgrind win-iconv-mingw-w64-dev xfslibs-dev zlib1g-dev
```

### Downloading & Building QEMU w/patch
```
cd /home/$(whoami)/Downloads && git clone https://gitlab.com/qemu-project/qemu/ -b v8.2.1 --depth 1 --recursive

cd qemu && git apply qemu8.2.1.patch && cd .. && mkdir qemu_build && cd qemu_build && ../qemu/configure --target-list=x86_64-softmmu,x86_64-linux-user --prefix=/usr && make -j $(nproc) && sudo make install

mv qemu-system-x86_64 /bin
```

## QEMU RDTSC VM_Exit Kernal Patch
* [RDTSC-KVM-Handler](https://github.com/Gyztor/kernel-rdtsc-patch)

## PCIe Passthrough (Debian Guide)
* [YT Guide #1](https://www.youtube.com/watch?v=g--fe8_kEcw)
* [YT Guide #2](https://www.youtube.com/watch?v=KVDUs019IB8)
* [YT Guide #3](https://www.youtube.com/watch?v=jc3PjDX-CGs)
* [Article Guide](https://mathiashueber.com/windows-virtual-machine-gpu-passthrough-ubuntu/)
* [Amazing Single GPU Passthrough Guide](https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/home)

### 1. Make sure to enable the following in the host UEFI/BIOS

| **AMD CPU** | **Intel CPU** |
|-|-|
| IOMMU | VT-D |
| NX | VT-X |
| SVM |  |

### Requirements
- Virtualization Check
```bash
LC_ALL=C lscpu | grep Virtualization && egrep -c '(vmx|svm)' /proc/cpuinfo
```<hyperv
- IOMMU Groups
```bash
lspci -nn | grep "NVIDIA"
```
or
```bash
#!/bin/bash
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
```

### Modify grub.cfg
- GRUB_CMDLINE_LINUX_DEFAULT="amd_iommu=on iommu=pt vfio-pci.ids=XXXX:XXXX,XXXX:XXXX,XXXX:XXXX,XXXX:XXXX"
```bash
sudo nano /etc/default/grub
```

### Update grub.cfg & reboot
```bash
sudo update-grub && sudo reboot now
```

### Modify vfio.conf (isolate GPU)
- options vfio-pci ids=XXXX:XXXX,XXXX:XXXX,XXXX:XXXX,XXXX:XXXX
- softdep nvidia pre: vfio-pci
```bash
sudo nano /etc/modprobe.d/vfio.conf
```

### Update initramfs
```bash
sudo update-initramfs -c -k $(uname -r) && sudo reboot now
```

### Check kernal driver in use for the GPU (should be vfio-pci)
```bash
lspci -k | grep -E "vfio-pci|NVIDIA"
```

## QEMU Virt-Manager Setup

1. Create a new virtual machine
2. Local install media (ISO image or CDROM)
3. Select a [Windows ISO](https://massgrave.dev/msdl/) and enter the OS you're using
4. Set a realistic amount of RAM (make sure its half of the full amount)

| GB | MBs |
|-|-|
| 8 | 8192 |
| 16 | 16384 |
| 32 | 32768 |

5. Set 1 less of the maximum amount of CPUs available
6. Set a virtual disk size of above 250GB+
7. Select "Customize configuration before install" and finish
8. Select `UEFI x86_64:/usr/share/OVMF/OVMF_CODE_4M.ms.fd` for the Firmware, then apply
8a. If you want to use Windows 11 you need to use `UEFI x86_64:/usr/share/qemu/edk2-x86_64-secure-code.fd` instead
9. Under `CPUs`, check `Copy host CPU configuration (host-passthrough)`
9a. Drop down `Topology` and check `Manually set CPU topology` then input whatever works with your system, then apply

| Sockets: | Cores: | Threads: |
|-|-|-|
| 1 | X | X |

11. Under `Boot Options` check `SATA CDROM 1`, then apply
12. Under `SATA Disk 1` and `SATA CDROM 1` drop down `Advanced options` and set a random custom serial #, then apply
13. Under `NIC:XX:XX:XX` select the drop down menu and pick `hypervisor default`
12a. Set a custom MAC address, make sure the vendor isn't a hypervisor vendor! then apply
14. Select `Add Hardware` and under `PCI Host Device` add ALL devices under the isolated GPU IOMMU group you figured out earlier
15. Now select `Begin Installation`, and enjoy your new undetectable windows system!

## QEMU XML Config
```
  <os>
    <bootmenu enable="no"/>
    <smbios mode="host"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode="custom">
      <relaxed state="on"/>
      <vapic state="on"/>
      <spinlocks state="on" retries="8191"/>
      <vpindex state="on"/>
      <runtime state="on"/>
      <synic state="on"/>
      <stimer state="on"/>
      <reset state="on"/>
      <vendor_id state="on" value="AuthenticAMD"/>
      <frequencies state="on"/>
    </hyperv>
    <kvm>
      <hidden state="on"/>
    </kvm>
    <vmport state="off"/>
  </features>
  <cpu mode="host-passthrough" check="none">
    <topology sockets="1" dies="1" cores="8" threads="2"/>
    <cache mode="passthrough"/>
    <feature policy="disable" name="hypervisor"/>
    <feature policy="require" name="invtsc"/>
    <feature policy="require" name="topoext"/>
    <feature policy="require" name="svm"/>
  </cpu>
  <clock offset="utc">
    <timer name="pit" tickpolicy="delay"/>
    <timer name="rtc" tickpolicy="catchup" track="guest"/>
    <timer name="hpet" present="no"/>
    <timer name="tsc" present="yes" mode="native"/>
    <timer name="hypervclock" present="yes"/>
  </clock>
```

### Testing it out...
- Connect an additional DisplayPort or HDMI cable from your spare/isolated GPU to your monitor. Alternatively, you can utilize a DisplayPort or HDMI Bidirectional Switch Splitter for convenience.
    - [DP Bidirectional Switch Splitter](https://www.amazon.com/dp/B0C9PDFYH3)

## QEMU General Patches
* [KVM-Spoofing](https://github.com/A1exxander/KVM-Spoofing)

</details>
</details>

<details>
<summary>Important Tips</summary>
    
* **Avoid NAT Similarities**: Ensure your host and VM have distinct IPv4 addresses within the LAN to prevent obvious signs of VM activity, as identical addresses could signal VM use.
* **Encrypt DNS Queries**: Utilize DNS-over-HTTPS (DoH) to encrypt your DNS queries. Unlike unencrypted DNS, DoH conceals the websites you visit, leaving only the external IP address visible to observers.
* **Opt for a VPN**: Use a VPN to obscure all your internet traffic. However, be cautious with popular VPN services as their IP ranges may be blacklisted by certain proctoring or anti-cheat systems.
* **Allocate Sufficient VM Storage**: Equip your VM with at least 128GB of storage. VMs with lower storage capacities may be more easily identified or flagged by monitoring systems.
* **System Up Time**: Leave the hypervisor running for at least 12+ minutes to bypass the `GetTickCount()` check.

</details>

## Spoofed Hardware/Firmware/Software Information
<details>
<summary>Expand - ⤵️</summary>

| Feature                | VirtualBox | VMware | QEMU |
|------------------------|------------|--------|-------|
| **CPUID**              | ✅         | ✅      | ✅    |
| **SMBIOS**             | ✅         | ✅      | ✅    |
| **MAC Address**        | ✅         | ✅      | ✅    |
| **Solid State Drive (SSD)** | ✅         | ✅      | ✅    |
| **Hard Disk Drive (HDD)** | ✅         | ✅      | ✅    |
| **DVD/CD-ROM drives**  | ✅         | ✅      | ✅    |
| **Registry**           | ✅         | ✅      | ✅    |
| **ACPI Tables**        | ❌         | ❌      | ✅    |
| **EDID**               | ❌         | ❌      | ✅    |
| **USB**                | ❌         | ❌      | ✅    |
| **PCIe Passthrough**   | ❌         | ❌      | ✅    |

</details>

## References & Help
<details>
<summary>General</summary>
    
* [https://evasions.checkpoint.com/](https://evasions.checkpoint.com/)
* [https://bannedit.github.io/Virtual-Machine-Detection-In-The-Browser.html](https://bannedit.github.io/Virtual-Machine-Detection-In-The-Browser.html)

</details>

<details>
<summary>VirtualBox</summary>
    
* [VirtualBox RDTSC Fix](https://www.reddit.com/r/virtualbox/comments/g6ky8a/disabling_vm_exit_for_rdtsc_access/)
* [https://forums.virtualbox.org/viewtopic.php?t=78859](https://forums.virtualbox.org/viewtopic.php?t=78859)
* [https://forums.virtualbox.org/viewtopic.php?t=81600](https://forums.virtualbox.org/viewtopic.php?t=81600)
* [https://superuser.com/questions/625648/virtualbox-how-to-force-a-specific-cpu-to-the-guest](https://superuser.com/questions/625648/virtualbox-how-to-force-a-specific-cpu-to-the-guest)
* [https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108](https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108)
* [https://github.com/d4rksystem/VBoxCloak](https://github.com/d4rksystem/VBoxCloak)
* [https://github.com/nsmfoo/antivmdetection](https://github.com/nsmfoo/antivmdetection)
    
</details>

<details>
<summary>VMware</summary>
    
* [https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/](https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/)
* [https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/](https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/)
* [https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/](https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/)
    
</details>

<details>
<summary>QEMU</summary>

* [Spoof and make your VM Undetectable - No more bullsh*t bans](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/)
* [BE is banning KVM on R6](https://www.reddit.com/r/VFIO/comments/hts1o1/be_is_banning_kvm_on_r6/)
* [KVM Detection fixes](https://www.unknowncheats.me/forum/escape-from-tarkov/418885-kvm-detection-fixes.html)

</details>

## Common Error Solutions

<details>
<summary>Unable to complete install: 'internal error: cannot load AppArmor profile 'libvirt-<UUID>''</summary>

- Set security_driver = "none" in /etc/libvirt/qemu.conf

```
#       security_driver = [ "selinux", "apparmor" ]
#security_driver = "selinux"
security_driver = "none"
```
- restart libvirtd service

```
systemctl restart libvirtd
```

</details>

<details>
<summary>NVIDIA Error 43</summary>

- Add this line in the `<hyperv/>` section in the QEMU XML:

```
<vendor_id state="on" value="AuthenticAMD"/>
```

</details>
