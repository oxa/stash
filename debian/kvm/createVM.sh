#!/bin/sh

brctl addbr br0
brctl addbr priv0

brctl addif br0 eth1

qemu-img create -f qcow2 apline.img 2G
qemu-img create -f qcow2 alpine2.img 2G


qemu-system-x86_64 -hda apline.img -cdrom alpine/alpine-3.3.2-x86.iso -boot d -m 256 -vnc :1 -device e1000,netdev=net0 -netdev tap,id=net0,script=/home/cisco/qemu-ifup -device e1000,netdev=net1 -netdev tap,id=net1,script=/home/cisco/qemu-priv  &

qemu-system-x86_64 -hda apline.img -cdrom alpine/alpine-3.3.2-x86.iso -boot d -m 256 -vnc :1 -device e1000,netdev=net0 -netdev tap,id=net0,script=/home/cisco/qemu-ifup -device e1000,netdev=net1 -netdev tap,id=net1,script=/home/cisco/qemu-priv &