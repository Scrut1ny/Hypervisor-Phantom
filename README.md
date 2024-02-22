## ExecutionPolicy Modifier:
```
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

## Todo List:
- Fix:
    - RDTSC force VM Exit check
    - Vbox failed to query monitor/displays via SEB [Code Reference](https://github.com/SafeExamBrowser/seb-win-refactoring/blob/master/SafeExamBrowser.Monitoring/Display/DisplayMonitor.cs)

## Proctor Info
<details>
<summary>Proctoring Software</summary>

| Software | Browser Extension | System Test | Bypassed | Difficulty |
| - | - | - | - | - |
| Pafish |  | [Link](https://github.com/a0rtega/pafish/releases/download/v0.6/pafish64.exe) | ✅ |  |
| Al-Khaser |  | [Link](https://github.com/LordNoteworthy/al-khaser) | ❔ |  |
| Safe Exam Browser |  | [Link](https://github.com/SafeExamBrowser/seb-win-refactoring) | ❔ | 😤 |
| Pearson VUE |  | [Link](https://system-test.onvue.com/system_test?customer=pearson_vue) | ❔ | 🤬 |
| ProctorU | ✅ | [FF Addon](https://s3-us-west-2.amazonaws.com/proctoru-assets/extension/firefox-extension-latest.xpi) or [Chrome Addon](https://chrome.google.com/webstore/detail/proctoru/goobgennebinldhonaajgafidboenlkl) | ✅ | 🤨 |
| ProctorU: Guardian Browser |  | [Link](https://guardian.meazurelearning.com/) | ❔ |  |
| Proctorio | ✅ | [Link](https://getproctorio.com/) | ✅ | 😂 |
| Examity |  |  | ❔ |  |
| Respondus (LockDown Browser) | ✅ | [Link](https://download.respondus.com/lockdown/download.php) | ❔ |  |
| Kryterion |  |  | ❔ |  |
| Honorlock | ✅ | [Link](https://app.honorlock.com/install/extension) | ✅ | 😂 |

</details>

<details>
<summary>Anti-Cheat Software</summary>

| Software | Bypassed | Difficulty |
| - | - | - |
| Easy Anti-Cheat (EAC) |  |  |
| BattlEye |  |  |
| Vanguard |  |  |

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

</details>

<details>
<summary>QEMU</summary>

* [Domain XML format](https://libvirt.org/formatdomain.html)

## QEMU + Virt-Manager Setup
```
sudo apt update && sudo apt upgrade
sudo apt install qemu-system-x86 libvirt-clients libvirt-daemon-system libvirt-daemon-config-network bridge-utils virt-manager ovmf
sudo usermod -a -G kvm,libvirt $(whoami)
sudo systemctl enable libvirtd && sudo systemctl start libvirtd && sudo groups $(whoami)
sudo virsh net-autostart default && sudo virsh net-start default
virt-manager
```

## PCIe Passthrough
* [YT Guide #1](https://www.youtube.com/watch?v=g--fe8_kEcw)
* [YT Guide #2](https://www.youtube.com/watch?v=KVDUs019IB8)
* [Article Guide](https://mathiashueber.com/windows-virtual-machine-gpu-passthrough-ubuntu/)
* [Amazing Single GPU Passthrough Guide](https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/home)

First, make sure to enable the following in the host UEFI/BIOS:

| **AMD CPU** | **Intel CPU** |
|-|-|
| IOMMU | VT-D |
| NX | VT-X |
| SVM |  |

* Second, make sure to use UEFI for the firmware!

### Requirements
- Virtualization Check
```bash
LC_ALL=C lscpu | grep Virtualization && egrep -c '(vmx|svm)' /proc/cpuinfo
```
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
- Ubuntu
```bash
sudo update-initramfs -c -k $(uname -r) && sudo reboot now
```
- Arch
```bash
sudo mkinitcpio -p linux && sudo reboot now
```

### Check kernal driver in use for the GPU (should be vfio-pci)
```bash
lspci -k | grep -E "vfio-pci|NVIDIA"
```

### Install Virtio on the guest
- [Virtio](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/)
- If your mouse stops working properly run `virtio-win-gt-x64.msi` and select uninstall, then reboot the guest.

## QEMU Strings Patch
* [qemu-patch-bypass](https://github.com/zhaodice/qemu-anti-detection)

## QEMU RDTSC Kernal Patch
* [RDTSC-KVM-Handler](https://github.com/WCharacter/RDTSC-KVM-Handler)

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

## Spoofed Information
| Feature                           | VirtualBox | VMware  | QEMU   |
|-----------------------------------|------------|---------|--------|
| **CPUID**                         | ✅         | ✅      | ✅    |
| **SMBIOS DMI**                    | ✅         | ✅      | ✅    |
| - BIOS Information                | ✅         | ✅      | ✅    |
| - System Information              | ✅         | ✅      | ✅    |
| - Board Information               | ✅         | ✅      | ✅    |
| - System Enclosure or Chassis     | ✅         | ✅      | ✅    |
| - Processor Information           | ✅         | ✅      | ✅    |
| - OEM Strings                     | ✅         | ✅      | ✅    |
| **MAC Address**                   | ✅         | ✅      | ✅    |
| **Hard Drives**                   | ✅         | ✅      | ✅    |
| **DVD/CD-ROM drives**             | ✅         | ✅      | ✅    |
| **Registry**                      | ✅         | ✅      | ✅    |
| **Device Manager**                | ✅         | ✅      | ✅    |
| **Hardware**                      | ✅         | ✅      | ✅    |
| **Passthrough Capabilities**      | ❌         | ❌      | ✅    |

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
