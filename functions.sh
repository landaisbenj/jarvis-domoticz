#!/bin/bash

#Fonction pour commander un switch
pg_dz_switch () {
local api="http://${pg_dz_domoticz_ip}:${pg_dz_domoticz_port}/json.htm?type=command&param=switchlight&switchcmd=${1}"
pg_dz_idx $2
local idx=$?
if [ $idx != 0 ]; then
jv_curl "${api}&idx=${idx}"
say "$(pg_dz_lg "switch_$1" "$device")"
else
return 0
fi
}

#Fonction pour commander un volet
pg_dz_blind () {
local cmd=${1}
pg_dz_idx $2
local idx=$?
if [ $idx != 0 ]; then
pg_dz_is_blind_inverted $idx
local ivt=$?
if [ $ivt == 1 ]; then
[ "$cmd" == "On" ] && cmd="Off" || cmd="On"
fi
local api="http://${pg_dz_domoticz_ip}:${pg_dz_domoticz_port}/json.htm?type=command&param=switchlight&switchcmd=${cmd}"
jv_curl "${api}&idx=${idx}"
say "$(pg_dz_lg "blind_$1" "$device")"
else
return 0
fi
}

#Fonction pour demander l'etat d'un device
pg_dz_stat () {
local api="http://${pg_dz_domoticz_ip}:${pg_dz_domoticz_port}/json.htm?type=devices"
pg_dz_idx $1
local idx=$?
if [ $idx != 0 ]; then
local curl="$(pg_dz_st "$(curl -s "${api}&rid=${idx}" | jq -r '.result[0].Data')")"
say "$(pg_dz_lg "stat" "$device") $curl"
else
return 0
fi
}

#Fonction pour demander une temperature
pg_dz_temp () {
local api="http://${pg_dz_domoticz_ip}:${pg_dz_domoticz_port}/json.htm?type=devices"
pg_dz_idx $1
local idx=$?
if [ $idx != 0 ]; then
local curl="$(curl -s "${api}&rid=${idx}" | jq -r '.result[0].Data' | sed "s/C/degrés/g" | sed "s/%/% dhumidité/g")"
say "$(pg_dz_lg "temp" "$device") $curl"
else
return 0
fi
}

#Fonction de recuperation de l'idx, via les devices en favoris
pg_dz_idx () {
local pg_dz_device="$(curl -s "http://${pg_dz_domoticz_ip}:${pg_dz_domoticz_port}/json.htm?type=devices&used=true&filter=all&favorite=1")"
local -r order="$(jv_sanitize "$order")"
    while read device; do
        local sdevice="$(jv_sanitize "$device" ".*")"
		if [[ "$order" =~ .*$sdevice.* ]]; then
            local idx="$(echo $pg_dz_device | jq -r ".result[] | select(.Name==\"$device\") | .idx")"
			return $idx
        fi
    done <<< "$(echo $pg_dz_device | jq -r '.result[].Name')"
    say "$(pg_dz_lg "no_device_matching")"
    return 0

}

# Fonction volet inserse ?
pg_dz_is_blind_inverted() {
local api="$(curl -s "http://${pg_dz_domoticz_ip}:${pg_dz_domoticz_port}/json.htm?type=devices&rid=${1}" | jq -r '.result[].SwitchTypeVal')"
[ $api == 16 ] && return 1 || return 0
}
