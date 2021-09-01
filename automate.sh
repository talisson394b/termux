#! /usr/bin/env bash

function _Help() {
    cat <<EOF
automatize [-h] <functions[option]>
functions:
    volume <perfil>
        perfil: silent | pattern
    organize		Separa arquivos por tipo.
    whatstatus		Copia midias da pasta .Status.
    wiftimer <minutos>	Desativa o wifi.
    wallpaper		Plano de fundo aleatório
EOF
}


function _SendMsg() {
    local quiet_mode="false"
    if [[ $quiet_mode =~ "false" ]]; then
        local background="$1" msg="$2"
        termux-toast -b "$background" "$msg"
    fi
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


function SetWallpaper() {
    local gallery=$(_CreateDir "/sdcard/Pictures/Wall")
    local pictures=($(ls "$gallery/"*jpg))
    local random=$(shuf -i 0-${#pictures[@]} -n 1)
    
    if [[ ${#pictures[@]} -ne 0 ]]; then
        termux-wallpaper -f "${pictures[$random]}"
    fi
}


function Wiftimer() {
    pkill --full "sleep"

    local minute=$1 conn_state=""

    if [[ $minute -gt 0 && $minute -lt 120 ]]; then
	_SendMsg "#16a085" "Wiftimer: ${minute} min."
	{
	    sleep ${minute}m
	   
	    conn_state="$(termux-wifi-connectioninfo | \
           		grep  "supplicant_state" | \
            		cut -f2 -d: )"

    	    if [[ $conn_state =~ '"COMPLETED"' ]]; then
               _SendMsg "#c0392b" "Desconectando"
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
Pictures /sdcard/Pictures/ '.png' '.jpg' '.gif' '.webp'
Audio /sdcard/Music/ '.mp3' '.m4a' '.wma'
Video /sdcard/Movies/ '.mp4' '.mkv'
Document /sdcard/Documents/ '.pdf' '.html'
Trash /sdcard/Void.d/ '.apk'
EOF
)    
     for file in "$root"/*; do
	local ext=$(cut -f2 -d. <<< $(basename $file))
	local search=($(grep -E "[.]$ext" <<< $types))

	if [[ ${#search[@]} -gt 0 ]]; then
	    local target_dir=${search[1]}
	    mv -f "$file" "$target_dir"
	fi
     done
     _SendMsg "#16a085" "Organize: OK"
}


function VolumeCtrl() {
    streams=("call" "system" "ring" "music" "alarm" "notification")
    volume=()

    case $1 in
	"silent")	
	    volume=(0 0 0 0 0 0)
	    ;;
	"pattern")
	    volume=(3 4 4 5 4 4)
	    ;;
    esac

    local count=0
    for stream in ${streams[@]}; do
	termux-volume $stream ${volume[$count]}
	((count++))
    done
    unset streams
    unset volume
}



function Main() {
    local arguments=($@) count=1
    for arg in ${arguments[@]}; do
        case $arg in
	    "volume")
		VolumeCtrl ${arguments[$count]} 2> /dev/null;; 
	    "organize")
                 Organize;;
	    "whatstatus")
	         Whatstatus;;
	    "wiftimer")
		 Wiftimer ${arguments[$count]} 2> /dev/null;;
	    "wallpaper")
		 SetWallpaper;;
	    "-h")
		 _Help;;
	    *)
		continue;;
	 esac
	 ((count++))
    done	 
}


Main $@

