#!/usr/bin/env bash
rofi -m $(($(swaymsg -t get_outputs | jq '[.[].focused] | index(true)') + 1)) $@
