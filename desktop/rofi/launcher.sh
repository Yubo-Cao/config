#!/usr/bin/env bash
source common.sh

case $session in
wayland)
	rofi -monitor "XWAYLAND$(wm-ipc -t get_outputs | jq '[.[].focused] | index(true)')" "$@"
	;;
xorg)
	rofi -monitor "$(wm-ipc -t get_outputs | jq '.[] | select(.focused).name')" "$@"
	;;
esac
