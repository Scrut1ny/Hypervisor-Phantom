#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil
from utils import utils

# =============================================================================
# SYSTEM CHECKS
# =============================================================================

def detect_distro():
    """Detects the Linux distribution and exports it to env."""
    distro_name = "Unknown"
    distro_id = ""

    # Method 1: Read /etc/os-release
    if os.path.exists("/etc/os-release"):
        with open("/etc/os-release", "r") as f:
            for line in f:
                if line.startswith("ID="):
                    distro_id = line.split("=", 1)[1].strip().strip('"')
                    break

        if distro_id in ["arch", "manjaro", "endeavouros", "arcolinux", "garuda", "artix"]:
            distro_name = "Arch"
        elif distro_id in ["opensuse-tumbleweed", "opensuse-slowroll", "opensuse-leap", "sles"]:
            distro_name = "openSUSE"
        elif distro_id in ["debian", "ubuntu", "linuxmint", "kali", "pureos", "pop", "elementary",
                           "zorin", "mx", "parrot", "deepin", "peppermint", "trisquel", "bodhi",
                           "linuxlite", "neon"]:
            distro_name = "Debian"
        elif distro_id in ["fedora", "centos", "rhel", "rocky", "alma", "oracle"]:
            distro_name = "Fedora"

    # Method 2: Fallback to package managers
    if distro_name == "Unknown":
        if shutil.which("pacman"):
            distro_name = "Arch"
        elif shutil.which("apt"):
            distro_name = "Debian"
        elif shutil.which("zypper"):
            distro_name = "openSUSE"
        elif shutil.which("dnf"):
            distro_name = "Fedora"
        elif distro_id:
            distro_name = f"Unknown ({distro_id})"

    # Export for child processes
    os.environ["DISTRO"] = distro_name
    return distro_name

def get_cpu_vendor_id():
    """Gets CPU vendor ID and exports it to env."""
    vendor_id = "Unknown"

    # Method 1: lscpu (standard but requires subprocess)
    if shutil.which("lscpu"):
        try:
            output = subprocess.check_output(["lscpu"], text=True)
            for line in output.splitlines():
                if "Vendor ID:" in line:
                    vendor_id = line.split(":")[1].strip()
                    break
        except Exception:
            pass

    # Method 2: /proc/cpuinfo (faster fallback)
    if vendor_id == "Unknown" and os.path.exists("/proc/cpuinfo"):
        try:
            with open("/proc/cpuinfo", "r") as f:
                for line in f:
                    if "vendor_id" in line:
                        vendor_id = line.split(":")[1].strip()
                        break
        except Exception:
            pass

    # Export for child processes
    os.environ["VENDOR_ID"] = vendor_id
    return vendor_id

def print_system_info(vendor_id):
    """Checks and prints virtualization/IOMMU status."""
    output = []
    show_error = False

    # Mappings
    virt_map = {"GenuineIntel": "VT-x", "AuthenticAMD": "AMD-V"}
    iommu_map = {"GenuineIntel": "VT-d", "AuthenticAMD": "AMD-Vi"}

    virt_name = virt_map.get(vendor_id, "Unknown")
    iommu_name = iommu_map.get(vendor_id, "Unknown")

    # Check 1: Virtualization Support in CPU
    has_virt = False
    try:
        with open("/proc/cpuinfo", "r") as f:
            content = f.read()
            if "vmx" in content or "svm" in content:
                has_virt = True
    except OSError:
        pass

    if has_virt:
        output.append(f"  [✅] {virt_name} (Virtualization): Supported")
    else:
        output.append(f"  [❌] {virt_name} (Virtualization): Not supported")
        show_error = True

    # Check 2: IOMMU Groups
    iommu_path = "/sys/kernel/iommu_groups"
    has_iommu = False
    if os.path.isdir(iommu_path):
        try:
            if os.listdir(iommu_path):
                has_iommu = True
        except OSError:
            pass

    if has_iommu:
        output.append(f"  [✅] {iommu_name} (IOMMU): Enabled")
    else:
        output.append(f"  [❌] {iommu_name} (IOMMU): Not enabled")
        show_error = True

    # Check 3: KVM Kernel Module
    has_kvm = False
    try:
        with open("/proc/modules", "r") as f:
            if "kvm" in f.read():
                has_kvm = True
    except OSError:
        pass

    if has_kvm:
        output.append(f"  [✅] KVM Kernel Module: Loaded")
    else:
        output.append(f"  [❌] KVM Kernel Module: Not loaded")
        show_error = True

    # Print results if there are errors or just info
    if show_error:
        print("\n" + "\n".join(output))
        print("\n  ──────────────────────────────\n")
    else:
        # Just print newline if all good, matching original script behavior?
        # Original script: [ "$show_output" -eq 1 ] && echo ... || echo ""
        print("")

