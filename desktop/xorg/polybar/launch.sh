#!/usr/bin/env bash

killall -q polybar

while pgrep -u $UID -x polybar >/dev/null;
do
    sleep 1;
done

for monitor in $(polybar -m | cut -d ':' -f 1);
do
    MONITOR=$monitor polybar --reload main&
done
