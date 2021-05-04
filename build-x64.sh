# Setup environment and download files
chmod +x env.sh
. env.sh
mkdir rootfs
wget ${GTOO_URL}
sudo tar -xpf ${TAR} -C rootfs --xattrs-include='*.*' --numeric-owner
cd rootfs
sudo cp -f ../wsl.conf ./etc
sudo cp -f ../make.conf ./etc/portage
sudo cp -f ../cpu.sh ./

# Mount directories and setup chroot
sudo mount --types proc /proc ./proc
sudo mount --rbind /sys ./sys
sudo mount --make-rslave ./sys
sudo mount --rbind /dev ./dev
sudo mount --make-rslave ./dev
sudo rm -rf /dev/shm
sudo mkdir /dev/shm
sudo mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm
sudo chmod 1777 /dev/shm
sudo mount --rbind /dev/shm/ ./dev/shm
sudo chmod 1777 ./dev/shm/
sudo chroot . sh cpu.sh
sudo chroot . mkdir --parents ./etc/portage/repos.conf
sudo chroot . cp ./usr/share/portage/config/repos.conf ./etc/portage/repos.conf/gentoo.conf
sudo chroot . emerge-webrsync

# More portage stuff
sudo chroot . emerge --update --deep --with-bdeps=y --newuse @world
sudo chroot . emerge -a n app-portage/mirrorselect
echo 'ACCEPT_LICENSE="-* @FREE linux-fw-redistributable no-source-code"' | sudo tee -a ./etc/portage/make.conf
sudo chroot . mirrorselect -s3 -b10 -D

# Sudo n stuff
sudo chroot . emerge -a n app-admin/sudo app-shells/bash-completion
sudo sed -i -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' ./etc/sudoers
sudo sed -i -e 's/pam_unix.so try_first_pass use_authtok nullok sha512 shadow/pam_unix.so nullok sha512 shadow/' ./etc/pam.d/system-auth
sudo sed -ie "s/\(.*passwdqc.*\)/#\1/" ./etc/pam.d/system-auth

# Locale stuff
echo 'en_US.UTF-8 UTF-8' | sudo tee -a ./etc/locale.gen
sudo chroot . locale-gen
sudo sed -i -e 's/C.UTF8/"en_US.UTF-8"/' ./etc/env.d/02locale
echo 'LC_COLLATE="C"' | sudo tee -a ./etc/env.d/02locale

# Setup custom gentoo overlay
sudo chroot . emerge -a n app-portage/layman
sudo sed -i '/^#/!s/check_official .*/check_official : No/' ./etc/layman/layman.cfg
sudo chroot . layman -o https://raw.githubusercontent.com/imaandrew/gentoowsl-overlay/master/repositories.xml -f -a gentoowsl
sudo chroot . layman-updater -R
sudo chroot . emerge -a n sys-apps/wslu sys-process/cronie
sudo chroot . rc-update add cronie default

# Network things
sudo chroot . emerge -a n net-misc/netifrc net-misc/dhcpcd net-misc/iputils
echo 'config_eth0="dhcp"' | sudo tee -a ./etc/conf.d/net

# Unmount and compress rootfs
sudo rm -rf ./var/cache/distfiles/*
sudo umount -Rq ./{sys,proc,dev}
sudo tar -zcpf ../rootfs.tar.gz *
sudo chown $(id -un) ../rootfs.tar.gz
mkdir ../out
mv ../rootfs.tar.gz ../out
echo "Build has completed. rootfs.tar.gz file located in the out directory."