# =============================================================================
# MAIN LOGIC
# =============================================================================

def run_script(script_path):
    """Helper to execute a script if it exists."""
    if not os.path.exists(script_path):
        utils.error(f"Script not found: {script_path}")
        return

    # Check if executable
    if not os.access(script_path, os.X_OK):
        # Try to run with bash explicitly if not executable
        cmd = ["bash", script_path]
    else:
        cmd = [script_path]

    try:
        subprocess.run(cmd, check=False)
    except KeyboardInterrupt:
        print() # Handle Ctrl+C gracefully during child script

def main_menu(distro, vendor_id):
    options = [
        ("Exit", None),
        ("Virtualization Setup", "./modules/virtualization.sh"),
        ("QEMU (Patched) Setup", "./modules/patch_qemu.sh"),
        ("EDK2 (Patched) Setup", "./modules/patch_ovmf.sh"),
        ("GPU Passthrough Setup", "./modules/gpu_passthrough.sh"),
        ("Kernel (Patched) Setup", "./modules/patch_kernel.sh"),
        ("Looking Glass Setup", "./modules/looking_glass.sh"),
        ("Auto Libvirt XML Setup", "./modules/auto_xml.sh"),
    ]

    while True:
        os.system('clear')
        utils.box_text(" >> Hypervisor Phantom << ")
        print_system_info(vendor_id)

        # Print Options (1-7)
        for i in range(1, len(options)):
            name = options[i][0]
            utils.format_text(f"  ", f"[{i}]", f" {name}", utils.Colors.BRIGHT_YELLOW)
            # Assuming utils.format_text prints. The python version returns string.
            # Let's fix that usage:
            print(utils.format_text(f"  ", f"[{i}]", f" {name}", utils.Colors.BRIGHT_YELLOW))

        # Print Exit (0)
        print(utils.format_text(f"\n  ", "[0]", f" {options[0][0]}\n", utils.Colors.BRIGHT_RED))

        choice = utils.quick_prompt("  Enter your choice [0-7]: ")
        os.system('clear')

        if choice == '0':
            # Exit Logic
            if utils.yes_or_no(utils.ask_prompt("Do you want to clear the logs directory?")):
                log_dir = os.path.dirname(utils.LOG_FILE)
                try:
                    for filename in os.listdir(log_dir):
                        file_path = os.path.join(log_dir, filename)
                        if os.path.isfile(file_path) and file_path.endswith(".log"):
                            os.remove(file_path)
                except Exception as e:
                    utils.error(f"Failed to clear logs: {e}")
            sys.exit(0)

        elif choice in [str(i) for i in range(1, len(options))]:
            idx = int(choice)
            name, script = options[idx]
            utils.box_text(name)
            run_script(script)

        else:
            utils.error("Invalid option, please try again.")

        utils.quick_prompt(utils.format_text("\n  ", "[i]", " Press any key to continue...", utils.Colors.BRIGHT_CYAN))

def main():
    # Root Check
    if os.geteuid() != 0:
        print("\n  [❌] Script requires root/sudo privileges.\n       Please run: sudo ./main.py")
        sys.exit(1)

    # Export LOG_FILE to env so child scripts can use it if needed
    if utils.LOG_FILE:
        os.environ["LOG_FILE"] = utils.LOG_FILE

    distro = detect_distro()
    vendor_id = get_cpu_vendor_id()

    try:
        main_menu(distro, vendor_id)
    except KeyboardInterrupt:
        print("\nExiting...")
        sys.exit(0)

if __name__ == "__main__":
    main()
