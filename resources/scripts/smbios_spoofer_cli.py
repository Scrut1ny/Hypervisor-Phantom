#!/usr/bin/env python3
from pathlib import Path
import uuid
import re

HEX_PATTERN  = re.compile(r'^[0-9A-F]{8}$')
DMI_SERIALS  = "To be filled by O.E.M."
RAM_SERIAL   = b"00000000"
SERIAL_PATHS = ("/sys/class/dmi/id/product_serial", "/sys/class/dmi/id/board_serial", "/sys/class/dmi/id/chassis_serial")

def get_ram_serials():
    return [
        s for p in Path("/sys/firmware/dmi/entries/").glob("17-*/raw")
        if (raw := p.read_text(errors='ignore'))
        for s in raw[2:].split('\x00')
        if s and HEX_PATTERN.match(s.upper())
    ]

def to_smbios_uuid(u: str) -> str:
    u = u.replace("-", "")
    return "".join(u[i:i + 2] for i in (6, 4, 2, 0, 10, 8, 14, 12)) + u[16:]

def safe_read(path: str) -> bytes | None:
    try:
        return Path(path).read_bytes()
    except OSError:
        return None

# Combine SMBIOS tables
smbios_path = Path("smbios.bin")
smbios_path.write_bytes(b"".join(
    d for f in ("/sys/firmware/dmi/tables/smbios_entry_point", "/sys/firmware/dmi/tables/DMI")
    if (d := safe_read(f))
))

data = smbios_path.read_bytes()

# Replace UUID if exists
if (uuid_path := Path("/sys/class/dmi/id/product_uuid")).exists() and (uuid_val := uuid_path.read_text().strip()):
    try:
        old_bytes = bytes.fromhex(to_smbios_uuid(uuid_val))
        new_bytes = b"\xFF" * 16  # SMBIOS UUID = all 00h (ID not present)

        if (idx := data.find(old_bytes)) != -1:
            data = data[:idx] + new_bytes + data[idx + len(old_bytes):]
    except Exception:
        pass

# Replace serial numbers
spoofer_encoded = DMI_SERIALS.encode("latin-1", errors="ignore")
for serial_path in SERIAL_PATHS:
    if (fp := Path(serial_path)).exists() and (val := fp.read_text(errors="ignore").strip()):
        if val not in ("Not Specified", DMI_SERIALS) and (old := val.encode("latin-1", errors="ignore")) and old != spoofer_encoded:
            data = data.replace(old, spoofer_encoded)

# Replace RAM serials
for ram_serial in get_ram_serials():
    for encoded in (ram_serial.encode("ascii"), ram_serial.lower().encode("ascii")):
        data = data.replace(encoded, RAM_SERIAL)

# Write if changed
if data != smbios_path.read_bytes():
    smbios_path.write_bytes(data)
