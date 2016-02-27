#!/bin/bash

cd /home/pi/freebox
# Domoticz server
DOMOTICZ_SERVER="192.168.0.31:8080"
# Freebox Server idx
FREEBOX_FW_IDX="92"
FREEBOX_UPTIME_IDX="93"
FREEBOX_UP_MAX_IDX="94"
FREEBOX_DOWN_MAX_IDX="95"
FREEBOX_DISKSPACE_IDX="96"
#
function show_time () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo "$day"%20jours%20"$hour"%20heures%20"$min"%20mn%20"$sec"%20secs
}

MY_APP_ID="Domoticz.app"
MY_APP_TOKEN="VPso1+xks2BNekGt7H7f8amMMkbfCbpNjiBl/SZWNRv/l96odu2ZOA+aKCR2Ohz6"

# source the freeboxos-bash-api
source ./freeboxos_bash_api.sh

# login
login_freebox "$MY_APP_ID" "$MY_APP_TOKEN"

# get xDSL data
answer=$(call_freebox_api '/connection/xdsl')
#echo " answer : ${answer} "
#echo " "
# extract max upload xDSL rate
up_max_rate=$(get_json_value_for_key "$answer" 'result.up.maxrate')%20kb/s
down_max_rate=$(get_json_value_for_key "$answer" 'result.down.maxrate')%20kb/s
uptime=$(get_json_value_for_key "$answer" 'result.status.uptime')
uptimefreebox=$(show_time ${uptime})
echo "Uptime : ${uptimefreebox} "

echo "Max Upload xDSL rate: ${up_max_rate} "
echo "Max Download xDSL rate: ${down_max_rate} "
answer=$(call_freebox_api '/system')
#echo " answer : ${answer} "
#uptimefreebox=$(get_json_value_for_key "$answer" 'result.uptime')
fwfreebox=$(get_json_value_for_key "$answer" 'result.firmware_version')
#echo "Uptime : ${uptimefreebox} "
echo "Firmware : ${fwfreebox} "
answer=$(call_freebox_api '/storage/disk')
answer=$(echo ${answer} | sed -e "s/\[//g" | sed -e "s/\]//g")
#echo " answer : ${answer} "
freediskspace=$(get_json_value_for_key "$answer" 'result.partitions.free_bytes')
freediskspace=$(echo $((${freediskspace}/1024/1024)))
freediskspace=$(echo "${freediskspace}%20MBytes")
echo "Free space HD : ${freediskspace} "
#
#Envoi des valeurs vers les devices virtuels
# Send data to Domoticz
curl --silent -s -i -H  "Accept: application/json"  "http://$DOMOTICZ_SERVER/json.htm?type=command&param=udevice&idx=$FREEBOX_FW_IDX&nvalue=0&svalue=$fwfreebox"
curl --silent -s -i -H  "Accept: application/json"  "http://$DOMOTICZ_SERVER/json.htm?type=command&param=udevice&idx=$FREEBOX_UPTIME_IDX&nvalue=0&svalue=$uptimefreebox"
curl --silent -s -i -H  "Accept: application/json"  "http://$DOMOTICZ_SERVER/json.htm?type=command&param=udevice&idx=$FREEBOX_UP_MAX_IDX&nvalue=0&svalue=$up_max_rate"
curl --silent -s -i -H  "Accept: application/json"  "http://$DOMOTICZ_SERVER/json.htm?type=command&param=udevice&idx=$FREEBOX_DOWN_MAX_IDX&nvalue=0&svalue=$down_max_rate"
curl --silent -s -i -H  "Accept: application/json"  "http://$DOMOTICZ_SERVER/json.htm?type=command&param=udevice&idx=$FREEBOX_DISKSPACE_IDX&nvalue=0&svalue=$freediskspace"


test
