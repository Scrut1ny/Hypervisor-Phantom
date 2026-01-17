BDF="0000:01:00.0"
DEV="/sys/bus/pci/devices/$BDF"
OUT="./VBIOS_${BDF}.rom"

# Identify current driver (save it before unbinding)
DRIVER_PATH="$(readlink "$DEV/driver" 2>/dev/null || true)"
DRIVER_NAME="${DRIVER_PATH##*/}"

# Unbind only if a driver is currently bound
if [[ -n "$DRIVER_NAME" ]]; then
  echo "$BDF" | sudo tee "$DEV/driver/unbind" > /dev/null
fi

# Enable ROM read, dump, disable
echo 1 | sudo tee "$DEV/rom" > /dev/null
sudo cat "$DEV/rom" > "$OUT"
echo 0 | sudo tee "$DEV/rom" > /dev/null

# Rebind only if we had a driver
if [[ -n "$DRIVER_NAME" ]]; then
  echo "$BDF" | sudo tee "/sys/bus/pci/drivers/$DRIVER_NAME/bind" > /dev/null
fi
