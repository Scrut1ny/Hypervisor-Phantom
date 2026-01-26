import os, struct, sys

RANGES = [
    (0x40000000, 0x400000FF, "Hyper-V Synthetic"),
    (0x4B564D00, 0x4B564DFF, "KVM-specific"),
]

RED, RESET = "\033[91m", "\033[0m"

if os.geteuid() != 0: sys.exit("UID!=0")

try:
    fd = os.open("/dev/cpu/0/msr", os.O_RDONLY)

    for start, end, label in RANGES:
        print(f"Scanning MSR range: {hex(start)} - {hex(end)} [{label}]")
        for msr in range(start, end + 1):
            try:
                os.lseek(fd, msr, os.SEEK_SET)
                val = struct.unpack('Q', os.read(fd, 8))[0]
                print(f"{RED}[!] DETECTED: {hex(msr)} = {hex(val)}{RESET}")
            except OSError: continue

    os.close(fd)
except Exception as e:
    sys.exit(f"Err: {e}")
