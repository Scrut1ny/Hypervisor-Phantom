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


>nul 2>&1 (
	rem Specifies how to share the guest VM or host system OS’s clipboard with the host system or guest VM, respectively.
	"!VBoxManager!" modifyvm "!VM!" --clipboard-mode "guesttohost"
	rem Specifies how to use the drag and drop feature between the host system and the VM.
	"!VBoxManager!" modifyvm "!VM!" --drag-and-drop "bidirectional"
	
	rem Specifies the mode of the mouse to use in the VM.
	"!VBoxManager!" modifyvm "!VM!" --mouse "usb"
	rem Specifies the mode of the keyboard to use in the VM.
	"!VBoxManager!" modifyvm "!VM!" --keyboard "usb"
	rem Specifies whether the real-time clock (RTC) uses coordinated universal time (UTC).
	"!VBoxManager!" modifyvm "!VM!" --rtc-use-utc "off"
	
	rem Enables or disables physical address extension (PAE).
	"!VBoxManager!" modifyvm "!VM!" --pae "on"
	rem Enables or disables nested virtualization. Enabling makes hardware virtualization features available to the VM. 
	"!VBoxManager!" modifyvm "!VM!" --nested-hw-virt "on"
	
	rem Specifies one of the following paravirtualization interfaces to provide to the guest OS.
	"!VBoxManager!" modifyvm "!VM!" --paravirt-provider "hyperv"
	rem Enables or disables the nested paging feature in the processor of the host system.
	"!VBoxManager!" modifyvm "!VM!" --nested-paging "on"
	
	rem Enables you to configure multiple monitors.
	"!VBoxManager!" modifyvm "!VM!" --monitor-count "1"
	
	rem Configures the network type used by each virtual network card in the VM.
	"!VBoxManager!" modifyvm "!VM!" --nic1 "bridged"
	rem Specifies the MAC address of the specified network adapter on the VM.
	"!VBoxManager!" modifyvm "!VM!" --mac-address1 "00065B1A9E03"
	
	
	rem RDTSC (Read Time-Stamp Counter)
	rem UserManual.pdf#section.10.11
	rem "!VBoxManager!" setextradata "!VM!" "VBoxInternal/TM/TSCTiedToExecution" "1"
	rem "!VBoxManager!" setextradata "!VM!" "VBoxInternal/TM/TSCMode" "RealTSCOffset"
	rem "!VBoxManager!" setextradata "!VM!" "VBoxInternal/CPUM/EnableHVP" "0"
	rem "!VBoxManager!" setextradata "!VM!" "VBoxInternal/CPUM/SSE4.1" "1"
	rem "!VBoxManager!" setextradata "!VM!" "VBoxInternal/CPUM/SSE4.2" "1"
	
	rem Enables or disables the use of hardware virtualization extensions in the processor of the host system.
	"!VBoxManager!" modifyvm "!VM!" --hwvirtex "on"
	rem Enables or disables the use of unrestricted guest mode for executing the guest VM.
	"!VBoxManager!" modifyvm "!VM!" --vtx-ux "on"
	rem Enables or disables the hypervisor’s use of large pages, which can improve performance by up to 5%.
	"!VBoxManager!" modifyvm "!VM!" --large-pages "on"
	rem Enables or disables a High Precision Event Timer (HPET) that can replace a legacy system timer.
	rem "!VBoxManager!" modifyvm "!VM!" --hpet "on"
	rem Specifies the profile to use for guest CPU emulation
	rem "!VBoxManager!" modifyvm "!VM!" --cpu-profile "Intel 8086"
	
	rem "!VBoxManager!" modifyvm "!VM!" --cpuid-remove-all
	
	
	rem CustomVideoMode
	"!VBoxManager!" setextradata "!VM!" "CustomVideoMode1" "1920x1080x32"


	rem DMI BIOS Information (type 0)
	rem UserManual.pdf#section.10.9
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor" "American Megatrends International, LLC."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion" "1.A0"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate" "11/23/2023"

	rem DMI System Information (type 1)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor" "Micro-Star International Co., Ltd."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct" "MS-7D78"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion" "1.0"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial" "To be filled by O.E.M."

	rem DMI Base Board/Module Information (type 2)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor" "Micro-Star International Co., Ltd."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct" "PRO B650-P WIFI (MS-7D78)"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVersion" "1.0"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiBoardSerial" "To be filled by O.E.M."

	rem DMI System Enclosure or Chassis (type 3)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor" "Micro-Star International Co., Ltd."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisType" "03"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVersion" "1.0"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiChassisSerial" "To be filled by O.E.M."

	rem DMI Processor Information (type 4)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiProcManufacturer" "Advanced Micro Devices, Inc."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiProcVersion" "AMD Ryzen 7 7700X 8-Core Processor"

	rem DMI OEM strings (type 11)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxVer" "To be filled by O.E.M."
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxRev" "To be filled by O.E.M."
	
	rem Configuring the Hard Disk Vendor Product Data (VPD) (10.7.2)
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port0/ModelNumber" "Samsung SSD 980 EVO"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port0/FirmwareRevision" "L4Q8G9Y1"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port0/SerialNumber" "J8R9H3P5N4Q7W0X2Y9A5"
	
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/ModelNumber" "HL-DT-ST BD-RE WH16NS60"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port0/FirmwareRevision" "P2K9W6X5"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/SerialNumber" "Q2W3E4R5T6Y7U8I9O0PA"
	
	rem CD/DVD drives
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIProductId" "DVD A DS8A8SH"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIRevision" "KAA2"
	"!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIVendorId" "Slimtype"
	
	rem "!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/acpi/0/Config/CustomTable" $SLIC
	rem "!VBoxManager!" setextradata "!VM!" "VBoxInternal/Devices/acpi/0/Config/AcpiOemId" "ASUS"
	
	"!VBoxManager!" startvm "!VM!"
	
) && echo( & echo   # Success

rem 	rem Enables or disables long mode.
rem 	"!VBoxManager!" modifyvm "!VM!" --long-mode "off"
rem 	rem Enables or disables the use of the tagged TLB (VPID) feature in the processor of your host system.
rem 	"!VBoxManager!" modifyvm "!VM!" --vtx-vpid "off"
