#!/usr/bin/env bash
source ./base.sh

# Determine if a device mappered disk exists.
# Return 0 if exists, 1 if not.
function disk_created() {
    [ "$(dmsetup ls | rg "^$1\s+")" ]
    return $?
}

# Create a new device mappered disk from a disk partition. Print the device name.
# @param $1: The partition to create the new device mappered disk from
# @param $2: The name of the new device mappered disk
# @param $3: The location of MBR. If not specified, the default location will be used,
#           which is /home/yubo/config/win/mbr.bin

function create_disk(){
    # Parse the arguments
    local partition="$1"
    local name="$2"
    local mbr_path=${3:-'/home/yubo/config/win/mbr.bin'}

    if $(disk_created "$name"); then
		get_dev "$name"
        return 0
    fi

    dd if=/dev/zero of=$mbr_path count=2048  || error "Failed to create MBR"
    local loop="$(losetup --show -f $mbr_path)"
    local partsize="$(blockdev --getsz $partition)"

	dmsetup create $name <<- EOF || error "Unable to set up device"
	0 	    2048 		linear $loop 	0
	2048 	$partsize 	linear $partition 	0
	EOF

	get_dev "$name"
    return 0
}

function get_dev(){
	local name=$1

	local cmd="if (\$_ =~ /^$name\\s*\\((\\d+:\\d+)\\)/) {print \"/sys/dev/block/\$1\"}"
    local devname=$(dmsetup ls | perl -nle "$cmd" | xargs udevadm info -rq name) \
    || error "Unable to get the device name"
	echo $devname
}


# Delete a device mappered disk.
# @param $1: The name of the device mappered disk

function delete_disk(){
    # Parse the arguments
    local name="$1"

    if [ ! $(disk_created $name) ]; then
        info "Disk does not exists"
    fi

    dmsetup remove $name || error "Unable to remove device"
    losetup -d $loop || error "Unable to remove loop device"
    return 0
}


# Create a bridge
# @param $1: The name of the bridge

function create_bridge(){
    chmod 755 /etc/qemu/bridge.conf
    chown root:root /etc/qemu/bridge.conf

    $BRIDGE="$1"

    if [ "$(rg 'winbr' /etc/qemu/bridge.conf)" ]; then
        echo "Bridge already exists in config"
    else
        echo "allow $BRIDGE" >> /etc/qemu/bridge.conf
    fi

    if [ $(ip --json link show | jq 'map(.["ifname"] == "winbr") | any') = 'true' ]; then
        echo "Bridge already exists in system"
    else
        ip link add name winbr type bridge
        ip link set winbr up
    fi
}

