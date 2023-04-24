qemu-system-x86_64 -enable-kvm -nographic\
 -kernel /root/work/gitkernel/linux/arch/x86/boot/bzImage\
 -m 32G -cpu host -smp cpus=16\
 -drive file=/home/vms/fedora/fedora_sda.qcow2,format=qcow2,if=none,id=drive0,cache=none\
 -device virtio-blk-pci,drive=drive0,id=drive0-dev,bootindex=1\
 -append 'root=/dev/vda2 console=ttyS0 earlyprintk=ttyS0' -vnc :19