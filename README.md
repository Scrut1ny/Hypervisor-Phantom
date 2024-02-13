### Set execution policy to be able to run scripts only in the current PowerShell session:
```
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### TODO LIST:
- Bypass RDTSC checks
- Bypass/fix Vbox monitor settings SEB error

### Setup Guide


## Proctor Info
<details>
<summary>Proctoring Software</summary>

| Software | Browser Extension | System Test | Bypassed | Difficulty |
| - | - | - | - | - |
| Pafish |  | [Link](https://github.com/a0rtega/pafish) | ✅ |  |
| Al-Khaser |  | [Link](https://github.com/LordNoteworthy/al-khaser) | ❔ |  |
| Pearson VUE |  | [Link](https://system-test.onvue.com/system_test?customer=pearson_vue) | ❔ | 🤬 |
| ProctorU | ✅ | [FF Addon](https://s3-us-west-2.amazonaws.com/proctoru-assets/extension/firefox-extension-latest.xpi) or [Chrome Addon](https://chrome.google.com/webstore/detail/proctoru/goobgennebinldhonaajgafidboenlkl) | ✅ |  |
| ProctorU: Guardian Browser |  | [Link](https://guardian.meazurelearning.com/) | ❔ |  |
| Proctorio | ✅ | [Link](https://getproctorio.com/) | ✅ |  |
| Examity |  |  | ❔ |  |
| Respondus (LockDown Browser) | ✅ | [Link](https://download.respondus.com/lockdown/download.php) | ❔ |  |
| Kryterion |  |  | ❔ |  |
| Honorlock | ✅ | [Link](https://app.honorlock.com/install/extension) | ✅ | 😀 |

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
    
  - General
      - Advanced
          - Shared Clipboard: Bidirectional
          - Drag'n'Drop: Bidirectional
  - System
      - Processor
          - ✅ Enable PAE/NX
          - ✅ Enable Nested VT-x/AMD-V
      - Acceleration
          - Paravirtualization Interface: Legacy
          - Hardware Virtualization: ✅
  - Network
      - Adapter 1
          - ✅ Enable Network Adapter
          - Attach to: `Bridged Adapter`
          - MAC Address: Randomize fully!
  </details>

  <details>
  <summary>VMware</summary>
  
  ## 1st Step: Add following settings into .vmx
  
  ```
  hypervisor.cpuid.v0 = "FALSE"
  board-id.reflectHost = "TRUE"
  hw.model.reflectHost = "TRUE"
  serialNumber.reflectHost = "TRUE"
  SMBIOS.reflectHost = "TRUE"
  SMBIOS.noOEMStrings = "TRUE"
  SMBIOS.addHostVendor = "TRUE"
  isolation.tools.getPtrLocation.disable = "TRUE"
  isolation.tools.setPtrLocation.disable = "TRUE"
  isolation.tools.setVersion.disable = "TRUE"
  isolation.tools.getVersion.disable = "TRUE"
  monitor_control.disable_directexec = "TRUE"
  monitor_control.disable_chksimd = "TRUE"
  monitor_control.disable_ntreloc = "TRUE"
  monitor_control.disable_selfmod = "TRUE"
  monitor_control.disable_reloc = "TRUE"
  monitor_control.disable_btinout = "TRUE"
  monitor_control.disable_btmemspace = "TRUE"
  monitor_control.disable_btpriv = "TRUE"
  monitor_control.disable_btseg = "TRUE"
  monitor_control.restrict_backdoor = "TRUE"
  ```
  
  If you have a SCSI virtual disk at scsi0 slot (first slot) as your system drive, remember to add
  
  ```
  scsi0:0.productID = "Whatever you want"
  scsi0:0.vendorID = "Whatever you want"
  ```
  
  I use
  ```
  scsi0:0.productID = "Tencent SSD"
  scsi0:0.vendorID = "Tencent"
  ```
  
  ## 2nd Step: Modify MAC address
  
  Modify guest's MAC address to whatever except below:
  ```
  	TCHAR *szMac[][2] = {
  		{ _T("\x00\x05\x69"), _T("00:05:69") }, // VMWare, Inc.
  		{ _T("\x00\x0C\x29"), _T("00:0c:29") }, // VMWare, Inc.
  		{ _T("\x00\x1C\x14"), _T("00:1C:14") }, // VMWare, Inc.
  		{ _T("\x00\x50\x56"), _T("00:50:56") },	// VMWare, Inc.
  	};
  ```
  
  ![mac](https://github.com/hzqst/VmwareHardenedLoader/raw/master/img/4.png)
  
  You could add
  
  ```
  ethernet0.address = "Some random mac address"
  ```
  Into vmx file instead of modifying MAC address in VMware GUI
  
  I use
  
  ```
  ethernet0.address = "00:11:56:20:D2:E8"
  ```

  </details>

  <details>
  <summary>QEMU/KVM</summary>
    - [QEMU Setup Guide](https://christitus.com/vm-setup-in-linux/)
    
  </details>
  
</details>



### Important Tips:
* To bypass certain Anti-Cheats and Proctoring software you must take different approaches, some are extreme and some are simple.
* Don't use NAT: The Host and VM Machine cannot have the same IPv4 LAN address. That is a clear indicator a VM is being utilized, because network traffic from the same IPv4 LAN Address is being generated from the host.
* Use DNS-over-HTTPS (DoH) because it's encrypted. Using a unencrypted DNS means the websites you visit are visible to all, but with DoH the most you can obtain is a external IP address.
* Use a Virtual Private Network (VPN) to mask all traffic. Remember popular VPNs won't work with some proctoring or Anti-Cheat software, because the VPNs IP ranges might be blacklisted.
* Make sure the VM is 128GB+ in size, any less will be flagged/detected.

### VMware PRO License Key:
```
MC60H-DWHD5-H80U9-6V85M-8280D
```

### QEMU:
* [QEMU](https://qemu.weilnetz.de/w64/)
* [QtEmu](https://sourceforge.net/projects/qtemu/)
* [qemu-patch-bypass](https://github.com/zhaodice/qemu-anti-detection)

### Virtual Box - VBoxManage Tool Location:
```
Linux: /usr/bin/VBoxManage
Mac OS X: /Applications/VirtualBox.app/Contents/MacOS/VBoxManage
Oracle Solaris: /opt/VirtualBox/bin/VBoxManage
Windows: C:\Program Files\Oracle\VirtualBox\VBoxManage.exe
```

### Spoofed Information
- CPUID
- DMI
  - BIOS Information
  - System Information
  - Board Information
  - System Enclosure or Chassis
  - Processor Information
  - OEM Strings
- MAC Address
- Disk drives
- DVD/CD-ROM drives
- Registry
- Device Manager
- Hardware

### Spoofing Software
- [Read & Write Everything](http://rweverything.com/download/)

### References & Help
- [https://evasions.checkpoint.com/](https://evasions.checkpoint.com/)
- [https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/](https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/)
- [https://forums.virtualbox.org/viewtopic.php?t=78859](https://forums.virtualbox.org/viewtopic.php?t=78859)
- [https://github.com/nxvvvv/safe-exam-browser-bypass](https://github.com/nxvvvv/safe-exam-browser-bypass)
- [https://forums.virtualbox.org/viewtopic.php?t=81600](https://forums.virtualbox.org/viewtopic.php?t=81600)
- [https://bannedit.github.io/Virtual-Machine-Detection-In-The-Browser.html](https://bannedit.github.io/Virtual-Machine-Detection-In-The-Browser.html)
- [https://superuser.com/questions/625648/virtualbox-how-to-force-a-specific-cpu-to-the-guest](https://superuser.com/questions/625648/virtualbox-how-to-force-a-specific-cpu-to-the-guest)
- [https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/](https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/)
- [https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108](https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108)
- [https://github.com/d4rksystem/VBoxCloak](https://github.com/d4rksystem/VBoxCloak)
- [https://github.com/nsmfoo/antivmdetection](https://github.com/nsmfoo/antivmdetection)
- [https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/](https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/)
- [https://www.unknowncheats.me/forum/escape-from-tarkov/418885-kvm-detection-fixes.html](https://www.unknowncheats.me/forum/escape-from-tarkov/418885-kvm-detection-fixes.html)
