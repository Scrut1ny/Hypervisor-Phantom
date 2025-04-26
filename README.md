<div align="center">

# 🕵️ Advanced Malware Analysis Tool 🕵️

This tool provides an automated setup solution designed to evade detection from advanced malware, enabling thorough analysis. It employs a highly customized version of QEMU/KVM, EDK2, and the Linux Kernel. This also spoofs many unique hypervisor identifiers, effectively disguising the environment. This setup enhances the accuracy and reliability of malware analysis by minimizing the risk of detection.

[![](https://dcbadge.limes.pink/api/server/https://discord.gg/kW8ZtQy6xU)](https://discord.gg/kW8ZtQy6xU)

</div>

![pic](https://github.com/user-attachments/assets/1329110e-62f9-456b-9816-83975d52a9df)







## What this tool does
- **🔍 Automatic Detection**
  - Detects distro, bootloader, and versions automatically

- **🤖 Full Automation**
  - **[VFIO Configuration](https://www.kernel.org/doc/html/latest/driver-api/vfio.html) (PCIe Passthrough)**
    - Configures bootloader
    - Regenerates ramdisks
  - **Custom Patched [QEMU](https://gitlab.com/qemu-project/qemu) Installation**
    - Spoofs all hardcoded serial numbers
  - **Custom Patched [EDK2/OVMF (UEFI Firmware)](https://github.com/tianocore/edk2) Installation**
  - **[Looking Glass](https://looking-glass.io/) Setup & Installation**
  - Installs all necessary virtualization packages

- **🛡️ Spoofing Capabilities**
  - SMBIOS Spoofing (via XML)
    - Serial Numbers, UUID, RAM, etc.







## 📖 Setup Instruction Guide

<details>
<summary>Expand for details...</summary>

```
# 1. Clone into the repository
git clone --single-branch --depth=1 https://github.com/Scrut1ny/Hypervisor-Phantom

# 2. CD into the repository
cd Hypervisor-Phantom/Hypervisor-Phantom/

# 3. Set executable permissions
chmod -R +x *

# 4. Run the script
./Auto-Hypervisor.sh
```

</details>








## 📝 Documentation & References

<details>
<summary>Expand for details...</summary>

- **Official**
  - [QEMU’s documentation](https://www.qemu.org/docs/master/)
    - [Man Page (Args)](https://www.qemu.org/docs/master/system/qemu-manpage.html)
    - [Hyper-V Enlightenments](https://www.qemu.org/docs/master/system/i386/hyperv.html)
  - [KVM for x86 systems (Linux Kernel)](https://www.kernel.org/doc/html/next/virt/kvm/x86/index.html)
  - [Domain XML format](https://libvirt.org/formatdomain.html)
  - [ACPI System Management Bus Interface Specification](https://uefi.org/specs/ACPI/6.5/13_System_Mgmt_Bus_Interface_Specification.html)
  - [System Management BIOS (SMBIOS) Reference Specification](https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.2.0.pdf)
  - [PCILookup](https://www.pcilookup.com/)
- **General**
  - [https://evasions.checkpoint.com/](https://evasions.checkpoint.com/)
  - [https://r0ttenbeef.github.io/](https://r0ttenbeef.github.io/Deploy-Hidden-Virtual-Machine-For-VMProtections-Evasion-And-Dynamic-Analysis/)
  - [https://secret.club/](https://secret.club/)
    - [how-anti-cheats-detect-system-emulation.html](https://secret.club/2020/04/13/how-anti-cheats-detect-system-emulation.html)
    - [battleye-hypervisor-detection.html](https://secret.club/2020/01/12/battleye-hypervisor-detection.html)
- **Reddit**
  - [spoof_and_make_your_vm_undetectable_no_more](https://www.reddit.com/r/VFIO/comments/i071qx/spoof_and_make_your_vm_undetectable_no_more/)
  - [be_is_banning_kvm_on_r6](https://www.reddit.com/r/VFIO/comments/hts1o1/be_is_banning_kvm_on_r6/)
- **Unknowncheats**
  - [418885-kvm-detection-fixes.html](https://www.unknowncheats.me/forum/escape-from-tarkov/418885-kvm-detection-fixes.html) 
- **Git Repos**
  - [pve-patch](https://github.com/Distance10086/pve-patch)
  - [pve-anti-detection](https://github.com/lixiaoliu666/pve-anti-detection)
  - [proxmox-ve-anti-detection](https://github.com/zhaodice/proxmox-ve-anti-detection)
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
  - [https://sammwy.com/blog/hide-vm-from-detection](https://sammwy.com/blog/hide-vm-from-detection)
  - [https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/](https://www.hexacorn.com/blog/2014/08/25/protecting-vmware-from-cpuid-hypervisor-detection/)
  - [https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/](https://rayanfam.com/topics/defeating-malware-anti-vm-techniques-cpuid-based-instructions/)
  - [https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/](https://tulach.cc/bypassing-vmprotect-themida-vm-checks-in-vmware/)

</details>







## 💡 Important/Useful Tips

<details>
<summary>Expand for details...</summary>

- **Opt for a VPN**: Use a VPN to obscure all your internet traffic. However, be cautious with popular VPN services as their IP ranges may be blacklisted by certain exam proctoring or anti-cheat systems.
- **Allocate Sufficient HV Storage**: Equip your hypervisor with at least `128GB+` of storage. Hypervisors with lower or insufficient storage are more susceptible to being identified or flagged by detection and monitoring systems.
- **System Up Time**: Leave the hypervisor running for at least `12+` minutes to bypass a `GetTickCount()` check in a hypervisor detection tool. (This check is honestly pointless, and isn't reliable to rely on.)

</details>








## 💾 Software
<details>
<summary>HV Detection, Anti-Cheat and Exam Software</summary>

## Hypervisor Detection Software

| Rating | Software | System Test | Bypassed |
| - | - | - | - |
| 🥇 | VMAware | [Repo Link](https://github.com/kernelwernel/VMAware) <> [Download - x64 - v2.3.0](https://github.com/kernelwernel/VMAware/releases/download/v2.3.0/vmaware.exe) <> [Download - x32 - v2.3.0](https://github.com/kernelwernel/VMAware/releases/download/v2.3.0/vmaware32.exe) | ✅ |
| 🥈 | Al-Khaser (Obsolete) | [Repo Link](https://github.com/LordNoteworthy/al-khaser) <> [Download - x64 - v1.0.0](https://github.com/ayoubfaouzi/al-khaser/releases/download/v1.0.0/al-khaser_x64.7z) <> [Download - x32 - v1.0.0](https://github.com/ayoubfaouzi/al-khaser/releases/download/v1.0.0/al-khaser_x86.7z) | ✅ |
| 🥉 | Pafish (Obsolete) | [Repo Link](https://github.com/a0rtega/pafish) <> [Download - x64 - v0.6](https://github.com/a0rtega/pafish/releases/download/v0.6/pafish64.exe) <> [Download - x32 - v0.6](https://github.com/a0rtega/pafish/releases/download/v0.6/pafish.exe) | ✅ |

## Exam Software

| Software | Browser Extension | System Test | Download | Bypassed |
|:--------:|:-----------------:|:-----------:|:--------:|:--------:|
| Bluebook |  |  | [>> ⬇️ <<](https://bluebook.app.collegeboard.org/) | ✅ |
| ExamSoft: Examplify | ✅ |  |  | ✅ |
| Examity | ✅ | [New Platform System Check](https://on.v5.examity.com/systemcheck) or [Chrome Addon](https://chromewebstore.google.com/detail/geapelpefnpekodnnlkcaadniodlgebj) or [FF Addon](https://addons.mozilla.org/en-US/firefox/addon/examity/) |  | ✅ |
| Honorlock | ✅ | [Link](https://app.honorlock.com/install/extension) |  | ✅ |
| Inspera Exam Portal | | [Link](https://ltu.inspera.com/get-iep) - [Demo Exam Instructions](https://www.ltu.se/en/student-web/your-studies/examination/digital-exam-inspera/instructions-for-pc-and-mac-when-downloading-the-inspera-exam-portal) |  | ✅ |
| Kryterion | | [Link](https://www.kryterion.com/systemcheck/) | [>> ⬇️ <<](https://media.webassessor.com/respondus/windows/labedition/Respondus_LockDown_Browser_Lab_OEM.msi) | ✅ |
| Pearson VUE | | [Link](https://system-test.onvue.com/system_test?customer=pearson_vue) |  | ✅ |
| ProctorU | ✅ |  | [⬇️ Firefox](https://s3-us-west-2.amazonaws.com/proctoru-assets/extension/firefox-extension-latest.xpi) or [⬇️ Chrome](https://chrome.google.com/webstore/detail/proctoru/goobgennebinldhonaajgafidboenlkl) | ✅ |
| ProctorU: Guardian Browser | | [Link](https://go.proctoru.com/testitout) | [⬇️](https://production-archimedes-secure-browser-artifacts.s3.amazonaws.com/latest/windows/guardian-browser-x64.exe) [Website #1](https://guardian.meazurelearning.com/) [Website #2](https://go.proctoru.com/testitout) | ✅ |
| Proctorio | ✅ | [Link](https://getproctorio.com/) |  | ✅ |
| Respondus (LockDown Browser) | ✅ | [Link](https://autolaunch.respondus2.com/MONServer/ldb/preview_launch.do) | [⬇️](https://download.respondus.com/lockdown/download.php) | ✅ |
| Safe Exam Browser | | [Link](https://github.com/SafeExamBrowser/seb-win-refactoring) | [⬇️](https://github.com/SafeExamBrowser/seb-win-refactoring/releases/download/v3.9.0/SEB_3.9.0.787_x64_Setup.msi) | ✅ |

## Anti-Cheat Software

- [areweanticheatyet](https://areweanticheatyet.com/)

| Engine | Used By | Bypassed |
|--------|---------|----------|
| Anti-Cheat Expert (ACE) | Primarily Mobile Games | ✅ |
| BattlEye (BE) | Desktop Games | ✅ (w/Kernal Patch for `R6, Destiny 2, etc...`) |
| Easy Anti-Cheat (EAC) | Desktop Games | ✅ |
| Gepard Shield | PUBG: Battlegrounds | ✅ |
| NACE (Netease Anticheat Expert) | Marvel Rivals | ❔ |
| Hyperion | Roblox | ✅ |
| Mhyprot | Genshin Impact | ✅ |
| nProtect GameGuard (NP) | Desktop Games | ✅ |
| RICOCHET | CoD Games | ❔ |
| Vanguard | Valorant & LoL | ❌ |

</details>




<details>
<summary>Exam Software Analysis: Reverse Engineering</summary>

#### Tools Recommended
- Websites
    - [Decompiler Explorer](https://dogbolt.org/)
    - [SQLite Viewer Web App](https://sqliteviewer.app/)
- Software
    - [Process Informer](https://github.com/winsiderss/systeminformer)
    - [PE-Bear (Lightweight PE Analyzer)](https://github.com/hasherezade/pe-bear)
    - [Detect It Easy (DIE)](https://github.com/horsicq/DIE-engine)
    - [Ghidra (Advanced Reverse Engineering)](https://github.com/NationalSecurityAgency/ghidra)
    - [x64dbg (Dynamic Debugging)](https://github.com/x64dbg/x64dbg)

---

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

---

## Pearson VUE

- [Sameple Exam/System Test](https://vueop.startpractice.com/)
- [System Requirements](https://home.pearsonvue.com/Standalone-pages/System-requirements-PVBL.aspx)

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

---

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






<details>
<summary>Virtual Video & Audio</summary>

## Bring live video from your smartphone, remote computer, or friends directly into OBS or other studio software.
- [VDO.Ninja](https://vdo.ninja/)
- [meshcast.io](https://meshcast.io/)

## VB-CABLE Virtual Audio Device
- [VB-AUDIO Software](https://vb-audio.com/Cable/index.htm)
    - [Windows Download](https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip)
    - [macOS Download](https://download.vb-audio.com/Download_MAC/VBCable_MACDriver_Pack108.zip)

## Virtual Display Driver
- [Virtual-Display-Driver](https://github.com/itsmikethetech/Virtual-Display-Driver)

## Webcam Manipulation
- [Deep-Live-Cam](https://github.com/hacksider/Deep-Live-Cam)

</details>








<details>
<summary>VPN + Hypervisor</summary>

- ***IMPORTANT***: Ensure not to add a custom DNS configuration to the guest system on the hypervisor if your host system's VPN uses custom DNS block lists. Doing so may result in your guest hypervisor system losing its internet connection!

## Mullvad VPN + QEMU
- For the VPN connection to get properly natted/bridged you must enable the setting `Local network sharing` option!
    - How to: `⚙️` > `VPN settings` > `Local network sharing` ✅

![image](https://github.com/user-attachments/assets/18ba68b4-31ea-4c5e-9ad1-66417001820f)
![image](https://github.com/user-attachments/assets/36465501-13fa-469b-bb66-f3db6003a64e)
![image](https://github.com/user-attachments/assets/77890671-d024-491a-8d33-cb38e3503ef4)
![image](https://github.com/user-attachments/assets/126e06bd-23c0-4cb9-9bfe-5a55fe6689ab)

</details>







<details>
<summary>Recommended Tools</summary>

- OCR Powered Screen-Capture Tools
    - Linux:
        - [NormCap](https://github.com/dynobo/normcap)
        - [TextSnatcher](https://github.com/RajSolai/TextSnatcher)
    - Windows:
        - [ShareX](https://github.com/ShareX/ShareX)
- RAT (Remote Access/Administration Trojan)
    - [Quasar](https://github.com/quasar/Quasar)
        - [Resource Hacker](https://www.angusj.com/resourcehacker/)
- RDP (Remote Desktop Protocal)
    - [Ammyy Admin](https://www.ammyy.com/)
    - [MeshCentral](https://github.com/Ylianst/MeshCentral)
- Monitor EDID Modifiers
    - [Monitor Asset Manager](https://www.entechtaiwan.com/util/moninfo.shtm)
        - [Dell Article](https://www.dell.com/support/kbdoc/en-us/000156229/using-monitor-asset-manager-version-2-6-to-read-extended-display-identification-data-edid-information)
        - [Using an INF file to override EDIDs](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/overriding-monitor-edids)
    - [Custom Resolution Utility (CRU)](https://www.monitortests.com/forum/Thread-Custom-Resolution-Utility-CRU)
- UEFI/BIOS Editors
    - [Phoenix BIOS Editor](https://theretroweb.com/drivers/208)
    - [UEFITool](https://github.com/LongSoft/UEFITool)

</details>







## 🔩 Hardware

<details>
<summary>Bypassing HDCP</summary>

#### HDCP (High-bandwidth Digital Content Protection)
- [HDCP](https://en.wikipedia.org/wiki/High-bandwidth_Digital_Content_Protection)
- [HDCP: Versions](https://en.wikipedia.org/wiki/High-bandwidth_Digital_Content_Protection#Versions)

## Bypassing HDCP Hardware/Software Diagram:
![bypass](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/589b0f88-f14b-44d8-bf1c-225df4d01e54)

## Bypass Kits

#### Expensive Bypass Kit (Recommended):
- 1x2 HDMI Splitter <> [ViewHD](https://www.amazon.com/dp/B004F9LVXC) - `~$21.95`
- EDID Emulator <> [4K-EWB - HDMI 2.1 4K EDID Emulator](https://www.amazon.com/dp/B0DB7YDFD6) - `~$25.00`
- USB HDMI Capture Card <> [Elgato HD60 X](https://www.amazon.com/dp/B09V1KJ3J4) - `~$159.99`

#### Cheap Bypass Kit (Not recommended):
- 1x2 HDMI Splitter <> [OREI](https://www.amazon.com/dp/B005HXFARS) - `~$13`
- EDID Emulator <> [EVanlak](https://www.amazon.com/dp/B07YMTKJCR) - `~$7`
- USB HDMI Capture Card <> [AXHDCAP](https://www.amazon.com/dp/B0C2MDTY8P) - `~$9`

## Equipment List
- Capture Card(s)
    - [Elgato HD60 X](https://www.amazon.com/dp/B09V1KJ3J4) - `~$159.99`
    - [Elgato Cam Link](https://www.amazon.com/dp/B07K3FN5MR) - `~$97.99`
    - [AXHDCAP 4K HDMI Video Capture Card](https://www.amazon.com/dp/B0C2MDTY8P) - `~$9.98`
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
            - [4K-EW2 - HDMI 2.1 4K EDID Emulator PRO](https://www.amazon.com/dp/B0DB65Y6VL) - `~$90.00`
            - [4K-EWB - HDMI 2.1 4K EDID Emulator](https://www.amazon.com/dp/B0DB7YDFD6) - `~$25.00`
            - [HD-EW2 - HDMI 2.0 EDID Emulator 4K PRO](https://www.amazon.com/dp/B0C32ZWBR6) - `~$90.00`
            - [HD-EWB - HDMI 2.0 4K EDID Emulator](https://www.amazon.com/dp/B0CRRWQ7XS) - `~$20.00`
    - DP
        - Brand: THWT
            - [DPH-EW2 - Displayport 1.2 EDID Emulator 4K PRO](https://www.amazon.com/dp/B0C32NJ2NF) - `~$90.00`
    - DP to HDMI
        - Brand: THWT
            - [DPH-EWB - Displayport 1.2 to HDMI 2.0 EDID Emulator](https://www.amazon.com/dp/B0C3H763FG) - `~$20.00`

</details>







<details>
<summary>Elgato Capture Cards</summary>

- Some of Elgato's capture cards, leveraging UVC (USB Video Class) technology, operate seamlessly without requiring additional drivers. As UVC devices, they adhere to a standard protocol for transmitting video and audio data over USB connections. This plug-and-play functionality ensures compatibility with various operating systems, enabling effortless setup and use for capturing high-quality video content.

## UVC Elgato Capture Cards

- [Article](https://help.elgato.com/hc/en-us/articles/360027961152-Elgato-Gaming-Hardware-Drivers)

| Device                      | Driver Status                     |
|-----------------------------|-----------------------------------|
| Elgato Cam Link             | No driver since it's a UVC device |
| Elgato Cam Link 4K          | No driver since it's a UVC device |
| Elgato Game Capture HD60 S+ | No driver since it's a UVC device |
| Elgato Game Capture HD60 X  | No driver since it's a UVC device |
| Game Capture 4K X           | No driver since it's a UVC device |
| Game Capture Neo            | No driver since it's a UVC device |

## Linux - OBS Black Screen Issue Solution

##### Step 1:
Download and Install the latest `4K CAPTURE UTILITY` software from [Elgato downloads page](https://www.elgato.com/us/en/s/downloads) on a `WINDOWS OS`.

#### Step 2:
Open `Elgato 4K Capture Utility` and let the software initialize the UVC capture card.

#### Step 3:
Select the settings icon on the top right corner of the software utility, and select `Check for Updates...`. (It should update automatically already, but just make sure the firmware is on the latest version available.)

#### Step 4:
Now, connect the capture card device back to your Linux host system now and open OBS, you should now see an output from your GPU instead of a black screen.

</details>









---

> **⚠️ Legal Disclaimer**  
> By using this tool, you agree to the following:
> 
> - This tool is intended **only for educational, research, and security analysis** purposes.
> - **The author is not liable** for any damages, legal consequences, or misuse arising from your use of this tool.
> - You are responsible for ensuring your use complies with all applicable laws. 
> - Misuse, including cheating or illegal activities, is strictly prohibited.
> 
> Use at your own risk. The tool is provided "as-is" without any warranties.

---








## Star History

<a href="https://star-history.com/#Scrut1ny/Hypervisor-Phantom&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Scrut1ny/Hypervisor-Phantom&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Scrut1ny/Hypervisor-Phantom&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Scrut1ny/Hypervisor-Phantom&type=Date" />
 </picture>
</a>
