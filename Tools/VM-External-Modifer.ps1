# ==================================================
# Admin Check
# ==================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$($PWD.Path)' ; & '$($myInvocation.InvocationName)'`"" -Verb RunAs
    Exit
}

# ==================================================
# External Modifiers
# ==================================================

$CPUID_String = (Get-CimInstance -ClassName Win32_Processor).Manufacturer
$Hypervisor = Read-Host "`n  # Enter a hypervisor 'vmware' or 'vbox'"

if ($Hypervisor -eq "vbox") {
    $VBoxManager = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
    Write-Host "`n  # Available VMs:`n"
    & $VBoxManager list vms

    $VM = Read-Host "`n  # Enter VM Name"
    $VDI = "$env:USERPROFILE\VirtualBox VMs\$VM\$VM.vdi"

    if (-not (Test-Path $VBoxManager)) {
        Write-Host "  # VirtualBox is not installed." -ForegroundColor Red
        exit 1
    }

    try {
        # ===== Misc. =====
        & $VBoxManager modifyvm $VM --clipboard-mode "bidirectional" --drag-and-drop "bidirectional"
        & $VBoxManager modifyvm $VM --mouse "ps2" --keyboard "ps2"
        & $VBoxManager modifyvm $VM --pae "on" --nested-hw-virt "on"
        & $VBoxManager modifyvm $VM --paravirtprovider "none" --nested-paging "on"
        & $VBoxManager modifyvm $VM --audio-out "on" --audio-in "on"
        & $VBoxManager modifyvm $VM --nic1 "bridged" --mac-address1 "428D5C257A8B"
        & $VBoxManager modifyvm $VM --hwvirtex "on" --vtx-ux "on"
        & $VBoxManager modifyvm $VM --large-pages "on"
        
        # ===== Storage Config [SATA > NVMe] =====
        # Important: Must install Windows on the .vdi attachment before switching to a NVMe Controller.
        # & $VBoxManager storagectl $VM --name "NVMe" --add "pcie" --controller "NVMe" --bootable "on"
        # & $VBoxManager storageattach $VM --storagectl "SATA" --port "0" --device "0" --medium "none"
        # & $VBoxManager storageattach $VM --storagectl "NVMe" --port "0" --device "0" --type "hdd" --medium "$VDI" --nonrotational "on"
        # NVMe Fix
        # & $VBoxManager setextradata $VM "VBoxInternal/Devices/nvme/0/Config/MsiXSupported" "0"
        # & $VBoxManager setextradata $VM "VBoxInternal/Devices/nvme/0/Config/CtrlMemBufSize" "0"
        
        # ===== CPU =====
        # CPUID
        & $VBoxManager modifyvm $VM --cpu-profile "AMD Ryzen 7 1800X Eight-Core"
        # RDTSC (Read Time-Stamp Counter)
        & $VBoxManager setextradata $VM "VBoxInternal/TM/TSCMode" "RealTSCOffset"
        & $VBoxManager setextradata $VM "VBoxInternal/CPUM/SSE4.1" "1"
        & $VBoxManager setextradata $VM "VBoxInternal/CPUM/SSE4.2" "1"
        # RDTSC VM Exit (Read Time-Stamp Counter)
        

        # ===== SMBIOS DMI =====
        # DMI BIOS Information (type 0)
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor" "American Megatrends International, LLC."
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion" "1.A0"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate" "11/23/2023"
        # DMI System Information (type 1)
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor" "Micro-Star International Co., Ltd."
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct" "MS-7D78"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion" "1.0"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial" "To be filled by O.E.M."
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily" "To be filled by O.E.M."
        # DMI Base Board/Module Information (type 2)
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor" "Micro-Star International Co., Ltd."
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct" "PRO B650-P WIFI (MS-7D78)"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVersion" "1.0"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiBoardSerial" "To be filled by O.E.M."
        # DMI System Enclosure or Chassis (type 3)
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor" "Micro-Star International Co., Ltd."
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiChassisType" "03"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVersion" "1.0"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiChassisSerial" "To be filled by O.E.M."
        # DMI Processor Information (type 4)
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiProcManufacturer" "Advanced Micro Devices, Inc."
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiProcVersion" "AMD Ryzen 7 1800X Eight-Core Processor"
        # DMI OEM strings (type 11)
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxVer" "<EMPTY>"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxRev" "<EMPTY>"
        # Configuring the Hard Disk Vendor Product Data (VPD)
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port0/ModelNumber" "Samsung SSD 980 EVO"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port0/FirmwareRevision" "L4Q8G9Y1"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port0/SerialNumber" "J8R9H3P5N4Q7W0X2Y9A5"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/ModelNumber" "HL-DT-ST BD-RE WH16NS60"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/FirmwareRevision" "P2K9W6X5"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/SerialNumber" "Q2W3E4R5T6Y7U8I9O0PA"
        # CD/DVD drives
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIProductId" "DVD A DS8A8SH"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIRevision" "KAA2"
        & $VBoxManager setextradata $VM "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIVendorId" "Slimtype"

        # & $VBoxManager startvm $VM
        Write-Host "`n  # Success" -ForegroundColor Green
    }
    catch {
        Write-Host "`n  # An error occurred: $_" -ForegroundColor Red
    }
}
elseif ($Hypervisor -eq "vmware") {
    # Default directory to search for .vmx files
    $defaultDirectory = "C:\Path\To\VMs"

    # Get a list of .vmx files in the default directory
    $vmxFiles = Get-ChildItem -Path $defaultDirectory -Filter *.vmx

    # Prompt the user to choose a .vmx file
    Write-Host "Please choose a .vmx file from the list below:"
    for ($i = 0; $i -lt $vmxFiles.Length; $i++) {
        Write-Host "$($i + 1): $($vmxFiles[$i].FullName)"
    }

    $selection = Read-Host "Enter the number of the .vmx file you want to use"

    # Validate the user's selection
    if ($selection -match '^\d+$' -and $selection -gt 0 -and $selection -le $vmxFiles.Length) {
        $vmxPath = $vmxFiles[$selection - 1].FullName
        Write-Host "You have selected: $vmxPath"

        # Entries to add to the .vmx file
        $entries = @"
hypervisor.cpuid.v0 = "FALSE"                    # Disable the hypervisor signature in CPUID
board-id.reflectHost = "TRUE"                    # Reflect the host board ID to the guest
hw.model.reflectHost = "TRUE"                    # Reflect the host hardware model to the guest
serialNumber.reflectHost = "TRUE"                # Reflect the host serial number to the guest
smbios.reflectHost = "TRUE"                      # Reflect the host SMBIOS information to the guest
SMBIOS.noOEMStrings = "TRUE"                     # Remove OEM strings from the SMBIOS information

isolation.tools.getPtrLocation.disable = "TRUE"  # Disable the ability to get the mouse pointer location
isolation.tools.setPtrLocation.disable = "TRUE"  # Disable the ability to set the mouse pointer location
isolation.tools.setVersion.disable = "TRUE"      # Disable the ability to set the VMware tools version
isolation.tools.getVersion.disable = "TRUE"      # Disable the ability to get the VMware tools version

monitor_control.virtual_rdtsc = "false"          # Disable the use of the virtual timestamp counter (RDTSC) instruction
monitor_control.restrict_backdoor = "true"       # Restrict the usage of the VMware backdoor I/O port
monitor_control.disable_directexec = "true"      # Disable direct execution of guest code
monitor_control.disable_chksimd = "true"         # Disable checks for SIMD (Single Instruction, Multiple Data) instructions
monitor_control.disable_ntreloc = "true"         # Disable relocation of non-transactional code
monitor_control.disable_selfmod = "true"         # Disable self-modifying code
monitor_control.disable_reloc = "true"           # Disable code relocation
monitor_control.disable_btinout = "true"         # Disable access to I/O ports via the backdoor
monitor_control.disable_btmemspace = "true"      # Disable memory space access via the backdoor
monitor_control.disable_btpriv = "true"          # Disable privileged instructions via the backdoor
monitor_control.disable_btseg = "true"           # Disable segment descriptor access via the backdoor

scsi0:0.productID = "Samsung SSD 980 500GB"      # Set the product ID for the SCSI device
scsi0:0.vendorID = "Samsung"                     # Set the vendor ID for the SCSI device
nvme0:0.productID = "Samsung SSD 980 500GB"      # Set the product ID for the NVMe device
nvme0:0.vendorID = "Samsung"                     # Set the vendor ID for the NVMe device

ethernet0.address = "24:C3:43:A6:BF:8E"          # Set a specific MAC address for the Ethernet adapter
"@

        # Commented out TESTING section
        $testingSection = @"
### TESTING ###
# vmGenCounter.enable = "FALSE"                 # Disable the virtual machine generation counter
# monitor_control.disable_hvsim_clusters = "TRUE"  # Disable Hyper-V simulation clusters
# monitor_control.disable_apichv = "TRUE"       # Disable API calls related to Hyper-V
# monitor_control.disable_nmi = "TRUE"          # Disable Non-Maskable Interrupts
# monitor_control.disable_acpi = "TRUE"         # Disable Advanced Configuration and Power Interface (ACPI) features
# monitor_control.disable_cpenable = "TRUE"     # Disable CPUID enablement
# monitor_control.disable_hv = "TRUE"           # Disable Hyper-V related features
# monitor_control.disable_hotadd = "TRUE"       # Disable hot-add of CPU and memory
# monitor_control.disable_pmu = "TRUE"          # Disable Performance Monitoring Unit
# monitor_control.disable_rdtscp = "TRUE"       # Disable RDTSCP instruction support
# monitor_control.disable_vapic = "TRUE"        # Disable Virtual APIC support
# monitor_control.disable_vhv = "TRUE"          # Disable Virtual Hardware Virtualization
# monitor_control.disable_vmtrr = "TRUE"        # Disable VMTRR support
# monitor_control.disable_x2apic = "TRUE"       # Disable x2APIC support
# tools.syncTime = "FALSE"                      # Disable time synchronization with host
# isolation.tools.copy.disable = "TRUE"         # Disable copy operations between guest and host
# isolation.tools.paste.disable = "TRUE"        # Disable paste operations between guest and host
# isolation.tools.dnd.disable = "TRUE"          # Disable drag-and-drop operations between guest and host
# isolation.tools.hgfs.disable = "TRUE"         # Disable VMware Host-Guest File System
# mks.enable3d = "FALSE"                        # Disable 3D acceleration
# svga.vramSize = "16384"                       # Set SVGA VRAM size to a minimal value
# vhv.enable = "FALSE"                          # Disable nested virtualization
"@

        # Add the entries to the .vmx file
        Add-Content -Path $vmxPath -Value $entries
        Add-Content -Path $vmxPath -Value $testingSection

        Write-Host "Entries have been added to the .vmx file."
    } else {
        Write-Host "Invalid selection. Please run the script again and select a valid number."
    }
}
else {
    Write-Host "`n  # Invalid hypervisor selected. Please choose 'vmware' or 'vbox'." -ForegroundColor Red
}

# https://en.wikipedia.org/wiki/CPUID
# "%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe" list cpu-profiles
# "%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe" list hostcpuids

# & $VBoxManager modifyvm $VM --cpuid-set "00000001", "00a60f12", "02100800", "7ed8320b", "178bfbff"
# & $VBoxManager modifyvm $VM --paravirtdebug "enabled=1,vendor=AuthenticAMD"
# & $VBoxManager modifyvm $VM --paravirtdebug "enabled=1,vendor=GenuineIntel"
