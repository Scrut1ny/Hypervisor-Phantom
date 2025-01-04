<div align="center">

# 🕵️ Advanced Malware Analysis Tool 🕵️

This tool provides an automated setup solution designed to evade detection from advanced malware, enabling thorough analysis. It employs a highly customized version of QEMU/KVM, EDK2, and the Linux Kernel. This also spoofs many unique hypervisor identifiers, effectively disguising the environment. This setup enhances the accuracy and reliability of malware analysis by minimizing the risk of detection.

</div>

![pic](https://github.com/user-attachments/assets/1329110e-62f9-456b-9816-83975d52a9df)







## What this tool does
- ✅ Automatic distro, bootloader, versions, etc detection
- ✅ Fully automates...
  - [VFIO](https://www.kernel.org/doc/html/latest/driver-api/vfio.html) configuration (PCIe Passthrough)
    - Configures bootloader
    - Regenerates ramdisks
  - Custom patched [QEMU](https://gitlab.com/qemu-project/qemu) install
    - Spoofs all hardcoded serial numbers
  - Custom patched [EDK2/OVMF (UEFI Firmware)](https://github.com/tianocore/edk2) install
  - [Looking Glass](https://looking-glass.io/) setup & install
  - Installation of all virtualization packages required
- ✅ Spoofs SMBIOS
- ✅ Spoofs Serial Numbers
- ✅ RAM
- ✅ Much more...







## 📖 Setup Instruction Guide

<details>
<summary>Expand for details...</summary>

```
# 1. Clone into the repository
git clone --single-branch --depth=1 https://github.com/Scrut1ny/Hypervisor-Phantom

# 2. CD into the repository
cd Hypervisor-Phantom

# 3. Set executable permissions
sudo chmod +x *.sh
```

</details>








## 📝 Documentation & References

<details>
<summary>Expand for details...</summary>

- **Official**
  - [QEMU v9.1.0](https://qemu.readthedocs.io/en/v9.1.0/)
    - [Man Page (command args)](https://qemu.readthedocs.io/en/v9.1.0/system/qemu-manpage.html)
    - [Hyper-V Enlightenments](https://www.qemu.org/docs/master/system/i386/hyperv.html)
  - [KVM for x86 systems (Linux Kernel)](https://www.kernel.org/doc/html/next/virt/kvm/x86/index.html)
  - [Domain XML format](https://libvirt.org/formatdomain.html)
  - [ACPI System Management Bus Interface Specification](https://uefi.org/specs/ACPI/6.5/13_System_Mgmt_Bus_Interface_Specification.html)
  - [System Management BIOS (SMBIOS) Reference Specification](https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf)
- **General**
  - [https://evasions.checkpoint.com/](https://evasions.checkpoint.com/)
  - [https://r0ttenbeef.github.io/](https://r0ttenbeef.github.io/Deploy-Hidden-Virtual-Machine-For-VMProtections-Evasion-And-Dynamic-Analysis/)
  - [https://secret.club/](https://secret.club/)
    - [how-anti-cheats-detect-system-emulation.html](https://secret.club/2020/04/13/how-anti-cheats-detect-system-emulation.html)
    - [battleye-hypervisor-detection.html](https://secret.club/2020/01/12/battleye-hypervisor-detection.html)
- **Reddit Posts**
  - [spoof_and_make_your_vm_undetectable_no_more](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/)
  - [be_is_banning_kvm_on_r6](https://www.reddit.com/r/VFIO/comments/hts1o1/be_is_banning_kvm_on_r6/)
- **Unknowncheats**
  - [418885-kvm-detection-fixes.html](https://www.unknowncheats.me/forum/escape-from-tarkov/418885-kvm-detection-fixes.html) 
- **Git Repos**
  - [pve-patch](https://github.com/Distance10086/pve-patch)
  - [kvm-hidden](https://gitlab.com/DonnerPartyOf1/kvm-hidden)
  - [KVM-Spoofing](https://github.com/A1exxander/KVM-Spoofing)
  - [linux-5.15-hardened-kvm-svm-qemu-win10](https://alt.deliktas.de/git/adeliktas/linux-5.15-hardened-kvm-svm-qemu-win10)
- **VirtualBox**
  - [VirtualBox RDTSC Fix](https://www.reddit.com/r/virtualbox/comments/g6ky8a/disabling_vm_exit_for_rdtsc_access/)
  - [https://forums.virtualbox.org/viewtopic.php?t=78859](https://forums.virtualbox.org/viewtopic.php?t=78859)
  - [https://forums.virtualbox.org/viewtopic.php?t=81600](https://forums.virtualbox.org/viewtopic.php?t=81600)
  - [https://superuser.com/questions/625648/virtualbox-how-to-force-a-specific-cpu-to-the-guest](https://superuser.com/questions/625648/virtualbox-how-to-force-a-specific-cpu-to-the-guest)
  - [https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108](https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108)
  - [https://github.com/d4rksystem/VBoxCloak](https://github.com/d4rksystem/VBoxCloak)
  - [https://github.com/nsmfoo/antivmdetection](https://github.com/nsmfoo/antivmdetection)
- **VMware**
  - [https://sanbarrow.com/vmx.html](https://sanbarrow.com/vmx.html)
  - [https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/](https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/)
  - [https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/](https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/)
  - [https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/](https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/)

</details>






## 💾 Software
<details>
<summary>Expand for details...</summary>

## Hypervisor detection tools

| Software | System Test | Bypassed |
| - | - | - |
| VMAware | [GitHub Repository Link](https://github.com/kernelwernel/VMAware) <> [Download - x64 - v2.0](https://github.com/kernelwernel/VMAware/releases/download/v2.0/vmaware64.exe) <> [Download - x32 - v2.0](https://github.com/kernelwernel/VMAware/releases/download/v2.0/vmaware32.exe) | ❔ |
| Al-Khaser | [GitHub Repository Link](https://github.com/LordNoteworthy/al-khaser) <> [Download - x64 - v1.0.0](https://github.com/ayoubfaouzi/al-khaser/releases/download/v1.0.0/al-khaser_x64.7z) <> [Download - x32 - v1.0.0](https://github.com/ayoubfaouzi/al-khaser/releases/download/v1.0.0/al-khaser_x86.7z) | ❔ |
| Pafish | [GitHub Repository Link](https://github.com/a0rtega/pafish) <> [Download - x64 - v0.6](https://github.com/a0rtega/pafish/releases/download/v0.6/pafish64.exe) <> [Download - x32 - v0.6](https://github.com/a0rtega/pafish/releases/download/v0.6/pafish.exe) | ❔ |

## Exam Software

| Software | Browser Extension | System Test | Bypassed |
|----------|-------------------|-------------|----------|
| ExamSoft: Examplify | ✅ | ??? | ✅ |
| Examity | ✅ | [New Platform System Check](https://on.v5.examity.com/systemcheck) or [Chrome Addon](https://chromewebstore.google.com/detail/geapelpefnpekodnnlkcaadniodlgebj) or [FF Addon](https://addons.mozilla.org/en-US/firefox/addon/examity/) | ✅ |
| Honorlock | ✅ | [Link](https://app.honorlock.com/install/extension) | ✅ |
| Inspera Exam Portal | | [Link](https://ltu.inspera.com/get-iep) - [Demo Exam Instructions](https://www.ltu.se/en/student-web/your-studies/examination/digital-exam-inspera/instructions-for-pc-and-mac-when-downloading-the-inspera-exam-portal) | ✅ |
| Kryterion | | [Link](https://www.kryterion.com/systemcheck/) | ✅ |
| Pearson VUE | | [Link](https://system-test.onvue.com/system_test?customer=pearson_vue) | ✅ |
| ProctorU | ✅ | [FF Addon](https://s3-us-west-2.amazonaws.com/proctoru-assets/extension/firefox-extension-latest.xpi) or [Chrome Addon](https://chrome.google.com/webstore/detail/proctoru/goobgennebinldhonaajgafidboenlkl) | ✅ |
| ProctorU: Guardian Browser | | [Link](https://guardian.meazurelearning.com/) | ✅ |
| Proctorio | ✅ | [Link](https://getproctorio.com/) | ✅ |
| Respondus (LockDown Browser) | ✅ | [Link](https://autolaunch.respondus2.com/MONServer/ldb/preview_launch.do) & [Download](https://download.respondus.com/lockdown/download.php) | ✅ |
| Safe Exam Browser | | [Link](https://github.com/SafeExamBrowser/seb-win-refactoring) | ✅ |

## Anti-Cheat Software

- [areweanticheatyet](https://areweanticheatyet.com/)

| Engine | Used By | Bypassed |
|--------|---------|----------|
| Anti-Cheat Expert (ACE) | Primarily Mobile Games | ✅ |
| BattlEye (BE) | Desktop Games | ✅ (w/Kernal Patch for `R6`) |
| Easy Anti-Cheat (EAC) | Desktop Games | ✅ |
| Gepard Shield | PUBG: Battlegrounds | ✅ |
| Hyperion | Roblox | ✅ |
| Mhyprot | Genshin Impact | ✅ |
| nProtect GameGuard (NP) | Desktop Games | ✅ |
| RICOCHET | CoD Games | ❔ |
| Vanguard | Valorant & LoL | ❌ |

</details>




<details>
<summary>Exam Software Analysis: Reverse Engineering</summary>

## Honorlock

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

## Pearson VUE

- System Requirements
[Link](https://home.pearsonvue.com/Standalone-pages/System-requirements-PVBL.aspx)

- Exam Content & Special Configurations (SDS)
```
https://securedelivery-hs-prd-1.pearsonvue.com/SecureDeliveryService
```

- Application location:
```batch
%APPDATA%\OnVUE\BrowserLock.exe
```

- Log file location:
```batch
%LOCALAPPDATA%\BrowserLock\log
```

- Commands it runs
```powershell
# Obtains NetConnectionID
wmic nic where "NetConnectionStatus = 2" get NetConnectionID /value

# Obtains USB FriendlyName
powershell.exe Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' }

# Obtains Display/Monitor FriendlyName
powershell.exe -Command "Get-WmiObject -Namespace 'root\WMI' -Class 'WMIMonitorID' | ForEach-Object -Process { if($_.UserFriendlyName) { ([System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName)).Replace('$([char]0x0000)','') } }"

# Obtains running processes
powershell.exe /c Get-CimInstance -className win32_process | select Name,ProcessId,ParentProcessId,CommandLine,ExecutablePath

# Obtains MachineGUID
powershell (Get-ItemProperty registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\ -Name MachineGuid).MachineGUID

# Obtains system hostname
C:\Windows\system32\cmd.exe /c hostname
```

- Hypervisor System Checks (in log file):
```
# LOG:
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] VM Allowed flag value from forensics is vmAllowedForensic=false
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Multiple Monitor Allowed flag value from forensics is multiMonitorAllowedForensic=false
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] VPN Allowed flag value from forensics is vpnAllowedForensic=true
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Shutdown file monitor started
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] VM configuration received from SDS will be applied for validation
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] VM detection value is: vmDetectConfig=true
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Multiple monitor configuration received from SDS will be applied for validation
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Multiple monitor detection value is: multipleMonitorDetectConfig=true
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] VPN configuration received from forensics will be applied for validation
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] VPN detection value is: vpnDetectConfig=false
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] USB mass storage detection value is: usbDetectConfig=false
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Minimum browserlock version required: 2304 
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Current browserlock version: 2402.1.1 
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Check if Browserlock running on VM: {DMI type 1 (System Information) - Product Name}, {DMI type 2 (Base Board Information) - Serial Number}, runningOnVM=false
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] VM check: diskSize=499 GB
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Browserlock is not running on virtual machine
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Display HDCP supported check: hdcpSupported=true
XXXX-XX-XX XX:XX:XX.XXX-XXXX [BROWSER LOCK] [INFO] Number of display devices connected: AWT=1, Physical=1, Physical/Virtual=1, Duplicate=1

# BrowserLock Booleon Variables
- hdcpSupported
- multiMonitorAllowedForensic
- multipleMonitorDetectConfig
- runningOnVM
- usbDetectConfig
- vmAllowedForensic
- vmDetectConfig
- vpnAllowedForensic
- vpnDetectConfig
```

![image](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/af144f9c-e69b-4998-8b44-16c876612c25)

## Proctorio

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







## Advanced: Hardware

<details>
<summary>Bypassing HDCP</summary>

## HDCP (High-bandwidth Digital Content Protection)
- [HDCP](https://en.wikipedia.org/wiki/High-bandwidth_Digital_Content_Protection)
- [HDCP: Versions](https://en.wikipedia.org/wiki/High-bandwidth_Digital_Content_Protection#Versions)

## Bypassing HDCP Visual Graph:
![bypass](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/589b0f88-f14b-44d8-bf1c-225df4d01e54)

## Capture Card Format Support:
![image](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/17cfcbe5-0700-440c-af12-3c1dd0157ff1)

## Bypass Kits

#### Elegant Bypass Kit (Recommended):
- 1x2 HDMI Splitter - [ViewHD](https://www.amazon.com/dp/B004F9LVXC) - ~`$21.95`
- EDID Emulator - [4K-EWB - HDMI 2.1 4K EDID Emulator](https://www.amazon.com/dp/B0DB7YDFD6) - ~`$25.00`
- USB HDMI Capture Card - [Elgato HD60 X](https://www.amazon.com/dp/B09V1KJ3J4) - ~`$159.99`

#### Cheap Bypass Kit (Not recommended):
- 1x2 HDMI Splitter <> [OREI](https://www.amazon.com/dp/B005HXFARS) - ~`$13`
- EDID Emulator <> [EVanlak](https://www.amazon.com/dp/B07YMTKJCR) - ~`$7`
- USB HDMI Capture Card <> [AXHDCAP](https://www.amazon.com/dp/B0C2MDTY8P) - ~`$9`

## Equipment List
- Capture Card(s)
    - [Elgato HD60 X](https://www.amazon.com/dp/B09V1KJ3J4) - ~`$159.99`
    - [Elgato Cam Link](https://www.amazon.com/dp/B07K3FN5MR) - ~`$97.99`
    - [AXHDCAP 4K HDMI Video Capture Card](https://www.amazon.com/dp/B0C2MDTY8P) - ~`$9.98`
- 1x2 HDMI Splitter(s)
    - [HBAVLINK](https://www.amazon.com/dp/B08T62MKH1)
    - [CORSAHD](https://www.amazon.com/dp/B0CLL5GQXT)
    - [ViewHD](https://www.amazon.com/dp/B004F9LVXC)
    - [OREI](https://www.amazon.com/dp/B005HXFARS)
    - [EZCOO](https://www.amazon.com/dp/B07VP37KMB)
    - [EZCOO](https://www.amazon.com/dp/B07TZRXKYG)
- EDID Emulator(s)
    - HDMI
        - Brand: THWT
            - [4K-EW2 - HDMI 2.1 4K EDID Emulator PRO](https://www.amazon.com/dp/B0DB65Y6VL) - ~`$90.00`
            - [4K-EWB - HDMI 2.1 4K EDID Emulator](https://www.amazon.com/dp/B0DB7YDFD6) - ~`$25.00`
            - [HD-EW2 - HDMI 2.0 EDID Emulator 4K PRO](https://www.amazon.com/dp/B0C32ZWBR6) - ~`$90.00`
            - [HD-EWB - HDMI 2.0 4K EDID Emulator](https://www.amazon.com/dp/B0CRRWQ7XS) - `$20.00`
    - DP
        - Brand: THWT
            - [DPH-EW2 - Displayport 1.2 EDID Emulator 4K PRO](https://www.amazon.com/dp/B0C32NJ2NF) - ~`$90.00`
    - DP to HDMI
        - Brand: THWT
            - [DPH-EWB - Displayport 1.2 to HDMI 2.0 EDID Emulator](https://www.amazon.com/dp/B0C3H763FG) - ~`$20.00`

</details>
