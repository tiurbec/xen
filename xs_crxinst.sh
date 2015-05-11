#!/bin/sh
# xs_xinst.sh - Creates xlXXX.install file for Xen virtual machines
#		Part of createvm @ ExpertSoftware
#
#

if [ $# != 6 ]
then
   cat << EOF
xen virtual machine install file creator"

 Usage:
  $0 <domuHostname> <domuIP> <domuMAC> <domuXInstFilename> <domuKickStart> <vgName>

EOF
   exit 1
fi

DUHOSTNAME=$1
DUIP=$2
DUMAC=$3
XINST=$4
XKS=$5
VGNAME=$6

cat <<EOF > ./$XINST
name = "$DUHOSTNAME"
kernel = "/usr/local/xen/vmlinuz"
ramdisk = "/usr/local/xen/initrd.img"
extra = "root=/dev/xvda ip=$DUIP netmask=255.255.255.0 gateway=10.1.1.254 dns=8.8.8.8 text ks=http://144.76.106.136:800/$XKS"
memory = 2048 
maxmem = 2048
vcpus = 2
vif = [ 'mac=$DUMAC, bridge=xenbr0' ]
disk = [ '/dev/$VGNAME/$DUHOSTNAME-root,raw,xvda3,rw', 
 '/dev/$VGNAME/$DUHOSTNAME-boot,raw,xvda1,rw', 
 '/dev/$VGNAME/$DUHOSTNAME-swap,raw,xvda2,rw' ]
on_reboot = 'destroy'
on_crash = 'destroy'
EOF

