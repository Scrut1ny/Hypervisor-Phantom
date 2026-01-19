#!/bin/bash

# https://libvirt.org/formatdomain.html#input-devices
# https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev

# Keyboards: grab="all" grabToggle="shift-shift" repeat="on"
# Mice/Trackpads: grabToggle="shift-shift"
# evdev attributes: grab (all), repeat (on/off), grabToggle (ctrl-ctrl, alt-alt, shift-shift, meta-meta, scrolllock, ctrl-scrolllock)

grab_toggle="shift-shift"

shopt -s nullglob
declare -A seen_devices

for dev in /dev/input/by-{id,path}/*-event-{kbd,mouse}; do
  # Deduplicate by real path
  real_dev=$(readlink -f "$dev") || continue
  [[ -n "${seen_devices[$real_dev]}" ]] && continue
  seen_devices["$real_dev"]=1

  # Keyboard specific config
  extra_attrs=""
  [[ "$dev" == *"-event-kbd" ]] && extra_attrs=' grab="all" repeat="on"'

  printf '    <input type="evdev">\n      <source dev="%s" grabToggle="%s"%s/>\n    </input>\n' \
    "$dev" "$grab_toggle" "$extra_attrs"
done
