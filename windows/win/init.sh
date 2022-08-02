#!/usr/bin/env bash
source ./base.sh
source ./devices.sh

WIN_ISO="$(pwd)/win.iso"
ensure "$WIN_ISO" "https://www.microsoft.com/software-download/windows11"
VIRTIO_ISO="$(pwd)/virtio-win.iso"
ensure "$VIRTIO_ISO" "https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md"

sudo umount /efi
sudo losetup --show -f ./mbr.bin
sudo virsh net-start win
cat table | sudo dmsetup create win

sudo setfacl -m u:yubo:rw /dev/tpm0
