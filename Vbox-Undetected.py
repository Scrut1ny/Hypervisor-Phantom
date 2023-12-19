import subprocess
import uuid
import random

# Function to generate a random MAC address
def generate_mac_address():
    mac = [0x52, 0x54, 0x00]  # MAC address prefix for VirtualBox
    for _ in range(3):
        mac.append(random.randint(0x00, 0xFF))
    return ':'.join(map(lambda x: format(x, '02x'), mac))

# Function to generate a random UUID
def generate_uuid():
    return str(uuid.uuid4())

# Define the path to VBoxManage.exe
VBoxManager = r"%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe"

# Prompt for VM name
c = input("Enter VM Name: ")

# Generate random UUID and MAC address
random_uuid = generate_uuid()
random_mac = generate_mac_address()

# Define the commands to set DMI information
dmi_commands = [
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMajor", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMinor", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMajor", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMinor", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiSystemUuid", random_uuid],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBoardVersion", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBoardSerial", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBoardAssetTag", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBoardLocInChass", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiBoardBoardType", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiChassisType", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiChassisVersion", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiChassisSerial", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiChassisAssetTag", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiProcManufacturer", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiProcVersion", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxVer", "NULLED"],
    [VBoxManager, "setextradata", c, "VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxRev", "NULLED"],
    [VBoxManager, "modifyvm", c, "--macaddress1", random_mac],
]

# Execute the commands
for cmd in dmi_commands:
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Output success message
print("\nSuccess")
input("Press Enter to continue...")