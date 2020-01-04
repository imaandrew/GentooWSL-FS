sudo apt update -q
sudo apt install -y -q curl wget xz-utils sudo

chmod +x env.sh
. env.sh
mkdir rootfs
wget ${GTOO_URL}
sudo tar -xf ${TAR} -C rootfs
sudo cp -f wsl.conf rootfs/etc
sudo cp -f resolv.conf rootfs/etc
sudo cp -f make.conf rootfs/etc/portage
sudo cp -f cpu.sh rootfs

cd rootfs
sudo mount -t proc proc proc/
sudo mount --bind /sys sys
sudo chroot . sh cpu.sh
sudo chroot . mkdir --parents etc/portage/repos.conf
sudo chroot . cp usr/share/portage/config/repos.conf etc/portage/repos.conf/gentoo.conf
sudo chroot . emerge-webrsync
sudo chroot . emerge --oneshot -a n sys-devel/gcc

sudo chroot . emerge --oneshot -a n app-portage/mirrorselect
sudo chmod -R a+rw etc
sudo chroot . mirrorselect -s3 -o >> etc/portage/repos.conf/gentoo.conf
sudo chroot . emerge --oneshot --usepkg=n -a n sys-devel/libtool
sudo chroot . emerge --verbose --update --deep --newuse -a n @world
sudo mkdir etc/portage/profile
sudo chmod -R a+rw etc
sudo echo "sys-apps/portage -ipc" > etc/portage/profile/package.use.force
sudo echo 'ACCEPT_LICENSE="-* @FREE linux-fw-redistributable no-source-code"' >> etc/portage/make.conf

sudo chroot . emerge -a n app-admin/sudo
sudo chmod -R a+rw etc
sudo cp etc/sudoers ../sudoers
sudo chmod a+rw ../sudoers
sudo echo "%wheel ALL=(ALL) ALL" >> ../sudoers
sudo visudo -cf ../sudoers
sudo cp ../sudoers etc/sudoers
sudo chroot . emerge -a n app-shells/bash-completion
sudo chroot . echo 'en_US.UTF-8 UTF-8' >> etc/locale.gen
sudo chroot . locale-gen
sudo chmod -R a+rw etc
sudo chroot . echo 'LANG="en_US.UTF-8"' >> etc/env.d/02locale
sudo chroot . echo 'LC_COLLATE="C"' >> etc/env.d/02locale
sudo cp -f ../resolv.conf etc/
sudo chroot . chmod 755 -R etc/sudoers
sudo chroot . chmod 755 -R etc/sudoers.d

sudo chroot . emerge -a n net-misc/netifrc
sudo chroot . echo 'config_eth0="dhcp"' >> etc/conf.d/net
sudo chroot . emerge -a n net-misc/dhcpcd

sudo umount ./{sys,proc}
sudo tar -zcpf ../install.tar.gz *
sudo chown `id -un` ../install.tar.gz
sudo mkdir targz
sudo mv ../install.tar.gz targz
echo "Build has completed. install.tar.gz file located in the rootfs/targz directory."
