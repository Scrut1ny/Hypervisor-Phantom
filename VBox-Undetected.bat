:: ==================================================
::  VBox-Undetected
:: ==================================================
::  Dev  - Scut1ny
::  Help - 
::  Link - https://github.com/Scrut1ny/VBox-Undetected
:: ==================================================

@echo off
setlocal enableDelayedExpansion

echo(
set "VBoxManager=%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe"
echo   # Available VMs:
"!VBoxManager!" list vms
echo(
set /p "VM=.  # Enter VM Name: "


:: System Name: DESKTOP-Y357A62
:: Make sure VM storage size is 128 GB and above.


>nul 2>&1 (
	rem Enables or disables APIC
	"!VBoxManager!" modifyvm "!VM!" --apic "on"
	rem Enables or disables a High Precision Event Timer (HPET) that can replace a legacy system timer.
	"!VBoxManager!" modifyvm "!VM!" --hpet "on"
	rem Enables or disables the use of hardware virtualization extensions in the processor of the host system.
	"!VBoxManager!" modifyvm "!VM!" --hwvirtex "on"
	rem Enables or disables the hypervisor’s use of large pages, which can improve performance by up to 5%.
	"!VBoxManager!" modifyvm "!VM!" --large-pages "on"
	rem Enables or disables long mode.
	"!VBoxManager!" modifyvm "!VM!" --longmode "on"
	rem Specifies the MAC address of the specified network adapter on the VM.
	"!VBoxManager!" modifyvm "!VM!" --mac-address1 "6CF1481A9E03"
	rem Specifies the mode of the mouse to use in the VM.
	"!VBoxManager!" modifyvm "!VM!" --mouse "ps2"
	rem Enables or disables the nested paging feature in the processor of the host system.
	"!VBoxManager!" modifyvm "!VM!" --nested-paging "on"
	rem Enables or disables physical address extension (PAE).
	"!VBoxManager!" modifyvm "!VM!" --pae "on"
	rem Specifies one of the following paravirtualization interfaces to provide to the guest OS.
	"!VBoxManager!" modifyvm "!VM!" --paravirt-provider "legacy"
	rem Enables or disables the use of unrestricted guest mode for executing the guest VM.
	"!VBoxManager!" modifyvm "!VM!" --vtx-ux "on"
	rem Enables or disables the use of the tagged TLB (VPID) feature in the processor of your host system.
	"!VBoxManager!" modifyvm "!VM!" --vtx-vpid "on"
	rem Enables or disables nested virtualization. Enabling makes hardware virtualization features available to the VM. 
	"!VBoxManager!" modifyvm "!VM!" --nested-hw-virt "on"
	rem Specifies whether the real-time clock (RTC) uses coordinated universal time (UTC).
	"!VBoxManager!" modifyvm "!VM!" --rtc-use-utc "on"
	rem Configures the network type used by each virtual network card in the VM.
	"!VBoxManager!" modifyvm "!VM!" --nic1 "bridged"


	rem RDTSC (Read Time-Stamp Counter)
	rem UserManual.pdf#section.10.11
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/TM/TSCTiedToExecution" "1"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/TM/TSCMode" "RealTSCOffset"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/CPUM/EnableHVP" "0"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/CPUM/SSE4.1" "1"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/CPUM/SSE4.2" "1"


	rem CustomVideoMode
	"!VBoxManager!" setextradata "!VM!" "CustomVideoMode1" "1920x1080x32"


	rem DMI BIOS Information (type 0)
	rem UserManual.pdf#section.10.9
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor" "American Megatrends International, LLC."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion" "A.K3"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate" "04/23/21"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMajor" "5"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMinor" "17"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMajor" "255"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMinor" "255"

	rem DMI System Information (type 1)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor" "Micro-Star International Co., Ltd."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct" "MS-7B79"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion" "2.0"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial" "To be filled by O.E.M."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemUuid" "86e3949a-c76a-4e53-9b05-49cfd0eb1e25"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU" "To be filled by O.E.M."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily" "To be filled by O.E.M."

	rem DMI Base Board/Module Information (type 2)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor" "Micro-Star International Co., Ltd."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct" "X470 GAMING PLUS (MS-7B79)"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVersion" "2.0"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardSerial" "A593233849"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardAssetTag" "To be filled by O.E.M."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardLocInChass" "To be filled by O.E.M."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardBoardType" ""

	rem DMI System Enclosure or Chassis (type 3)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor" "Micro-Star International Co., Ltd."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisType" "3"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVersion" "2.0"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisSerial" "To be filled by O.E.M."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisAssetTag" "To be filled by O.E.M."

	rem DMI Processor Information (type 4)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiProcManufacturer" "Intel"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiProcVersion" "Intel(R) Xeon(TM) CPU"

	rem DMI OEM strings (type 11)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxVer" ""
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxRev" ""
	
	rem Disk drives
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port0/ModelNumber" "Samsung SSD 970 EVO 500GB"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port0/SerialNumber" "5H6Y7SDFXRGJ9LL"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port0/FirmwareRevision" "ES2OA60W"
	
	rem DVD/CD-ROM drives
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/ModelNumber" "HL-DT-ST DVDRAM GH12NS74 ATA Device"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/SerialNumber" "KC6AYJ8SQ58XSS9"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/FirmwareRevision" "KAA2"
	
	rem CD-ROM drives
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIProductId" "DVD A DS8A8SH"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIRevision" "KAA2"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIVendorId" "Slimtype"
	
	
	
	
	rem 
	rem "!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/acpi/0/Config/CustomTable" $SLIC
	rem "!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/acpi/0/Config/AcpiOemId" "ASUS"
	rem %vBox% setextradata "%VMname%" "VBoxInternal/Devices/%fw%/0/Config/DmiOEMVBoxVer" "Extended version info: 1.00.00"
	rem %vBox% setextradata "%VMname%" "VBoxInternal/Devices/%fw%/0/Config/DmiOEMVBoxRev" "Extended revision info: 1A"
	
	"!VBoxManager!" startvm "!VM!"
	
) && echo( & echo   # Success & pause>nul


rem https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108
rem https://github.com/xyafes/VBoxAntiDetection/blob/main/statick.bat
rem 
