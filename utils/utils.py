#!/usr/bin/env python3
import os
import sys
import subprocess
import termios
import tty
from pathlib import Path

# -----------------------------------------------------------------------------
# DEBUGGER / LOGGING
# -----------------------------------------------------------------------------
LOG_PATH = os.getenv("LOG_PATH", os.path.join(os.getcwd(), "logs"))
LOG_FILE = os.getenv("LOG_FILE", os.path.join(LOG_PATH, f"{int(os.times()[4])}.log"))

def init_log() -> None:
    os.makedirs(LOG_PATH, exist_ok=True)
    Path(LOG_FILE).touch(exist_ok=True)

def fail(message: str) -> None:
    fatal(message)
    sys.exit(1)

# -----------------------------------------------------------------------------
# FORMATTER / ANSI STYLING
# -----------------------------------------------------------------------------
RESET = "\033[0m"

TEXT_BOLD = "\033[1m"
TEXT_DIM = "\033[2m"
TEXT_ITALIC = "\033[3m"
TEXT_UNDER = "\033[4m"
TEXT_BLINK = "\033[5m"
TEXT_REVERSE = "\033[7m"
TEXT_HIDDEN = "\033[8m"
TEXT_STRIKE = "\033[9m"

TEXT_BLACK = "\033[30m"
TEXT_GRAY = "\033[90m"
TEXT_RED = "\033[31m"
TEXT_BRIGHT_RED = "\033[91m"
TEXT_GREEN = "\033[32m"
TEXT_BRIGHT_GREEN = "\033[92m"
TEXT_YELLOW = "\033[33m"
TEXT_BRIGHT_YELLOW = "\033[93m"
TEXT_BLUE = "\033[34m"
TEXT_BRIGHT_BLUE = "\033[94m"
TEXT_MAGENTA = "\033[35m"
TEXT_BRIGHT_MAGENTA = "\033[95m"
TEXT_CYAN = "\033[36m"
TEXT_BRIGHT_CYAN = "\033[96m"
TEXT_WHITE = "\033[37m"
TEXT_BRIGHT_WHITE = "\033[97m"

BACK_BLACK = "\033[40m"
BACK_GRAY = "\033[100m"
BACK_RED = "\033[41m"
BACK_BRIGHT_RED = "\033[101m"
BACK_GREEN = "\033[42m"
BACK_BRIGHT_GREEN = "\033[102m"
BACK_YELLOW = "\033[43m"
BACK_BRIGHT_YELLOW = "\033[103m"
BACK_BLUE = "\033[44m"
BACK_BRIGHT_BLUE = "\033[104m"
BACK_MAGENTA = "\033[45m"
BACK_BRIGHT_MAGENTA = "\033[105m"
BACK_CYAN = "\033[46m"
BACK_BRIGHT_CYAN = "\033[106m"
BACK_WHITE = "\033[47m"
BACK_BRIGHT_WHITE = "\033[107m"

def format_text(prefix: str, text: str, suffix: str = "", *styles: str) -> str:
    return f"{prefix}{''.join(styles)}{text}{RESET}{suffix}"

def __styled_log(icon: str, color: str, message: str, stream: str = "stdout") -> None:
    formatted = format_text("\n  ", icon, f" {message}", color)
    log_file_path = Path(LOG_FILE)
    if stream == "stderr":
        print(formatted, file=sys.stderr)
        with open(log_file_path, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    else:
        print(formatted)
        with open(log_file_path, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")

def log(message: str) -> None:
    __styled_log("[+]", TEXT_BRIGHT_GREEN, message)

def info(message: str) -> None:
    __styled_log("[i]", TEXT_BRIGHT_CYAN, message)

def warn(message: str) -> None:
    __styled_log("[!]", TEXT_BRIGHT_YELLOW, message)

def error(message: str) -> None:
    __styled_log("[-]", TEXT_BRIGHT_RED, message, stream="stderr")

def fatal(message: str) -> None:
    formatted = format_text("\n  ", "[X] " + message, "", TEXT_BRIGHT_RED, TEXT_BOLD)
    print(formatted, file=sys.stderr)
    with open(Path(LOG_FILE), "a", encoding="utf-8") as f:
        f.write(formatted + "\n")

def box_text(text: str) -> None:
    width = len(text) + 2
    print("\n  ╔" + "═" * width + "╗")
    print(f"  ║ {text} ║")
    print("  ╚" + "═" * width + "╝")

# -----------------------------------------------------------------------------
# PROMPTER
# -----------------------------------------------------------------------------
def _format_question(text: str) -> str:
    return format_text("\n  ", "[?]", f" {text}", TEXT_BLACK, BACK_BRIGHT_GREEN)

def ask(text: str, end_newline: bool = True) -> str:
    message = _format_question(text)
    print(message, end="\n" if end_newline else "")
    with open(Path(LOG_FILE), "a", encoding="utf-8") as f:
        f.write(message + "\n")
    return message

def yes_or_no(question: str) -> bool:
    log_file = Path(LOG_FILE)
    formatted = _format_question(question)

    while True:
        answer = input(f"{formatted} [y/n]: ").strip().lower()
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(answer + "\n")

        if answer.startswith("y"):
            print()
            return True
        elif answer.startswith("n"):
            print()
            return False
        else:
            print("\n  [!] Please answer y/n")

def quick_prompt(prompt: str) -> str:
    log_file = Path(LOG_FILE)
    print(prompt, end="", flush=True)
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        response = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    print(response)
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(response + "\n")
    return response

# -----------------------------------------------------------------------------
# PACKAGES / INSTALLATION
# -----------------------------------------------------------------------------
def install_req_pkgs(component: str, required_pkgs_map: dict) -> None:
    if not component:
        error("Component name not specified!")
        sys.exit(1)

    distro = os.getenv("DISTRO")
    if not distro:
        error("Environment variable DISTRO not set.")
        sys.exit(1)

    log(f"Checking for required missing {component} packages...")

    pkg_managers = {
        "Arch": ("pacman", "sudo pacman -S --noconfirm", "pacman -Q"),
        "Debian": ("apt", "sudo apt -y install", "dpkg -s"),
        "openSUSE": ("zypper", "sudo zypper install -y", "rpm -q"),
        "Fedora": ("dnf", "sudo dnf -yq install", "rpm -q"),
    }

    if distro not in pkg_managers:
        error(f"Unsupported distribution: {distro}.")
        sys.exit(1)

    pkg_manager, install_cmd, check_cmd = pkg_managers[distro]

    pkg_var = f"REQUIRED_PKGS_{distro}"
    required_pkgs = required_pkgs_map.get(pkg_var)
    if not required_pkgs:
        error(f"{component} packages undefined for {distro}.")
        sys.exit(1)

    missing_pkgs = []
    for pkg in required_pkgs:
        try:
            subprocess.run(f"{check_cmd} {pkg}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        except subprocess.CalledProcessError:
            missing_pkgs.append(pkg)

    if not missing_pkgs:
        log(f"All required {component} packages already installed.")
        return

    warn(f"Missing required {component} packages: {' '.join(missing_pkgs)}")

    if yes_or_no(f"Install required missing {component} packages?"):
        log_file = Path(LOG_FILE)
        try:
            subprocess.run(f"{install_cmd} {' '.join(missing_pkgs)}", shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(f"Installed: {' '.join(missing_pkgs)}\n")
            log(f"Installed: {' '.join(missing_pkgs)}")
        except subprocess.CalledProcessError:
            error(f"Failed to install required {component} packages")
            sys.exit(1)
    else:
        log(f"Exiting due to required missing {component} packages.")
        sys.exit(1)
