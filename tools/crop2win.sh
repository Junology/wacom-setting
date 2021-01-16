#!/bin/bash

###
### crop2win.sh
### Restrict the area of stylus to the active window
###
### The script requires xdotool command.
###
### Copyright: Jun Yoshida, 2021
### License: CC0 (see LICENSE for details)


# Get device IDs of Wacom devices of a specific type.
function get_wacom_id {
    xsetwacom --list devices | grep "type: $1" | sed -e "s|^.*id:[[:space:]]*\([0-9]*\).*|\1|"
}

# Get active window area.
function get_actwin_area {
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
	xwininfo -id $(xdotool getactivewindow) |
		sed -n -e "s|^${s}Absolute upper-left X:${s}\([0-9]*\).*|\1|p" \
			-e "s|^${s}Absolute upper-left Y:${s}\([0-9]*\).*|\1|p" \
			-e "s|^${s}Width:${s}\([0-9]*\).*|\1|p" \
			-e "s|^${s}Height:${s}\([0-9]*\).*|\1|p"
}

# Get Wacom device area.
function get_wacom_area {
	xsetwacom --get $1 Area
}

# Get the first STYLUS device
dev_id=$(get_wacom_id "STYLUS" | awk '{print $1}')

# Reset the size.
xsetwacom --set $dev_id ResetArea

# Store geometries in variables.
eval $(echo $(get_actwin_area) | awk '{print "x="$1,"y="$2,"ww="$3,"wh="$4}')
eval $(get_wacom_area $dev_id | awk '{print "sw="$3,"sh="$4}')

# Make up a command setting Area property.
if [ $((sw*wh)) -gt $((ww*sh)) ]; then
	# h/w of window is larger than that of pad.
	echo "Use full height on PAD"
	cmdArea="xsetwacom --set $dev_id Area 0 0 $((sh*ww/wh)) $sh"
else
	# h/w of window is smaller than or equal to that of pad.
	echo "Use full width on PAD"
	cmdArea="xsetwacom --set $dev_id Area 0 0 $sw $((sw*wh/ww))"
fi

# Make up a command setting MapToOutput property.
cmdMTO="xsetwacom --set $dev_id MapToOutput ${ww}x${wh}+${x}+${y}"

# Run the commands
echo $cmdArea
eval $cmdArea
echo $cmdMTO
eval $cmdMTO
