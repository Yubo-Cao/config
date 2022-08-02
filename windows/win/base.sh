#!/usr/bin/env bash

# Report error and exit.
# @param $1: error message
function error(){
    echo -e "\033[0;31mError: $1\033[0m"
    exit 1
}

function info(){
    echo -e "\033[0;33mInfo: $1\033[0m"
}

# Ensure File is downloaded. If not download it.
# @param $1: The file name
# @param $2: The website to download the ISO from

function ensure(){
    if [ ! \( -f "$1" \) ]; then
        echo "Please download $1."
        xdg-open "$2"
        read -rp "Enter the URL of the ISO file: " URL
        aria2c -c -s 16 -x 16 -d "$(pwd)" -o "$1" "$URL"
    fi
}