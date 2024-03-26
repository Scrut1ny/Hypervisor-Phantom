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
<summary>Bypassing HDCP</summary>

- [HDCP Versions](https://en.wikipedia.org/wiki/High-bandwidth_Digital_Content_Protection#Versions)

## WORKING BYPASS METHOD AS OF 20240320:
Isolated GPU --> HDMI Cable --> HDMI Splitter (Strips/Downgrades HDCP) --> HDMI Cable --> HDMI to USB Video Capture Device

## Amazon Product Links:
- [HDMI Splitter](https://www.amazon.com/dp/B004F9LVXC)
- [Video Capture Card](https://www.amazon.com/dp/B0C2MDTY8P)
- [x2 - HDMI Cable](https://www.amazon.com/dp/B07X37CG9V)

## Equipment
- HDMI Splitter 1 in 2 Out
    - [#1](https://www.amazon.com/dp/B004F9LVXC)
    - [#2](https://www.amazon.com/dp/B07VP37KMB)
    - [#3](https://www.amazon.com/dp/B07TZRXKYG)
    - [#4](https://www.amazon.com/dp/B08T62MKH1)
- DP or HDMI (Male) to VGA (Female) Adapter <---> VGA (Male) to DP or HDMI (Male) Adapter
    - [#1](https://www.amazon.com/dp/B01GPMRYNM)
    - [#2](https://www.amazon.com/dp/B083P358V6)

</details>

<details>
<summary>QEMU Anti Detection</summary>

* [areweanticheatyet](https://areweanticheatyet.com/)

| Type | Engine | Bypassed |
|-|-|-|
| **Anti-Cheat** | Anti Cheat Expert(ACE) | ✅ |
| **Anti-Cheat** | BattlEye (BE) | ✅ (With RDTSC VM Force Exit Kernal Patch) |
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

<details>
<summary>Pearson VUE</summary>

## BrowserLock
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

## Building a Custom Version
- [Vbox Source Code](https://www.virtualbox.org/browser/vbox/trunk#src/VBox/Devices)
- [Vbox Build Instructions](https://www.virtualbox.org/wiki/Linux%20build%20instructions)

### Dependencies
```
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt install -y acpica-tools chrpath doxygen g++-multilib libasound2-dev libcap-dev libcurl4-openssl-dev libdevmapper-dev libidl-dev libopus-dev libpam0g-dev libpulse-dev libqt5opengl5-dev libqt5x11extras5-dev qttools5-dev libsdl1.2-dev libsdl-ttf2.0-dev libssl-dev libvpx-dev libxcursor-dev libxinerama-dev libxml2-dev libxml2-utils libxmu-dev libxrandr-dev make nasm python3-dev python-dev qttools5-dev-tools texlive texlive-fonts-extra texlive-latex-extra unzip xsltproc default-jdk libstdc++5 libxslt1-dev linux-kernel-headers makeself mesa-common-dev subversion yasm zlib1g-dev glslang-tools ia32-libs libc6-dev-i386 lib32gcc1 lib32stdc++6
```

### Building VirtualBox
```
./configure --disable-hardening && source ./env.sh && kmk all && 
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

### Dependencies
```
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt install -y binutils-mingw-w64 binutils-mingw-w64-i686 binutils-mingw-w64-x86-64 build-essential clang g++-mingw-w64 g++-mingw-w64-i686 g++-mingw-w64-x86-64 gcc-mingw-w64 gcc-mingw-w64-i686 gcc-mingw-w64-x86-64 git git-email gnutls-bin libaio-dev libbluetooth-dev libbrlapi-dev libbz2-dev libcacard-dev libcap-dev libcap-ng-dev libcurl4-gnutls-dev libfdt-dev libglib2.0-dev libgtk-3-dev libibverbs-dev libiscsi-dev libjpeg8-dev liblzo2-dev libncurses5-dev libncursesw5-dev libnfs-dev libnuma-dev libpam0g-dev libpixman-1-dev librbd-dev librdmacm-dev libseccomp-dev libsnappy-dev libsasl2-dev libsdl1.2-dev libsdl2-dev libsdl2-image-dev libspice-protocol-dev libspice-server-dev libusb-1.0-0-dev libusb-dev libusbredirparser-dev libusbredirparser1 libvde-dev libvdeplug-dev libvirglrenderer-dev libvte-2.91-dev libxen-dev libxml2-dev libz-mingw-w64-dev libzstd-dev ninja-build valgrind win-iconv-mingw-w64-dev xfslibs-dev zlib1g-dev
```

### Make custom QEMU .patch file
```
cd $HOME/Downloads && git clone --depth 1 --branch v8.2.1 --recursive https://gitlab.com/qemu-project/qemu.git && cd qemu/

# Edit all compromised strings within the source code...
grep -Rn '"QEMU ' "$HOME/Downloads/qemu"
grep -Rn '"QEMU' "$HOME/Downloads/qemu"
grep -Rn 'Virtual Machine"' "$HOME/Downloads/qemu"
grep -Rn 'Virtual CPU version "' "$HOME/Downloads/qemu"
grep -Rn '"KVM/Linux       "' "$HOME/Downloads/qemu"
grep -Rn '"KVMKVMKVM\\0\\0\\0"' "$HOME/Downloads/qemu"
grep -Rn 'ACPI_BUILD_APPNAME6 "BOCHS "' "$HOME/Downloads/qemu"
grep -Rn 'ACPI_BUILD_APPNAME8 "BXPC    "' "$HOME/Downloads/qemu"
grep -Rn '\[STR_SERIALNUMBER\]' "$HOME/Downloads/qemu"

git diff > v8.2.1.patch
```

### Downloading & Building QEMU w/patch
```
cd $HOME/Downloads && git clone --depth 1 --branch v8.2.1 --recursive https://gitlab.com/qemu-project/qemu.git

cd qemu/ && git apply v8.2.1.patch && cd .. && mkdir qemu_build && cd qemu_build && ../qemu/configure --target-list=x86_64-softmmu,x86_64-linux-user --prefix=/usr && make -j $(nproc) && sudo make install

sudo mv -f qemu-system-x86_64 /bin
```

## QEMU RDTSC VM_Exit Kernal Patch
* [RDTSC-KVM-Handler](https://github.com/Gyztor/kernel-rdtsc-patch)

### Dependencies

- Arch
```
sudo pacman -S base-devel bc coreutils cpio gettext initramfs kmod libelf ncurses pahole perl python rsync tar xz
```

- Debian
```
sudo apt install bc binutils bison dwarves flex gcc git gnupg2 gzip libelf-dev libncurses5-dev libssl-dev make openssl pahole perl-base rsync tar xz-utils
```

- Fedora
```
sudo dnf install binutils ncurses-devel \
    /usr/include/{libelf.h,openssl/pkcs7.h} \
    /usr/bin/{bc,bison,flex,gcc,git,gpg2,gzip,make,openssl,pahole,perl,rsync,tar,xz,zstd}
```

### Download latest Kernal release
- [Linux Kernel Website](https://kernel.org/)
- [Linux Kernal GitHub](https://github.com/torvalds/linux/tags)

### Extracting the tarball
```
tar -xf linux-*.tar && cd linux-*/
```

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
```

- List PCI Devices
```bash
lspci -nn | grep "NVIDIA"
```

or

- List IOMMU Groups
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
![image](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/0c0820d5-3b9f-4b8d-9e87-1df84b947eac)

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
![image](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/dd7fa9e5-8305-4ec0-8a96-c8b2ad4d2ae1)

### Update initramfs
```bash
sudo update-initramfs -c -k $(uname -r) && sudo reboot now
```

### Check kernal driver in use for the isolated GPU (should be vfio-pci)
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
* [Domain XML format](https://libvirt.org/formatdomain.html)
```
  <os>
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

## Looking Glass Setup Guide

- [Client usage](https://looking-glass.io/docs/B6/usage/#)
- *KVM (Kernel-based Virtual Machine) configured for VGA PCI Pass-through without an attached physical monitor, keyboard or mouse.*

### Add this to your .XML file in the devices section:
```
    <shmem name='looking-glass'>
      <model type='ivshmem-plain'/>
      <size unit='M'>32</size>
    </shmem>
```
![image](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/c2400987-64fa-4a00-87c7-f2b6b6b4047f)

### Dependencies
```
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt install -y binutils-dev cmake fonts-dejavu-core libfontconfig-dev gcc g++ pkg-config libegl-dev libgl-dev libgles-dev libspice-protocol-dev nettle-dev libx11-dev libxcursor-dev libxi-dev libxinerama-dev libxpresent-dev libxss-dev libxkbcommon-dev libwayland-dev wayland-protocols libpipewire-0.3-dev libpulse-dev libsamplerate0-dev
```

### Create a new file
```
sudo nano /etc/tmpfiles.d/10-looking-glass.conf
```
- Give it the following contents
```
# Type Path               Mode UID  GID Age Argument

f /dev/shm/looking-glass 0660 user kvm -
```

### Granting Permissions 
```
touch /dev/shm/looking-glass && chown $USER:kvm /dev/shm/looking-glass && chmod 660 /dev/shm/looking-glass
```

### Download/Build/Install LookingGlass
```
curl -sSL https://looking-glass.io/artifact/stable/source -o latest.tar.gz && tar -zxvf latest.tar.gz && rm -rf latest.tar.gz

cd looking-glass-* && mkdir client/build && cd client/build && cmake ../ && make && sudo make install

./looking-glass-client
```

## Testing it out...
- [VFIO - EDID Emulator Review](https://www.youtube.com/watch?v=_freOfQCpYU)
- DP/HDMI/DVI/VGA Dummy Plug (EDID Emulator)
    - [#1 - DP](https://www.amazon.com/dp/B071CGCTMY)
    - [#2 - HDMI](https://www.amazon.com/dp/B07FB8GJ1Z)
    - [#3 - DVI](https://www.amazon.com/dp/B077CKX6ZK)
    - [#4 - VGA](https://www.amazon.com/dp/B075ZMVGQS)
- USB Type C to DP Adapter <---> DP/HDMI/DVI/VGA Dummy Plug (EDID Emulator)
    - [USB C to DisplayPort Adapter](https://www.amazon.com/dp/B0836FFKGD)
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

<details>
<summary>Useful Software</summary>

- Linux:
    - [NormCap](https://github.com/dynobo/normcap)
- Windows:
    - [ShareX](https://github.com/ShareX/ShareX)

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
<summary>Unable to complete install: 'internal error: cannot load AppArmor profile '{UUID}''</summary>

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

## Screen Shots

<details>
<summary>Pearson VUE (OnVUE)</summary>

* [Exam Simulation](https://vueop.startpractice.com/)
![bypassed](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/59e47bc0-93bf-464e-a7ec-21cf1176c6b8)
![bypassed1](https://github.com/Scrut1ny/Hypervisor-Phantom/assets/53458032/68487380-218b-487a-a260-a54a4dfda2e6)

</details>
