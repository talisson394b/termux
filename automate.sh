#! /usr/bin/env bash


function _SendMsg() {
    local background="$1" msg="$2"

    termux-toast -b "$background" "$msg"
}


function _CreateDir() {
    local dir="$1"

    if ! [[ -d $(dirname $dir) ]]; then
	dir="/sdcard/$(basename $dir)/"
    fi
    if ! [[ -d $dir ]]; then
	mkdir $dir
    fi
    echo -e "$dir"

}


function _Random() {
    local a=${1} b=${2}
    if [[ $a -lt $b ]]; then
	shuf -i  $a-$b -n 1
    fi
}


function SetWallpaper() {
    local GALLERY=$(_CreatDir "/sdcard/Pictures/Wall")
    [[ $(ls $GALLERY) =~ .*[.](png|jpg) ]]
    local pictures=(${BASH_REMATCH[@]})
    local pos=$(_Random 0 ${#pictures[@]})
    
    if [[ ${#pictures[@]} -ne 0 ]]; then
        termux-set-wallpaper "$GALLERY/${pictures[$pos]}"
    fi
}


function Wiftimer() {
    pkill --full "sleep"
    local minute="70"
 

    if [[ $minute -gt 0 && $minute -lt 120 ]]; then
	_SendMsg "#16a085" "Wiftimer: ${minute} min."
	{
	    sleep ${minute}m
	   
            conn_state="$(termux-wifi-connectioninfo | \ 
                grep "supplicant_state" | \
	        cut -f2 -d: )"

	    if [[ $conn_state =~ '"COMPLETED"' ]]; then
                _SendMsg "#e74c3c" "Desconectando"
	    fi
    
        } && termux-wifi-enable "false" &
    fi
}


function Whatstatus() {
    local origin="/sdcard/WhatsApp/Media/.Statuses"
    local backup=$(_CreateDir "/sdcard/WhatStatus")
    local count=0
    
    if [[ $(wc -l <<< $(ls $origin)) -gt 1 ]]; then
	for file in "$origin"/*; do
	    if ! [[ -e "$backup/$(basename $file)" ]]; then
                cp "$file" "$backup/"
		((count++))
	    fi
	done

    fi
    _SendMsg "#16a085" "WhatStatus: +$count"
}


function Organize() {
     local root="/sdcard/Download/"
     local types=$(cat <<EOF
Pictures /sdcard/Pictures/ '.png' '.jpg' '.gif'
Audio /sdcard/Music/ '.mp3' '.m4a' '.wma'
Video /sdcard/Movies/ '.mp4' '.mkv'
Document /sdcard/Documents/ '.pdf' '.html'
EOF
)    
     for file in "$root"/*; do
	local ext=$(cut -f2 -d. <<< $(basename $file))
	local search=($(grep -E "[.]$ext" <<< $types))

	if [[ ${#search[@]} -gt 0 ]]; then
	    local target_dir=${search[1]}
	    mv "$file" "$target_dir"
	fi
     done
     _SendMsg "#16a085" "Organize: OK"
}


function Main() {
    for arg in "$@"; do
        case $arg in
	    *"organize")
                 Organize;;
	    *"whatstatus")
	         Whatstatus;;
	    *"wiftimer")
		 Wiftimer;;
	    *"walppaper")
		 SetWallpaper;;
	    *)
		continue;;
	 esac
    done	 
}


Main $@

