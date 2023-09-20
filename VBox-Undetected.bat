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


:: Make sure VM storage size is 61 GB and above.


>nul 2>&1 (
	rem modifyvm
	"!VBoxManager!" modifyvm "!VM!" --apic "on"
	"!VBoxManager!" modifyvm "!VM!" --bioslogoimagepath "C:\XXX.bmp"
	"!VBoxManager!" modifyvm "!VM!" --hpet "on"
	"!VBoxManager!" modifyvm "!VM!" --hwvirtex "on"
	"!VBoxManager!" modifyvm "!VM!" --largepages "on"
	"!VBoxManager!" modifyvm "!VM!" --longmode "on"
	"!VBoxManager!" modifyvm "!VM!" --mac-address1 "6CF1481A9E03"
	"!VBoxManager!" modifyvm "!VM!" --mouse "ps2"
	"!VBoxManager!" modifyvm "!VM!" --nestedpaging "on"
	"!VBoxManager!" modifyvm "!VM!" --pae "on"
	"!VBoxManager!" modifyvm "!VM!" --paravirtprovider "legacy"
	"!VBoxManager!" modifyvm "!VM!" --vtxux "on"
	"!VBoxManager!" modifyvm "!VM!" --vtxvpid "on"
	"!VBoxManager!" modifyvm "!VM!" --nested-hw-virt "on"
	"!VBoxManager!" modifyvm "!VM!" --rtc-use-utc "on"
	"!VBoxManager!" modifyvm "!VM!" --nic1 bridged

	rem CPUM
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/CPUM/EnableHVP" "0"
	
	rem TSC
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/TM/TSCTiedToExecution" "1"

	rem DMI BIOS Information (type 0)
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
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/acpi/0/Config/AcpiOemId" "ASUS"
	rem %vBox% setextradata "%VMname%" "VBoxInternal/Devices/%fw%/0/Config/DmiOEMVBoxVer" "Extended version info: 1.00.00"
	rem %vBox% setextradata "%VMname%" "VBoxInternal/Devices/%fw%/0/Config/DmiOEMVBoxRev" "Extended revision info: 1A"
	
	"!VBoxManager!" startvm "!VM!"
	
) && echo( & echo   # Success & pause>nul


rem https://berhanbingol.medium.com/virtualbox-detection-anti-detection-30614691f108
rem https://github.com/xyafes/VBoxAntiDetection/blob/main/statick.bat
rem 