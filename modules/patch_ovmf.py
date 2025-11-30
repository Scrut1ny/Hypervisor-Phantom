


















# ============================================================================
# BMP Validator
# ============================================================================

class BMPValidator:
    """Validates BMP image files"""

    @staticmethod
    def validate(bmp_path: Path) -> Optional[BMPInfo]:
        """Validate BMP file format and return info"""
        try:
            with open(bmp_path, "rb") as f:
                header = f.read(54)

                if len(header) < 54:
                    return None

                # Check BMP signature
                if header[0:2] != b'BM':
                    return None

                # Extract dimensions (little-endian)
                width = struct.unpack('<I', header[18:22])[0]
                height = struct.unpack('<I', header[22:26])[0]
                bit_depth = struct.unpack('<H', header[28:30])[0]
                compression = struct.unpack('<I', header[30:34])[0]

                # Validate constraints
                if bit_depth not in (1, 4, 8, 24):
                    return None
                if compression != 0:
                    return None
                if width > 65535 or height > 65535:
                    return None

                return BMPInfo(width=width, height=height, bit_depth=bit_depth, compression=compression)
        except (IOError, struct.error):
            return None
