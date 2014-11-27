#!/bin/sh
# xs_xrun.sh - 	Creates xlXXX.run file for Xen virtual machines
#		Part of createvm @ ExpertSoftware
#
#

if [ $# != 3 ]
then
   cat << EOF
xen virtual machine run file creator"

 Usage:
  $0 <domuHostname> <domuMAC> <domuXRunFilename>

EOF
   exit 1
fi

DUHOSTNAME=$1
DUMAC=$2
XRUN=$3

cat <<EOF > ./$XRUN
name = "$DUHOSTNAME"
kernel = "/usr/lib/xen/boot/pv-grub-x86_64.gz"
extra = "(hd0,0)/grub/menu.lst console=hvc0"
memory = 1024
maxmem = 2048
vcpus = 2
vif = [ 'mac=$DUMAC, bridge=xenbr0, vifname=vif.$DUHOSTNAME' ]
disk = [ '/dev/vg0/$DUHOSTNAME,raw,xvda,rw' ]
EOF



