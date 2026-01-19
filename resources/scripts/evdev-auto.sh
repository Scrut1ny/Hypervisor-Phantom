#!/bin/bash

# Keyboards: grab="all" grabToggle="shift-shift" repeat="on"
# Mice/Trackpads: grabToggle="shift-shift"
# evdev attributes: grab (all), repeat (on/off), grabToggle (ctrl-ctrl, alt-alt, shift-shift, meta-meta, scrolllock, ctrl-scrolllock)

shopt -s nullglob

grab_toggle="shift-shift"

declare -A seen_devices
for dev in /dev/input/by-{id,path}/*-event-{kbd,mouse}; do
  real_dev=$(readlink -f -- "$dev")
  [[ ${seen_devices["$real_dev"]+x} ]] && continue
  seen_devices["$real_dev"]=1
  if [[ $dev == *-event-kbd ]]; then
    cat <<EOF
    <input type="evdev">
      <source dev="$dev" grab="all" grabToggle="$grab_toggle" repeat="on"/>
    </input>
EOF
  else
    cat <<EOF
    <input type="evdev">
      <source dev="$dev" grabToggle="$grab_toggle"/>
    </input>
EOF
  fi
done
