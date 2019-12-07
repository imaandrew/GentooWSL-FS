#!/bin/bash

die()
{
    echo "$1" 1>&2
    exit 1
}

# check if running as root
check_sudo()
{
    if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root" 1>&2
       exit 1
    fi
}

# outputs number of CPU coress (with hyperthreading)
count_cpu() {
	grep -c processor /proc/cpuinfo || \
		 die "Error getting number of cpu"

}

# get location of make.conf
get_make() {
	if [ -e /etc/make.conf ]; then
		echo '/etc/make.conf'
	elif [ -e /etc/portage/make.conf ]; then
		echo '/etc/portage/make.conf'
	else
		die "make.conf not found"
	fi
}

# create a backup of make.conf in /tmp/make.conf.backup
backup_config() {
	local dest_path='/tmp/make.conf.backup'
	local now=$(date +'%Y%m%d%I%M%S')
	echo "Creating backup of make.conf in:"
	echo "${dest_path}/make.conf.${now}"
	mkdir -p "${dest_path}" || die "mkdir ${dest_path} failed"
	cp -a "$(get_make)" "${dest_path}/make.conf.${now}" \
		|| die "cp make.conf failed"
}

sed_make() {
	local countC=$(count_cpu)
	sed -i -r \
		-e "s/^([[:space:]]*MAKEOPTS=.*)(["\""'[[:space:]])(-j|--jobs=)[1-9][0-9]*(["\""'[[:space:]])/\1\2\3$(($countC+1))\4/" \
		-e "s/^([[:space:]]*MAKEOPTS=.*)(["\""'[[:space:]])(-l)[1-9][0-9]*\.?[0-9]*(["\""'[[:space:]])/\1\2\3$(($countC-1))\.95\4/" \
		-e "s/^([[:space:]]*EMERGE_DEFAULT_OPTS=.*)(["\""'[[:space:]])(-j|--jobs=)[1-9][0-9]*(["\""'[[:space:]])/\1\2\3${countC}\4/" \
		-e "s/^([[:space:]]*EMERGE_DEFAULT_OPTS=.*)(["\""'[[:space:]])(--load-average=)[1-9][0-9]*\.?[0-9]*(["\""'[[:space:]])/\1\2\3$(($countC-1))\.85\4/" \
		$(get_make) || die "sed on make.conf failed"
	echo "make.conf processed for ${countC} cpu"
}

# sanity checks
check_sudo
# check at least 2 cores
[ "$(count_cpu)" -lt 2 ] && die "Less than 2 CPUs detected!"

# create backup
backup_config

# modify make.conf
sed_make
