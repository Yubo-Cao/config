#!/usr/bin/env bash
source common.sh

PROG="kitty"
APP_ID="dropdown"
ACTION=""

function extract() {
	jq --arg app_id "$APP_ID" \
		--arg term "$PROG" \
		"$@"
}

function tree() {
	wm-ipc -t get_tree
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
	$ACTION
}

function usage() {
	cat <<-END
		Usage: $(basename $0) [-t program] [-i app_id] [-h] -a action
			-t program: program to use for the action. default 'kitty'
			-i app_id: app_id to use for the action. default 'dropdown'
			-a action: action to perform. choose from:
				- init
				- toggle
				- destroy
				- status
				- usage
			-h: show this help message
	END
}

function parse() {
	while getopts 't:i:a:h' option "$@"; do
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
			init | toggle | status | destroy | usage)
				continue
				;;
			*)
				warning "Invalid action $ACTION"
				usage
				exit 1
				;;
			esac
			;;
		h)
			usage
			exit 0
			;;
		?)
			warning "Invalid option."
			usage
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
	tree | extract_windows | extract '[.[] | select(.app_id == $app_id)][1:] | .[].pid' | xargs -I pid kill pid
}

function init() {
	case $(status) in
	"multiple")
		more_than_one
		;;
	"uninitialized")
		$PROG --class "$APP_ID" --instance-group "$APP_ID" --detach
		until wm-ipc -t subscribe '["window"]' | grep -q '"change": "new"'; do
			sleep 0.1
		done
		toggle
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
		if [ "$(tree | extract_scratch | extract_windows | extract_ids | jq 'length')" -eq 1 ]; then
			echo "off"
		else
			echo "on"
		fi
	else
		echo "multiple"
	fi
}

function toggle() {
	case $(status) in
	"multiple")
		more_than_one
		;;
	"uninitialized")
		warning "'$PROG' haven't been created."
		init
		toggle
		;;
	"on")
		id="$(tree | extract_windows | extract_ids | extract '.[].id')"
		wm-ipc "[con_id=$id]" move window to scratchpad, \
			floating enable, \
			resize set width 1900 px height 400 px, \
			border pixel 1
		;;
	"off")
		id="$(tree | extract_scratch | extract_windows | extract_ids | extract '.[].id')"
		wm-ipc "[con_id=$id]" scratchpad show, \
			move position 10 px 0 px
		;;
	esac
}

function destroy() {
	case $(status) in
	"uninitialized")
		warning "'$PROG' haven't been created. Nothing is done."
		;;
	"on" | "off" | "multiple")
		tree | extract_windows | extract_ids | extract '.[].pid' | xargs -I pid kill pid
		;;
	esac
}

main "$@"
