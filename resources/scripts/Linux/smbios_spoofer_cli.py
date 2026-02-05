#!/usr/bin/env python3
from pathlib import Path
import re

OEM = b"To be filled by O.E.M."
HEX_PAT = re.compile(rb'^[0-9A-F]{8}$')

def get_bytes(path):
    try: return Path(path).read_bytes()
    except OSError: return b""

# 1. SMBIOS Tables Concatenation
data = get_bytes("/sys/firmware/dmi/tables/smbios_entry_point") + get_bytes("/sys/firmware/dmi/tables/DMI")

# 2. Overwrite Little-Endian UUID Bytes with 0xFF
if (u_txt := get_bytes("/sys/class/dmi/id/product_uuid").strip()):
    b = bytes.fromhex(u_txt.decode().replace("-", ""))
    data = data.replace(b[3::-1] + b[5:3:-1] + b[7:5:-1] + b[8:], b"\xFF" * 16)

# 3. Overwrite System Serial Strings with OEM Constant
for name in ("product_serial", "board_serial", "chassis_serial"):
    if (val := get_bytes(f"/sys/class/dmi/id/{name}").strip()) and val not in (b"Not Specified", OEM):
        data = data.replace(val, OEM)

# 4. Overwrite RAM Serial Strings with Null Bytes
ram_serials = {
    s for p in Path("/sys/firmware/dmi/entries/").glob("17-*/raw")
    for s in get_bytes(p)[2:].split(b'\x00')
    if HEX_PAT.match(s.upper())
}
for s in ram_serials:
    blank = b"\x00" * len(s)
    data = data.replace(s, blank).replace(s.lower(), blank)

if data:
    Path("smbios.bin").write_bytes(data)
