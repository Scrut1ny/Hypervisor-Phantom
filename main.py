#!/usr/bin/env python3
import os
import sys
import subprocess
from pathlib import Path
from utils import utils

DISTRO = None
VENDOR_ID = None

def detect_distro():
    global DISTRO
    distro_id = ""
    if Path("/etc/os-release").exists():
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("ID="):
                    distro_id = line.strip().split("=")[1].replace('"', "")
                    break
    arch_like = {"arch", "manjaro", "endeavouros", "arcolinux", "garuda", "artix"}
    opensuse_like = {"opensuse-tumbleweed", "opensuse-slowroll", "opensuse-leap", "sles"}
    debian_like = {"debian","ubuntu","linuxmint","kali","pureos","pop","elementary","zorin",
                   "mx","parrot","deepin","peppermint","trisquel","bodhi","linuxlite","neon"}
    fedora_like = {"fedora","centos","rhel","rocky","alma","oracle"}

    if distro_id in arch_like:
        DISTRO = "Arch"
    elif distro_id in opensuse_like:
        DISTRO = "openSUSE"
    elif distro_id in debian_like:
        DISTRO = "Debian"
    elif distro_id in fedora_like:
        DISTRO = "Fedora"

    if not DISTRO:
        import shutil
        if shutil.which("pacman"):
            DISTRO = "Arch"
        elif shutil.which("apt"):
            DISTRO = "Debian"
        elif shutil.which("zypper"):
            DISTRO = "openSUSE"
        elif shutil.which("dnf"):
            DISTRO = "Fedora"
        else:
            DISTRO = f"Unknown ({distro_id})" if distro_id else "Unknown"

def cpu_vendor_id():
    global VENDOR_ID
    try:
        output = subprocess.check_output("lscpu", shell=True, text=True, stderr=subprocess.DEVNULL)
        for line in output.splitlines():
            if line.startswith("Vendor ID:"):
                VENDOR_ID = line.split(":")[1].strip()
                break
    except Exception:
        pass

    if not VENDOR_ID:
        try:
            with open("/proc/cpuinfo") as f:
                for line in f:
                    if "vendor_id" in line:
                        VENDOR_ID = line.split(":")[1].strip()
                        break
        except Exception:
            pass

    if not VENDOR_ID:
        VENDOR_ID = "Unknown"

def print_system_info():
    virt_map = {"GenuineIntel": "VT-x", "AuthenticAMD": "AMD-V"}
    iommu_map = {"GenuineIntel": "VT-d", "AuthenticAMD": "AMD-Vi"}

    virt_name = virt_map.get(VENDOR_ID, "Unknown")
    iommu_name = iommu_map.get(VENDOR_ID, "Unknown")
    show_output = False
    output = ""

    try:
        with open("/proc/cpuinfo") as f:
            cpuinfo = f.read()
        if ("vmx" in cpuinfo or "svm" in cpuinfo):
            output += f"\n  [✅] {virt_name} (Virtualization): Supported"
        else:
            output += f"\n  [❌] {virt_name} (Virtualization): Not supported"
            show_output = True
    except Exception:
        output += f"\n  [❌] {virt_name} (Virtualization): Unknown"
        show_output = True

    if Path("/sys/kernel/iommu_groups").exists() and any(Path("/sys/kernel/iommu_groups").iterdir()):
        output += f"\n  [✅] {iommu_name} (IOMMU): Enabled"
    else:
        output += f"\n  [❌] {iommu_name} (IOMMU): Not enabled"
        show_output = True

    try:
        lsmod = subprocess.check_output("lsmod", shell=True, text=True)
        if "kvm" in lsmod:
            output += f"\n  [✅] KVM Kernel Module: Loaded"
        else:
            output += f"\n  [❌] KVM Kernel Module: Not loaded"
            show_output = True
    except Exception:
        output += f"\n  [❌] KVM Kernel Module: Unknown"
        show_output = True

    if show_output:
        print(output + "\n\n  ──────────────────────────────\n")

def execute_module(script_name):
    """Helper to execute a module shell script safely"""
    script_path = Path(f"./modules/{script_name}")
    if script_path.exists() and script_path.is_file():
        subprocess.call([str(script_path)])
    else:
        utils.error(f"Module {script_name} not found!")

def main_menu():
    options = {
        "1": "Virtualization Setup",
        "2": "QEMU (Patched) Setup",
        "3": "EDK2 (Patched) Setup",
        "4": "GPU Passthrough Setup",
        "5": "Kernel (Patched) Setup",
        "6": "Looking Glass Setup",
        "7": "Auto Libvirt XML Setup"
    }

    exit_option = "Exit"

    modules = {
        "1": "virtualization.sh",
        "2": "patch_qemu.sh",
        "3": "patch_ovmf.sh",
        "4": "gpu_passthrough.sh",
        "5": "patch_kernel.sh",
        "6": "looking_glass.sh",
        "7": "auto_xml.sh"
    }

    while True:
        os.system("clear")
        utils.box_text(" >> Hypervisor Phantom << ")
        print_system_info()

        menu = "\n".join([
            utils.format_text("  ", f"[{key}]", f" {options[key]}", utils.TEXT_BRIGHT_YELLOW)
            for key in options
        ])

        menu += f"\n\n{utils.format_text('  ', '[0]', f' {exit_option}', utils.TEXT_BRIGHT_RED)}\n"

        print(f"\n{menu}")

        choice = utils.quick_prompt("  Enter your choice [0-7]: ")

        os.system("clear")
        if choice == "0":
            if utils.yes_or_no("Do you want to clear the logs directory?"):
                for log_file in Path(utils.LOG_PATH).glob("*.log"):
                    log_file.unlink()
            sys.exit(0)
        elif choice in modules:
            utils.box_text(options[choice])
            execute_module(modules[choice])
        else:
            utils.error("Invalid option, please try again.")

        utils.quick_prompt(utils.info("Press any key to continue..."))

def main():
    if os.geteuid() != 0:
        print("\n  [❌] Script requires root/sudo privileges.\n       Please run: sudo python3 main.py")
        sys.exit(1)

    utils.init_log()
    detect_distro()
    cpu_vendor_id()
    main_menu()

if __name__ == "__main__":
    main()
