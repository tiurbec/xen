#!/bin/sh
# xs_cp.sh - 	Copies files for Xen virtual machines
#		Part of createvm @ ExpertSoftware
#
#

if [ $# != 5 ]
then
   cat << EOF
xen virtual machine - tool that copies files"

 Usage:
  $0 <domuXInst> <domuXRun> <domuXKS> <dom0IP> <dom0sshPort>

EOF
   exit 1
fi

XINST=$1
XRUN=$2
XKS=$3
HOSTIP=$4
HOSTSSHP=$5

cp -f ./$XKS /var/www/html/
scp -P $HOSTSSHP ./$XINST root@$HOSTIP:/etc/xen/$XINST
XRUNEXISTS=`ssh -p $HOSTSSHP root@$HOSTIP "ls /etc/xen/$XRUN | wc -l"`
if [ $XRUNEXISTS -ne 0 ]
then
   echo "$XRUN file is already on Dom0 at $HOSTIP. Are you sure you want to continue installing a new DomU there?"
   exit 20
fi
scp -P $HOSTSSHP ./$XRUN root@$HOSTIP:/etc/xen/$XRUN

