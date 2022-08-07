#!/usr/bin/env bash
set -e
set -u
set -o pipefail

function warning() {
	echo -e "\033[0;31m[ $(date '+%F %T') ]: $*\033[0m"
}

case ${XDG_CURRENT_DESKTOP:=sway} in
sway)
	function wm-ipc() {
		swaymsg "$@"
	}
	session="wayland"
	;;
i3)
	function wm-ipc {
		i3-msg "$@"
	}
	session="xorg"
	;;
*)
	warning "Unsupported session ${XDG_CURRENT_DESKTOP}"
	exit 1
	;;
esac

export -f wm-ipc
export -f warning
export session
