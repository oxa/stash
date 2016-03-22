#!/bin/sh
set -x

switch=priv-0

if [ -n "$1" ];then
        ip link set $1 up
        sleep 0.5s
        brctl addif $switch $1
        exit 0
else
        echo "Error: no interface specified"
        exit 1
fi