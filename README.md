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
<summary>VM Setup Guide</summary>
<details>
<summary>Oracle VM VirtualBox</summary>

### Virtual Box - VBoxManage Tool Location:
```
Linux: /usr/bin/VBoxManage
Mac OS X: /Applications/VirtualBox.app/Contents/MacOS/VBoxManage
Oracle Solaris: /opt/VirtualBox/bin/VBoxManage
Windows: C:\Program Files\Oracle\VirtualBox\VBoxManage.exe
```

### Run these scripts:
* Configure the VM: `VM-External-Modifer.ps1`
* Spoof the VM: `VM-Internal-Modifier.ps1`

</details>

<details>
<summary>VMware</summary>

### VMware PRO License Key:
```
MC60H-DWHD5-H80U9-6V85M-8280D
```
  
### Add the following into your *.vmx

```
hypervisor.cpuid.v0 = "FALSE"
smbios.reflectHost = "TRUE"
ethernet0.address = "00:C0:CA:A7:2B:9E"
scsi0:0.productID = "Samsung 980 PRO SSD"
scsi0:0.vendorID = "Samsung"
monitor_control.virtual_rdtsc = "FALSE"
monitor_control.restrict_backdoor = "TRUE"
isolation.tools.getPtrLocation.disable = "TRUE"
isolation.tools.setPtrLocation.disable = "TRUE"
isolation.tools.setVersion.disable = "TRUE"
isolation.tools.getVersion.disable = "TRUE"
monitor_control.disable_directexec = "TRUE"
```

### **IMPORTANT**
* `smbios.reflectHost` will NOT function properly if UEFI is utilized instead of BIOS firmware!

</details>

<details>
<summary>QEMU/KVM</summary>
      
### QEMU + Virt-Manager Setup
   
```
sudo apt update && sudo apt upgrade
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
sudo adduser $USER libvirt && sudo adduser $USER kvm
sudo systemctl status libvirtd
sudo systemctl start libvirtd && sudo systemctl enable libvirtd
virt-manager
```

### QEMU libvert: Domain XML format
* [Domain XML format](https://libvirt.org/formatdomain.html)

### QEMU Strings Patch
* [qemu-patch-bypass](https://github.com/zhaodice/qemu-anti-detection)

### QEMU RDTSC Kernal Patch

### PCIe Passthrough
* [GPU Pass-through On Linux/Virt-Manager](https://www.youtube.com/watch?v=KVDUs019IB8)
* First Make sure `Intel vt-d` or `amd-vi` and `IOMMU` are enabled in the UEFI/BIOS.
      
```
# Check if your system has virtualization enabled
LC_ALL=C lscpu | grep Virtualization
egrep -c '(vmx|svm)' /proc/cpuinfo

Add "amd_iommu=on" or "intel_iommu=on" to line "GRUB_CMDLINE_LINUX_DEFAULT"
sudo vim /etc/default/grub

sudo grub-mkconfig -o /boot/grub/grub.cfg

Search all installed PCI devices (look for VGA):
lspci -nn | grep "VGA"

sudo vim /etc/modprobe.d/vfio.conf

sudo mkinitcpio -p linux
```

</details>
</details>

<details>
<summary>Important Tips</summary>
    
* **Avoid NAT Similarities**: Ensure your host and VM have distinct IPv4 addresses within the LAN to prevent obvious signs of VM activity, as identical addresses could signal VM use.
* **Encrypt DNS Queries**: Utilize DNS-over-HTTPS (DoH) to encrypt your DNS queries. Unlike unencrypted DNS, DoH conceals the websites you visit, leaving only the external IP address visible to observers.
* **Opt for a VPN**: Use a VPN to obscure all your internet traffic. However, be cautious with popular VPN services as their IP ranges may be blacklisted by certain proctoring or anti-cheat systems.
* **Allocate Sufficient VM Storage**: Equip your VM with at least 128GB of storage. VMs with lower storage capacities may be more easily identified or flagged by monitoring systems.

</details>

## Spoofed Information
| Feature                           | VirtualBox | VMware  | QEMU  |
|-----------------------------------|------------|---------|-------|
| **CPUID**                         | ✅          | ✅      | ✅    |
| **SMBIOS DMI**                    | ✅          | ✅      | ✅    |
| - BIOS Information                | ✅          | ✅      | ✅    |
| - System Information              | ✅          | ✅      | ✅    |
| - Board Information               | ✅          | ✅      | ✅    |
| - System Enclosure or Chassis     | ✅          | ✅      | ✅    |
| - Processor Information           | ✅          | ✅      | ✅    |
| - OEM Strings                     | ✅          | ✅      | ✅    |
| **MAC Address**                   | ✅          | ✅      | ✅    |
| **Hard Drives**                   | ✅          | ✅      | ✅    |
| **DVD/CD-ROM drives**             | ✅          | ✅      | ✅    |
| **Registry**                      | ✅          | ✅      | ✅    |
| **Device Manager**                | ✅          | ✅      | ✅    |
| **Hardware**                      | ✅          | ✅      | ✅    |
| **Monitor/Display (Passthrough)** | ❌          | ❌      | ✅    |
| **GPU (Passthrough)**             | ❌          | ❌      | ✅    |

## Software
* [Read & Write Everything](http://rweverything.com/download/)

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
<summary>QEMU/KVM</summary>

* [Spoof and make your VM Undetectable - No more bullsh*t bans](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/)
* [BE is banning KVM on R6](https://www.reddit.com/r/VFIO/comments/hts1o1/be_is_banning_kvm_on_r6/)
* [KVM Detection fixes](https://www.unknowncheats.me/forum/escape-from-tarkov/418885-kvm-detection-fixes.html)

</details>
