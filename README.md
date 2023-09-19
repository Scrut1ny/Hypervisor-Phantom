### VBoxManage Tool Location:
`%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe`

### Configuring the BIOS DMI Information

DMI BIOS information (type 0)
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor" "BIOS Vendor"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion" "BIOS Version"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate" "BIOS Release Date"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMajor" 1
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMinor" 2
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMajor" 3
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMinor" 4

DMI system information (type 1)
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor" "System Vendor"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct" "System Product"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion" "System Version"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial" "System Serial"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU" "System SKU"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily" "System Family"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiSystemUuid" "9852bf98-b83c-49db-a8de-182c42c7226b"

DMI board information (type 2)
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor" "Board Vendor"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct" "Board Product"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVersion" "Board Version"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBoardSerial" "Board Serial"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBoardAssetTag" "Board Tag"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBoardLocInChass" "Board Location"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiBoardBoardType" 10

DMI system enclosure or chassis (type 3)
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor" "Chassis Vendor"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiChassisType" 3
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVersion" "Chassis Version"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiChassisSerial" "Chassis Serial"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiChassisAssetTag" "Chassis Tag"

DMI processor information (type 4)
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiProcManufacturer" "GenuineIntel"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiProcVersion" "Pentium(R) III"

DMI OEM strings (type 11)
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxVer" "vboxVer_1.2.3"
$ VBoxManage setextradata <VM-name> "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxRev" "vboxRev_12345"
