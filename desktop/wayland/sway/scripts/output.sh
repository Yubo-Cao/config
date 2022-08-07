#!/usr/bin/env bash
source common.sh

while true; do
	let outputCount=$(wm-ipc -t get_outputs | jq 'length')

	if [ "$outputCount" -eq 2 ]; then
		wm-ipc output "HDMI-A-2" pos 0 0, \
			output "eDP-1" pos 0 1080
	elif [ "$outputCount" -eq 1 ]; then
		wm-ipc output "eDP-1" pos 0 0
	else
		warning "Unsupported monitor layout"
		exit 1
	fi
	sleep 5
done
