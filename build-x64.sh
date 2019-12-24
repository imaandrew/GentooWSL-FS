sudo apt update -q
sudo apt install -y -q curl wget xz-utils sudo

source ./env.sh
mkdir rootfs
wget ${GTOO_URL}
sudo tar -xf ${TAR} -C rootfs
sudo cp -f wsl.conf rootfs/etc
sudo cp -f resolv.conf rootfs/etc
sudo cp -f make.conf rootfs/etc/portage
sudo cp -f cpu.sh rootfs

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
sudo chroot . emerge -a n sys-kernel/gentoo-sources

sudo chroot . emerge -a n sys-kernel/genkernel
sudo chroot . genkernel all
sudo chroot . emerge -a n sys-kernel/linux-firmware

sudo umount ./{sys,proc}
sudo tar -zcpf ../install.tar.gz *
sudo chown `id -un` ../install.tar.gz
sudo mkdir targz
sudo mv ../install.tar.gz targz
echo "Build has completed. install.tar.gz file located in the rootfs/targz directory."
