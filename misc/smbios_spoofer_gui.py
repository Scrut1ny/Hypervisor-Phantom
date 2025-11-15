#!/usr/bin/env python3
from pathlib import Path
import uuid
import re
import sys
from PyQt6.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QHBoxLayout, QWidget, QPushButton, QTextEdit, QLabel
from PyQt6.QtCore import QThread, pyqtSignal, Qt
from PyQt6.QtGui import QFont

HEX_PATTERN = re.compile(r'^[0-9A-F]{8}$')
DMI_SERIALS = "To be filled by O.E.M."
RAM_SERIAL = b"00000000"
SERIAL_PATHS = ("/sys/class/dmi/id/product_serial", "/sys/class/dmi/id/board_serial", "/sys/class/dmi/id/chassis_serial")
SMBIOS_FILES = ("/sys/firmware/dmi/tables/smbios_entry_point", "/sys/firmware/dmi/tables/DMI")

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

class SMBIOSWorker(QThread):
    log_signal = pyqtSignal(str)
    finished_signal = pyqtSignal(bool, str)

    def run(self):
        try:
            smbios_path = Path("smbios.bin")
            smbios_path.write_bytes(b"".join(
                d for f in SMBIOS_FILES if (d := self.safe_read(f))
            ))
            self.emit_log("[DUMP] ✓ Host SMBIOS tables dumped to smbios.bin")

            data = smbios_path.read_bytes()
            data = self.spoof_uuid(data)
            data = self.spoof_serials(data)
            data = self.spoof_ram_serials(data)

            if data != smbios_path.read_bytes():
                smbios_path.write_bytes(data)
                self.emit_log("[WRITE] ✓ Spoofed SMBIOS data written to smbios.bin")
            else:
                self.emit_log("[WRITE] ℹ No changes required")

            self.emit_log("[COMPLETE] ✓ SMBIOS dump and spoof completed successfully")
            self.finished_signal.emit(True, "Success")

        except Exception as e:
            self.emit_log(f"[ERROR] ✗ {str(e)}")
            self.finished_signal.emit(False, str(e))

    @staticmethod
    def safe_read(path: str) -> bytes | None:
        try:
            return Path(path).read_bytes()
        except OSError:
            return None

    def emit_log(self, msg: str):
        self.log_signal.emit(msg)

    def spoof_uuid(self, data: bytearray) -> bytearray:
        uuid_path = Path("/sys/class/dmi/id/product_uuid")
        if uuid_path.exists() and (uuid_val := uuid_path.read_text().strip()):
            try:
                new_uuid = str(uuid.uuid4())
                old_bytes = bytes.fromhex(to_smbios_uuid(uuid_val))
                new_bytes = bytes.fromhex(to_smbios_uuid(new_uuid))
                if (idx := data.find(old_bytes)) != -1:
                    data = data[:idx] + new_bytes + data[idx + len(old_bytes):]
                    self.emit_log(f"[SPOOF] ✓ product_uuid: \"{uuid_val}\" → \"{new_uuid}\"")
            except Exception as e:
                self.emit_log(f"[SPOOF] ⚠ product_uuid: skipped ({str(e)})")
        return data

    def spoof_serials(self, data: bytearray) -> bytearray:
        dmi_serials_encoded = DMI_SERIALS.encode("latin-1", errors="ignore")
        for serial_path in SERIAL_PATHS:
            if (fp := Path(serial_path)).exists() and (val := fp.read_text(errors="ignore").strip()):
                if val not in ("Not Specified", DMI_SERIALS) and (old := val.encode("latin-1", errors="ignore")) and old != dmi_serials_encoded:
                    data = data.replace(old, dmi_serials_encoded)
                    self.emit_log(f"[SPOOF] ✓ {fp.name}: \"{val}\" → \"{DMI_SERIALS}\"")
        return data

    def spoof_ram_serials(self, data: bytearray) -> bytearray:
        ram_serials = get_ram_serials()
        if ram_serials:
            for ram_serial in ram_serials:
                for encoded in (ram_serial.encode("ascii"), ram_serial.lower().encode("ascii")):
                    data = data.replace(encoded, RAM_SERIAL)
                self.emit_log(f"[SPOOF] ✓ memory_serial: \"{ram_serial}\" → \"{RAM_SERIAL.decode('ascii')}\"")
        else:
            self.emit_log("[SPOOF] ℹ memory_serial: no serials found")
        return data

class SMBIOSApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.worker = None
        self.setup_ui()

    def setup_ui(self):
        self.setWindowTitle("SMBIOS Dumper & Spoofer")
        self.setGeometry(100, 100, 500, 360)

        main_widget = QWidget()
        self.setCentralWidget(main_widget)

        layout = QVBoxLayout(main_widget)
        layout.setContentsMargins(10, 10, 10, 10)
        layout.setSpacing(8)

        self.log_text = QTextEdit()
        self.log_text.setReadOnly(True)
        self.log_text.setFont(QFont("Courier", 8))
        self.log_text.setPlaceholderText("Log:")
        layout.addWidget(self.log_text)

        button_layout = QHBoxLayout()
        button_layout.setSpacing(6)

        self.run_button = QPushButton("Dump + Spoof")
        self.run_button.setFixedHeight(32)
        self.run_button.clicked.connect(self.run_spoof)
        button_layout.addWidget(self.run_button)

        self.clear_button = QPushButton("Clear Log")
        self.clear_button.setFixedHeight(32)
        self.clear_button.clicked.connect(self.log_text.clear)
        button_layout.addWidget(self.clear_button)

        layout.addLayout(button_layout)

        # Footer with credits
        credits_label = QLabel(
            'Developed by <a href="https://github.com/Scrut1ny" style="color: #0d47a1; text-decoration: none;">Scrut1ny</a> | '
            '<a href="https://github.com/Scrut1ny/Hypervisor-Phantom" style="color: #0d47a1; text-decoration: none;">Project Repository</a>'
        )
        credits_label.setOpenExternalLinks(True)
        credits_font = QFont()
        credits_font.setPointSize(8)
        credits_label.setFont(credits_font)
        credits_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(credits_label)

        self.setStyleSheet("""
            QMainWindow, QWidget { background-color: #1e1e1e; color: #ffffff; }
            QTextEdit {
                background-color: #2d2d2d; color: #e0e0e0;
                border: 1px solid #3d3d3d; border-radius: 4px; padding: 5px;
            }
            QTextEdit::placeholder { color: #555555; }
            QPushButton {
                background-color: #0d47a1; color: #ffffff;
                border: none; border-radius: 4px; padding: 6px; font-weight: bold;
            }
            QPushButton:hover { background-color: #1565c0; }
            QPushButton:pressed { background-color: #0d3a8f; }
            QPushButton:disabled { background-color: #555555; color: #888888; }
            QLabel { color: #888888; }
        """)

    def run_spoof(self):
        self.run_button.setEnabled(False)
        self.log_text.append("="*50)

        self.worker = SMBIOSWorker()
        self.worker.log_signal.connect(self.log_text.append)
        self.worker.finished_signal.connect(lambda s, m: self.run_button.setEnabled(True))
        self.worker.start()

def main():
    app = QApplication(sys.argv)
    window = SMBIOSApp()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
