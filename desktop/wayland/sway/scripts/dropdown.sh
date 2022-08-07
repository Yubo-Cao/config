#!/usr/bin/bash
set -e          # exit on error
set -u          # undefined variable is error
set -o pipefail # pipe is successsfully only if all commands inside are successful

PROG="kitty"
APP_ID="dropdown"
ACTION=""

function extract() {
	jq --arg app_id "$APP_ID" \
		--arg term "$PROG" \
		"$@"
}

function warning() {
	echo -e "\033[0;31m[ $(date '+%F %T') ]: $*\033[0m"
}

function tree() {
	swaymsg -t get_tree
}

function extract_windows() {
	extract '[ recurse(.["nodes", "floating_nodes"][])
	| select((.nodes? | length == 0) and
    (.type? as $type | $type == "con" or $type == "floating_con")) ]'
}

function extract_ids() {
	extract '[ .[] | select(.app_id == $app_id) ]'
}

function extract_scratch() {
	extract 'recurse(.nodes[]) | select(.name == "__i3_scratch")'
}

function main() {
	parse "$@"

	case $ACTION in
	init) init ;;
	toggle) toggle ;;
	esac
}

function parse() {
	while getopts 't:i:a:' option "$@"; do
		case $option in
		t)
			PROG="$OPTARG"
			;;
		i)
			APP_ID="$OPTARG"
			;;
		a)
			ACTION="$OPTARG"
			case $ACTION in
			init | toggle)
				continue
				;;
			*)
				warning "Invalid action $ACTION"
				exit 1
				;;
			esac
			;;
		?)
			warning "Invalid option."
			exit 1
			;;
		esac
	done

	if [ -z "$ACTION" ]; then
		warning "You must specify an action"
		exit 1
	fi
}

function more_than_one() {
	warning "More than one '$PROG' is found. Extras are killed."
	get_windows | extract '[.[] | select(.app_id == $app_id)][1:] | .pid' | xargs kill '{}'
}

function init() {
	case $(status) in
	"multiple")
		more_than_one
		;;
	"uninitialized")
		$PROG --class "$APP_ID" --instance-group "$APP_ID" --detach
		;;
	"off" | "on")
		warning "'$PROG' already created. Nothing is done."
		;;
	esac
}

function status() {
	local ids_count
	ids_count="$(tree | extract_windows | extract_ids | jq 'length')"

	if [ -z "$(pgrep "$PROG")" ] || [ "$ids_count" -eq 0 ]; then
		echo "uninitialized"
	elif [ "$ids_count" -eq 1 ]; then
		if [ "$(tree | extract_scratch | extract_ids | jq 'length')" -eq 1 ]; then
			echo "off"
		else
			echo "on"
		fi
	else
		echo "multiple"
	fi
}

function toggle() {
	local ids
	local pid
	ids="$(tree | extract_scratch | extract_windows | extract_ids)"

	if [ "$ids" = '[]' ]; then
		pid="$(tree | extract_windows | extract_ids | extract '.[].pid')"
		swaymsg "[pid=$pid]" move window to scratchpad
	else
		pid="$(echo "$ids" | extract '.[].pid')"
		swaymsg "[pid=$pid]" scratchpad show, \
			floating enable, \
			move position 10 px 0 px, \
			resize set width 1900 px height 400 px
	fi
}

main "$@"
