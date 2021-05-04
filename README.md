# GentooWSL-FS ![CI](https://github.com/imaandrew/GentooWSL-FS/workflows/CI/badge.svg)
Filesystem for GentooWSL

## Building
### Dependencies
The build script depends on curl, wget, xz-utils, sudo, and pv. Most of these should be already installed on your system. On Debian and Ubuntu, you can make sure all of the packages are installed by running `sudo apt install curl wget xz-utils sudo pv`

The rootfs file is automatically build every Sunday at 14:10 UTC. If you would like to build it for yourself, you can run ` bash build-x64.sh` on Ubuntu or Debian.

## Other stuff
The cpu.sh script is from [this](https://blechtog.wordpress.com/2012/12/02/gentoo-autoconfigure-number-of-cpu-in-make-conf/) site.
