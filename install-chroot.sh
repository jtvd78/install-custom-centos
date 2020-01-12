
# Reinstall package managers and install base packages
yum install -y hostname
yum --releasever=8 install -y yum centos-release
yum install -y redhat-lsb-core dracut-tools dracut-squash dracut-network dracut-config-rescue dracut-config-generic # is dracut-squash, dracut-network, and dracut-config-generic necessary?

# Install kernel 
yum install -y kernel

# Bootloader

# How To Boot For now
# https://www.linux.com/tutorials/how-rescue-non-booting-grub-2-linux/

# TODO!
# https://www.dedoimedo.com/computers/grub2-fedora-command-not-found.html
# Install grub2-efi-modules

yum install -y grub2 grub2-efi efibootmgr

cat > /etc/default/grub << EOF
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto rd.auto consoleblank=0"
GRUB_DISABLE_RECOVERY="true"
EOF

efibootmgr -c -p 1 -d $DRIVE -L "Custom CentOS" -l "\EFI\centos\grubx64.efi"
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

## Network

yum install -y nmcli

# Enable networking
cat > "/etc/sysconfig/network" << EOF
NETWORKING=yes
NETWORKING_IPV6=no
EOF

# Configure each network device
mkdir -p /etc/sysconfig/network-scripts/

init_ifcfg() {
	if [ "$1" != "lo" ]; then
		cat > "/etc/sysconfig/network-scripts/ifcfg-${1}" << EOF
TYPE=Ethernet
BOOTPROTO=dhcp
PROXY_METHOD=none
BROWSER_ONLY=no
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
NAME=$1
DEVICE=$1
ONBOOT=yes
EOF
	fi
}

export -f init_ifcfg
cut -d: -f1 <(nmcli -t device) | xargs -n1 bash -c 'init_ifcfg "$@"' _

# Journald


# Something something autorelabel
touch /.autorelabel

# Fstab (see `blkid`)
EFI_UUID=$(blkid | grep "${DRIVE}1" | sed 's/^.*UUID="\(.*\)" T.*$/\1/')
BOOT_UUID=$(blkid | grep "${DRIVE}2" | sed 's/^.*UUID="\(.*\)" T.*$/\1/')
ROOT_UUID=$(blkid | grep "${DRIVE}3" | sed 's/^.*UUID="\(.*\)" T.*$/\1/')

cat > /etc/fstab << EOF
UUID=$EFI_UUID	/boot/efi	vfat	defaults	0	0
UUID=$BOOT_UUID	/boot		ext4	defaults	0	0
UUID=$ROOT_UUID	/		ext4	defaults	0	0
EOF

# Root password
passwd

# Time
rm /etc/localtime
ln -s /usr/share/zoneinfo/US/Eastern localtime

# Install custom packages
yum install -y vim tmux openssh

# Leave chroot
echo "Installtion complete."
echo "Perform any extra work necessary in chroot."
echo "Then, type 'exit' to complete installation outside of chroot. "