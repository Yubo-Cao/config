#!/usr/bin/bash
set -e          # exit on error
set -u          # undefined variable is error
set -o pipefail # pipe is successsfully only if all commands inside are successful

TERM="kitty"
APP_ID="dropdown"
ACTION=""

function extract() {
  jq --arg app_id "$APP_ID" \
    --arg term "$TERM" \
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

function extract_dropdowns() {
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
      TERM="$OPTARG"
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

function init() {
  local term_count
  term_count="$(tree | extract_windows | extract_dropdowns | jq 'length')"

  if [ "$term_count" -eq 0 ]; then
    $TERM --class "dropdown" --instance-group "dropdown" --detach
  elif [ "$term_count" -eq 1 ]; then
    warning "'$TERM' already created. Nothing is done."
  elif [ "$term_count" -gt 1 ]; then
    get_windows | extract '[.[] | select(.app_id == $app_id)][1:] | .pid' | xargs kill '{}'
    warning "More than one dropdown '$TERM' is found. Extras are killed."
  fi
}

function toggle() {
  local dropdown
  local pid
  dropdown="$(tree | extract_scratch | extract_windows | extract_dropdowns)"

  if [ "$dropdown" = '[]' ]; then
    pid="$(tree | extract_windows | extract_dropdowns | extract '.[].pid')"
    swaymsg "[pid=$pid]" move window to scratchpad
  else
    pid="$(echo "$dropdown" | extract '.[].pid')"
    swaymsg "[pid=$pid]" scratchpad show, \
      floating enable, \
      move position 10 px 0 px, \
      resize set width 1900 px height 400 px
  fi
}

main "$@"
