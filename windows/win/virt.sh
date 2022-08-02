WIN_ISO="win.iso"
VIRTIO_ISO="virtio-win.iso"
DISK="/dev/dm-0"

qemu-system-x86_64 \
    -machine q35,smm=on \
    -accel kvm \
    -device intel-iommu \
	-global driver=cfi.pflash01,property=secure,value=on \
	-global ICH9-LPC.disable_s3=1 \
	-drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/edk2-ovmf/x64/OVMF_CODE.secboot.fd `# secure boot` \
	-drive if=pflash,format=raw,unit=1,readonly=on,file=/usr/share/edk2-ovmf/x64/OVMF_VARS.fd \
	-device tpm-tis,tpmdev=tpm0 `# tpm 2.0` \
	-tpmdev passthrough,id=tpm0,path=/dev/tpm0,cancel-path=/home/yubo/config/windows/win/fake-cancel \
    -cpu host `# cpu passthrough` \
    -smp 4,cores=4 \
    -m 8192 `# 8G memory` \
    -vga std \
    -rtc base=localtime \
	-drive file="$DISK",format=raw,media=disk \
    -usb -device usb-tablet \
    -device virtio-net,netdev=nd0,mac=52:55:00:d1:55:01 \
    -netdev tap,id=nd0,br=winbr,helper=/usr/lib/qemu/qemu-bridge-helper,vhost=on \
    -nographic

# -cdrom "$WIN_ISO" -boot once=d `# installation media` \
# -drive file="$VIRTIO_ISO",media=cdrom \

# -blockdev node-name=q1,driver=raw,file.driver=host_device,file.filename=$DISK \
# -device virtio-blk,drive=q1

