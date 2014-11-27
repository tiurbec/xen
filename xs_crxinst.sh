#!/bin/sh
# xs_xinst.sh - Creates xlXXX.install file for Xen virtual machines
#		Part of createvm @ ExpertSoftware
#
#

if [ $# != 5 ]
then
   cat << EOF
xen virtual machine install file creator"

 Usage:
  $0 <domuHostname> <domuIP> <domuMAC> <domuXInstFilename> <domuKickStart>

EOF
   exit 1
fi

DUHOSTNAME=$1
DUIP=$2
DUMAC=$3
XINST=$4
XKS=$5

cat <<EOF > ./$XINST
name = "$DUHOSTNAME"
kernel = "/usr/local/xen/vmlinuz"
ramdisk = "/usr/local/xen/initrd.img"
extra = "root=/dev/xvda1 ip=$DUIP netmask=255.255.255.0 gateway=10.1.1.1 dns=8.8.8.8 text ks=http://10.1.1.10/$XKS"
memory = 1024
maxmem = 2048
vcpus = 2
vif = [ 'mac=$DUMAC, bridge=xenbr0' ]
disk = [ '/dev/vg0/$DUHOSTNAME,raw,xvda,rw' ]
on_reboot = 'destroy'
on_crash = 'destroy'
EOF
