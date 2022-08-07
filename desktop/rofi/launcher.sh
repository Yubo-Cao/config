#!/usr/bin/env bash
case ${XDG_CURRENT_DESKTOP:-sway} in
sway)
	rofi -monitor "XWAYLAND$(swaymsg -t get_outputs | jq '[.[].focused] | index(true)')" "$@"
	;;
i3)
	rofi -monitor "$(i3-msg -t get_outputs | jq '.[] | select(.focused).name')" "$@"
	;;
esac
