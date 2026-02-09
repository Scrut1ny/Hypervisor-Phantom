#!/usr/bin/env python3
from pathlib import Path

def get_bytes(path):
    try: return Path(path).read_bytes()
    except OSError: return b""

# 1. Table concatenation
data = get_bytes("/sys/firmware/dmi/tables/smbios_entry_point") + get_bytes("/sys/firmware/dmi/tables/DMI")

# 2. Overwrite UUID bytes with 0xFF
if (u_txt := get_bytes("/sys/class/dmi/id/product_uuid").strip()):
    b = bytes.fromhex(u_txt.decode().replace("-", ""))
    data = data.replace(b[3::-1] + b[5:3:-1] + b[7:5:-1] + b[8:], b"\xFF" * 16)

# 3. Overwrite serial number strings with 0x00
for name in ("product_serial", "board_serial", "chassis_serial"):
    if val := get_bytes(f"/sys/class/dmi/id/{name}").strip():
        data = data.replace(val, b"To be filled by O.E.M.")

for p in Path("/sys/firmware/dmi/entries/").glob("17-*/raw"):
    for s in get_bytes(p)[2:].split(b'\x00'):
        if len(s) == 8 and s.isalnum() and not s.isalpha() and not s.isdigit():
            data = data.replace(s.lower(), b"00000000").replace(s.upper(), b"00000000")

if data:
    Path("smbios.bin").write_bytes(data)
