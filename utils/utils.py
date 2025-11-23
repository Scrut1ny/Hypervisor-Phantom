#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import atexit
from datetime import datetime

# =============================================================================
# CONFIGURATION & CONSTANTS
# =============================================================================

class Colors:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    CYAN = "\033[36m"
    WHITE = "\033[37m"
    BRIGHT_RED = "\033[91m"
    BRIGHT_GREEN = "\033[92m"
    BRIGHT_YELLOW = "\033[93m"
    BRIGHT_CYAN = "\033[96m"
    BACK_BRIGHT_GREEN = "\033[102m"
    TEXT_BLACK = "\033[30m"

# Global state
LOG_FILE = None
_LOG_STREAM = None

# =============================================================================
# LOGGING & INITIALIZATION
# =============================================================================

def _close_log():
    """Cleanup function to close the log stream on exit."""
    global _LOG_STREAM
    if _LOG_STREAM:
        _LOG_STREAM.close()
        _LOG_STREAM = None

def init_logging(log_path=None):
    """Initialize logging with a persistent file handle."""
    global LOG_FILE, _LOG_STREAM

    # Only initialize once
    if _LOG_STREAM is not None:
        return

    if not log_path:
        log_path = os.getenv("LOG_PATH", os.path.join(os.getcwd(), "logs"))

    if not os.path.exists(log_path):
        try:
            os.makedirs(log_path)
        except OSError:
            sys.exit(1)

    if not LOG_FILE:
        filename = os.getenv("LOG_FILE", f"{int(time.time())}.log")
        LOG_FILE = os.path.join(log_path, filename)

    try:
        # Open file once with line buffering (buffering=1)
        _LOG_STREAM = open(LOG_FILE, 'a', encoding='utf-8', buffering=1)
        # Touch the file to ensure mtime is updated
        os.utime(LOG_FILE, None)
        # Register cleanup
        atexit.register(_close_log)
    except OSError:
        sys.exit(1)

def _write_log(message, plain_message=None, stream=sys.stdout):
    """Write to the global log stream and the specified output stream."""
    if _LOG_STREAM:
        timestamp = datetime.now().strftime("[%Y-%m-%d %H:%M:%S] ")
        # Use plain_message if provided, otherwise the formatted message (which might have ANSI codes)
        # Stripping ANSI codes here would be expensive, so we rely on caller providing plain_message
        content = plain_message if plain_message else message
        try:
            _LOG_STREAM.write(f"{timestamp}{content}\n")
        except ValueError:
            pass # Stream might be closed if called during shutdown

    print(message, file=stream)

# =============================================================================
# FORMATTER
# =============================================================================

def format_text(prefix, text, suffix="", styles=""):
    return f"{prefix}{styles}{text}{Colors.RESET}{suffix}"

def log(text):
    msg = format_text("\n  ", "[+]", f" {text}", Colors.BRIGHT_GREEN)
    _write_log(msg, plain_message=f"[LOG] {text}")

def info(text):
    msg = format_text("\n  ", "[i]", f" {text}", Colors.BRIGHT_CYAN)
    _write_log(msg, plain_message=f"[INFO] {text}")

def warn(text):
    msg = format_text("\n  ", "[!]", f" {text}", Colors.BRIGHT_YELLOW)
    _write_log(msg, plain_message=f"[WARN] {text}")

def error(text):
    msg = format_text("\n  ", "[-]", f" {text}", Colors.BRIGHT_RED)
    _write_log(msg, plain_message=f"[ERROR] {text}", stream=sys.stderr)

def fatal(text):
    msg = format_text("\n  ", f"[X] {text}", "", f"{Colors.RED}{Colors.BOLD}")
    _write_log(msg, plain_message=f"[FATAL] {text}", stream=sys.stderr)
    sys.exit(1)

