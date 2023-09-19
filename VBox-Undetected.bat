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
set /p "c=.  # Enter VM Name: "


>nul 2>&1 (
	rem DMI BIOS information (type 0)
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMajor" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMinor" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMajor" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMinor" "NULLED"

	rem DMI system information (type 1)
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemUuid" "86e3949a-c76a-4e53-9b05-49cfd0eb1e25"

	rem DMI board information (type 2)
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVersion" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardSerial" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardAssetTag" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardLocInChass" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardBoardType" "NULLED"

	rem DMI system enclosure or chassis (type 3)
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisType" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVersion" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisSerial" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisAssetTag" "NULLED"

	rem DMI processor information (type 4)
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiProcManufacturer" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiProcVersion" "NULLED"

	rem DMI OEM strings (type 11)
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxVer" "NULLED"
	"!VBoxManager!" setextradata "!c!" "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxRev" "NULLED"
	
	rem MAC Address
	"!VBoxManager!" modifyvm "!c!" --macaddress1 "9E-E7-EA-D8-FF-96"
	
) && echo( & echo   # Success & pause>nul