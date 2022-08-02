#!/usr/bin/zsh

curl -H "Content-Type: application/json" \
	-H "Accept: application/json" -X POST \
	-H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0" \
	--data "$(jq --arg text "$(xclip -o -sel clip)" --null-input --compact-output  '{"text":$text, "autoReplace":true,"generateRecommendations":false,"generateSynonyms":false,"getCorrectionDetails":true,"interfaceLanguage":"en","language":"eng","locale":"Indifferent","origin":"interactive"}')" 'https://orthographe.reverso.net/api/v1/Spelling' \
	| jq '.text' | xargs echo -n | sed 's/\\n/\n/g' | xclip -sel clip | xdotool key ctrl+v

if $_; then;
    notify-send "Grammar corrected"
else
    notify-send "Failed to correct grammar"
fi