def box_text(text):
    width = len(text) + 2
    top = f"\n  ╔{'═' * width}╗"
    middle = f"  ║ {text} ║"
    bottom = f"  ╚{'═' * width}╝"
    print(f"{top}\n{middle}\n{bottom}")

# =============================================================================
# PROMPTER
# =============================================================================

def ask_prompt(text):
    """Returns the stylized prompt string."""
    msg = format_text("\n  ", "[?]", f" {text}", f"{Colors.TEXT_BLACK}{Colors.BACK_BRIGHT_GREEN}")
    if _LOG_STREAM:
        try:
            _LOG_STREAM.write(f"\n[PROMPT] {text}\n")
        except ValueError:
            pass
    return msg

def yes_or_no(question):
    """
    Ask a yes/no question.
    Checks if 'question' starts with a newline (indicating it was formatted by ask_prompt)
    to avoid double formatting.
    """
    if not question.startswith("\n"):
         question = ask_prompt(question)

    while True:
        try:
            answer = input(f"{question} [y/n]: ").strip().lower()

            if _LOG_STREAM:
                try:
                    _LOG_STREAM.write(f"User Input: {answer}\n")
                except ValueError:
                    pass

            if answer.startswith('y'):
                return True
            elif answer.startswith('n'):
                return False
            else:
                print("\n  [!] Please answer y/n")
        except KeyboardInterrupt:
            print()
            return False

def quick_prompt(prompt_text):
    """Capture a single keypress."""
    import termios, tty
    print(prompt_text, end='', flush=True)
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(sys.stdin.fileno())
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    if ord(ch) == 3: # Ctrl+C
        print("^C")
        sys.exit(0)

    print(ch)
    if _LOG_STREAM:
        try:
            _LOG_STREAM.write(f"[QUICK_PROMPT] {prompt_text} -> {ch}\n")
        except ValueError:
            pass
    return ch

# =============================================================================
# PACKAGES
# =============================================================================

def install_req_pkgs(component, distro, required_pkgs):
    if not component:
        fatal("Component name not specified!")

    log(f"Checking for required missing {component} packages...")

    cmds = {
        "Arch": {"install": ["sudo", "pacman", "-S", "--noconfirm"], "check": ["pacman", "-Q"]},
        "Debian": {"install": ["sudo", "apt", "-y", "install"], "check": ["dpkg", "-s"]},
        "openSUSE": {"install": ["sudo", "zypper", "install", "-y"], "check": ["rpm", "-q"]},
        "Fedora": {"install": ["sudo", "dnf", "-yq", "install"], "check": ["rpm", "-q"]}
    }

    if distro not in cmds:
        error(f"Unsupported distribution: {distro}.")
        sys.exit(1)

    check_cmd = cmds[distro]["check"]
    install_cmd = cmds[distro]["install"]

    missing_pkgs = []

    # Optimization: We could batch check, but CLI behaviors differ.
    # Keeping sequential check for maximum reliability across distros.
    for pkg in required_pkgs:
        res = subprocess.run(check_cmd + [pkg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if res.returncode != 0:
            missing_pkgs.append(pkg)

    if not missing_pkgs:
        log(f"All required {component} packages already installed.")
        return True

    warn(f"Missing required {component} packages: {', '.join(missing_pkgs)}")

    if yes_or_no(f"Install required missing {component} packages?"):
        full_cmd = install_cmd + missing_pkgs
        try:
            # Use _LOG_STREAM for redirect if available, else DEVNULL to avoid crashing
            stderr_target = _LOG_STREAM if _LOG_STREAM else subprocess.DEVNULL
            subprocess.run(full_cmd, stdout=stderr_target, stderr=stderr_target, check=True)
            log(f"Installed: {', '.join(missing_pkgs)}")
        except subprocess.CalledProcessError:
            error(f"Failed to install required {component} packages")
            sys.exit(1)
    else:
        log(f"Exiting due to required missing {component} packages.")
        sys.exit(1)

# Initialize on import
init_logging()
