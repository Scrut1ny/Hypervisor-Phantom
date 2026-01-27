## 🛠️ Common Troubleshooting

<details>
<summary>Expand for details...</summary>

- Windows 11 BSOD - USBXHCI.sys
  - Switch from USB3 to USB2 in VMM/XML

- Windows 10/11 w/Secure Boot BSOD after 5-30 mins from boot
  - Increase pagefile size inside Windows

- Dumping host's SMBIOS for QEMU passthrough
  - First try:
  ```
  sudo cat /sys/firmware/dmi/tables/{smbios_entry_point,DMI} > smbios.bin
  ```
  - Then try (if QEMU doesn't accept):
  ```
  sudo cat /sys/firmware/dmi/tables/DMI > smbios.bin
  ```

- Fix Ryzen 7000/9000 iGPUs "No Signal/Black Screen/flickering" when attempting to display the DM
Add the arg below to your kernel options config:
```
amdgpu.sg_display=0
```
- https://www.kernel.org/doc/html/latest/gpu/amdgpu/module-parameters.html
  - sg_display (int)
    - Disable S/G (scatter/gather) display (i.e., display from system memory). This option is only relevant on APUs. Set this option to 0 to disable S/G display if you experience flickering or other issues under memory pressure and report the issue.

</details>





---





## 📝 Documentation & References

<details>
<summary>Expand for details...</summary>

- **Official**
  - [QEMU’s documentation](https://www.qemu.org/docs/master/)
    - [Man Page (Args)](https://www.qemu.org/docs/master/system/qemu-manpage.html)
    - [Hyper-V Enlightenments](https://www.qemu.org/docs/master/system/i386/hyperv.html)
  - [KVM for x86 systems (Linux Kernel)](https://www.kernel.org/doc/html/next/virt/kvm/x86/index.html)
  - [Domain XML format](https://libvirt.org/formatdomain.html)
  - [ACPI System Management Bus Interface Specification - HTML](https://uefi.org/specs/ACPI/6.6/13_System_Mgmt_Bus_Interface_Specification.html) - [PDF Version](https://uefi.org/sites/default/files/resources/ACPI_Spec_6.6.pdf)
  - [SMBIOS Reference Specification - PDF](https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_3.9.0.pdf)
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
  - [sGPUpt](https://github.com/MaxxRK/sGPUpt)
  - [gpupt](https://github.com/pragmagrid/gpupt)

</details>





---





## 💾 Software
<details>
<summary>Software Assessments</summary>

## Hypervisor Analysis

| ⭐ Rating | 💻 Software | 🧪 System Test | ✅ Bypassed |
|:------:|:--------:|:-----------:|:--------:|
| 🥇 | VMAware | [Repository Link](https://github.com/kernelwernel/VMAware) <br> [⬇ Download - x64 - v2.6.0 ⬇](https://github.com/kernelwernel/VMAware/releases/download/v2.6.0/vmaware_2.6.0.exe) <br> [⬇ Download - x32 - v2.6.0 ⬇](https://github.com/kernelwernel/VMAware/releases/download/v2.6.0/vmaware32_2.6.0.exe) <br> [⬇ Download - DEBUG - v2.6.0 ⬇](https://github.com/kernelwernel/VMAware/releases/download/v2.6.0/vmaware_debug_2.6.0.exe) | ❌ |
| 🥈 | Al-Khaser (Obsolete) | [Repository Link](https://github.com/LordNoteworthy/al-khaser) <br> [⬇ Download - x64 - v1.0.0 ⬇](https://github.com/ayoubfaouzi/al-khaser/releases/download/v1.0.0/al-khaser_x64.7z) <br> [⬇ Download - x32 - v1.0.0 ⬇](https://github.com/ayoubfaouzi/al-khaser/releases/download/v1.0.0/al-khaser_x86.7z) | ✅ |
| 🥉 | Pafish (Obsolete) | [Repository Link](https://github.com/a0rtega/pafish) <br> [⬇ Download - x64 - v0.6 ⬇](https://github.com/a0rtega/pafish/releases/download/v0.6/pafish64.exe) <br> [⬇ Download - x32 - v0.6 ⬇](https://github.com/a0rtega/pafish/releases/download/v0.6/pafish.exe) | ✅ |

## Exam/Test

| 💻 Software | 🌐 Browser Extension | 🧪 System Test | ⬇️ Download | ✅ Bypassed |
|:-----------:|:--------------------:|:--------------:|:-----------:|:------------:|
| Respondus (LockDown Browser) | ✅ | [System Test](https://autolaunch.respondus2.com/MONServer/ldb/preview_launch.do) | [⬇ Download ⬇](https://download.respondus.com/lockdown/download.php) | ✅ |
| ProctorU | ✅ |  | • [⬇ Firefox ⬇](https://s3-us-west-2.amazonaws.com/proctoru-assets/extension/firefox-extension-latest.xpi) <br> • [⬇ Chrome ⬇](https://chrome.google.com/webstore/detail/proctoru/goobgennebinldhonaajgafidboenlkl) | ✅ |
| ProctorU: Guardian Browser |  | [System Test](https://go.proctoru.com/testitout) | • [⬇ Download ⬇](https://production-archimedes-secure-browser-artifacts.s3.amazonaws.com/latest/windows/guardian-browser-x64.exe) <br> • [Meazure Learning Page](https://guardian.meazurelearning.com/) <br> • [ProctorU Page](https://go.proctoru.com/testitout) | ✅ |
| Proctorio | ✅ | [System Test](https://getproctorio.com/) |  | ✅ |
| Prometric: ProProctor |  | [System Test](https://rpcandidate.prometric.com/) |  | ✅ |
| Honorlock | ✅ |  | • [Honorlock](https://app.honorlock.com/install/extension) <br> • [⬇ Chrome ⬇](https://chromewebstore.google.com/detail/honorlock/hnbmpkmhjackfpkpcbapafmpepgmmddc) | ✅ |
| Pearson VUE |  | • [System Test](https://system-test.onvue.com/system_test?customer=pearson_vue) <br> • [System Test](https://vueop.startpractice.com/) |  | ✅ |
| ExamSoft: Examplify |  |  | [⬇ Download ⬇](https://releases.examsoft.com/Examplify/Examplify_LATEST_win.exe) | ✅ |
| Examity | ✅ | [System Test](https://on.v5.examity.com/systemcheck) | • [⬇ Firefox ⬇](https://addons.mozilla.org/en-US/firefox/addon/examity/) <br> • [⬇ Chrome ⬇](https://chromewebstore.google.com/detail/geapelpefnpekodnnlkcaadniodlgebj) | ✅ |
| Safe Exam Browser |  | [System Test](https://demo.safeexambrowser.org/exams/) | [⬇ Download ⬇](https://github.com/SafeExamBrowser/seb-win-refactoring/releases) | ✅ |
| ETS Online Test (CLEP) |  |  | [⬇ Download ⬇](https://www.ets.org/browserinstall) | ✅ |
| Bluebook |  |  | [⬇ Download ⬇](https://bluebook.app.collegeboard.org/) | ✅ |
| Inspera Exam Portal |  | [Demo Exam Instructions](https://www.ltu.se/en/student-web/your-studies/examination/digital-exam-inspera/instructions-for-pc-and-mac-when-downloading-the-inspera-exam-portal) | [⬇ Download ⬇](https://ltu.inspera.com/get-iep) | ✅ |
| Kryterion |  | [System Test](https://www.kryterion.com/systemcheck/) | [⬇ Download ⬇](https://media.webassessor.com/respondus/windows/labedition/Respondus_LockDown_Browser_Lab_OEM.msi) | ✅ |

## Anti-Cheats

- [areweanticheatyet](https://areweanticheatyet.com/)

| 🎮 Game | 🛡️ Engine | ✅ Bypassed |
|:------:|:--------:|:--------:|
| Fortnite | Easy Anti-Cheat (EAC) | ✅ |
| Call of Duty (Warzone / MW Series) | RICOCHET | ✅ |
| Roblox | Hyperion | ✅ |
| Valorant / League of Legends | Vanguard | ✅ ([Hyper-V](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/overview) + [HVCI](https://learn.microsoft.com/en-us/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity)) |
| PUBG: Battlegrounds | Gepard Shield | ✅ |
| Tom Clancy's Rainbow Six® Siege | BattlEye (BE) + FairFight | ✅ |
| Genshin Impact | Mhyprot | ❔ (HoYoKProtect.sys) <br> 🪟 [BSOD: ATTEMPTED_WRITE_TO_READONLY_MEMORY](https://github.com/Scrut1ny/Hypervisor-Phantom/issues/34) |
| Battlefield™ 2042 | EA anticheat (EAAC) | ✅ |
| Marvel Rivals | NACE (Netease Anticheat Expert) | ✅ |
| Various Desktop Games | Easy Anti-Cheat (EAC) | ✅ |
| Various Desktop Games | nProtect GameGuard (NP) | ✅ |
| Various Desktop Games | BattlEye (BE) | ✅ ([Hyper-V](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/overview) + [HVCI](https://learn.microsoft.com/en-us/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity)) |
| Various Mobile Games | Anti-Cheat Expert (ACE) | ✅ |

</details>





<details>
<summary>Virtual Audio & Video (AV)</summary>

## Video
- Display
  - [LookingGlass](https://github.com/gnif/LookingGlass)
    - [Virtual-Display-Driver](https://github.com/itsmikethetech/Virtual-Display-Driver)
  - [memflow-mirror](https://github.com/ko1N/memflow-mirror)
  - [Sunshine](https://github.com/LizardByte/Sunshine)
  - [Moonlight](https://github.com/moonlight-stream/moonlight-qt)
- Streaming (WHIP/WHEP)
  - [meshcast.io](https://meshcast.io/)
  - [VDO.Ninja](https://vdo.ninja/)
- Webcam Manipulation
  - [Deep-Live-Cam](https://github.com/hacksider/Deep-Live-Cam)

## Audio
- [VB-AUDIO](https://vb-audio.com/Cable/index.htm)

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
    - Windows:
        - [ShareX](https://github.com/ShareX/ShareX)
- RAT (Remote Access/Administration Trojan)
    - [Quasar](https://github.com/quasar/Quasar)
        - [Resource Hacker](https://www.angusj.com/resourcehacker/)
- Monitor EDID Modifiers
  - EEPROM EDID (Hardware)
    - [Monitor Tests](https://www.monitortests.com/)
      - [EDID/DisplayID Writer](https://www.monitortests.com/forum/Thread-EDID-DisplayID-Writer)
  - Windows INF override registry EDID (Software)
    - [Monitor Tests](https://www.monitortests.com/)
      - [Custom Resolution Utility (CRU)](https://www.monitortests.com/forum/Thread-Custom-Resolution-Utility-CRU)
    - [Monitor Asset Manager](https://www.entechtaiwan.com/util/moninfo.shtm)
- UEFI/BIOS Editors
    - [Phoenix BIOS Editor](https://theretroweb.com/drivers/208)
    - [UEFITool](https://github.com/LongSoft/UEFITool)

</details>





---





## 🔩 Hardware

<details>
<summary>Bypassing HDCP</summary>

#### HDCP (High-bandwidth Digital Content Protection) Stuff
- [Wikipedia - HDCP](https://en.wikipedia.org/wiki/High-bandwidth_Digital_Content_Protection)
- [NVIDIA - To verify if your system is HDCP-capable](https://www.nvidia.com/content/Control-Panel-Help/vLatest/en-us/mergedProjects/Display/To_verify_if_your_system_is_HDCP-capable.htm)

## Bypassing HDCP Hardware/Software Diagram:
![bypass](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/589b0f88-f14b-44d8-bf1c-225df4d01e54)

## Bypass Kits

#### Expensive Bypass Kit (Recommended):
- 1x2 HDMI Splitter <> [U9/ViewHD - VHD-1X2MN3D](https://www.amazon.com/dp/B086JKRSW1) - `~$18.00`
- EDID Emulator <> [4K-EWB - HDMI 2.1 4K EDID Emulator](https://www.amazon.com/dp/B0DB7YDFD6) - `~$25.00`
- USB HDMI Capture Card <> [Elgato HD60 X](https://www.amazon.com/dp/B09V1KJ3J4) - `~$160.00`

#### Cheap Bypass Kit (Not recommended):
- 1x2 HDMI Splitter <> [OREI](https://www.amazon.com/dp/B005HXFARS) - `~$13.00`
- EDID Emulator <> [EVanlak](https://www.amazon.com/dp/B07YMTKJCR) - `~$7.00`
- USB HDMI Capture Card <> [AXHDCAP](https://www.amazon.com/dp/B0C2MDTY8P) - `~$9.00`

## Equipment List
- External USB Capture Card(s)
    - Elgato
        - [HD60 X | 10GBE9901](https://www.amazon.com/dp/B09V1KJ3J4) - `~$140.00`
        - [4K X | 20GBH9901](https://www.amazon.com/dp/B0CPFWXMBL) - `~$200.00`
        - [Game Capture Neo | 20GBI9901](https://www.amazon.com/dp/B0CVYKQNFH) - `~$110.00`
        - [Cam Link](https://www.amazon.com/dp/B07K3FN5MR) - `~$90.00`
    - [AXHDCAP 4K HDMI Video Capture Card](https://www.amazon.com/dp/B0C2MDTY8P) - `~$9.98`
- 1x2 HDMI Splitter(s)
    - [U9 / ViewHD](https://u9ltd.myshopify.com/collections/splitter)
        - [VHD-1X2MN3D](https://www.amazon.com/dp/B004F9LVXC) - `~$22.00`
        - [VHD-1X2MN3D](https://www.amazon.com/dp/B086JKRSW1) - `~$18.00`
    - HBAVLINK
        - [HB-SP102B](https://www.amazon.com/dp/B08T62MKH1)
        - [HB-SP102C](https://www.amazon.com/dp/B08T64JWWT)
    - CORSAHD
        - [CO-SP12H2](https://www.amazon.com/dp/B0CLL5GQXT)
        - [?????????](https://www.amazon.com/dp/B0CXHQNSWM)
    - EZCOO
        - [EZ-SP12H2](https://www.amazon.com/dp/B07VP37KMB)
        - [EZ-EX11HAS-PRO](https://www.amazon.com/dp/B07TZRXKYG)
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


