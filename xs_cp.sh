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


#Checking /usr/local/xen folder on Dom0
ssh -p $HOSTSSHP root@$HOSTIP "stat /usr/local/xen"
XRUNEXISTS=$?
if [ $XRUNEXISTS -ne 0 ]
then
   ssh -p $HOSTSSHP root@$HOSTIP "mkdir -p /usr/local/xen"
fi

#Checking /usr/local/xen/vmlinuz on Dom0
ssh -p $HOSTSSHP root@$HOSTIP "stat /usr/local/xen/vmlinuz"
XRUNEXISTS=$?
if [ $XRUNEXISTS -ne 0 ]
then
   scp -P $HOSTSSHP ./files/Dom0/vmlinuz root@$HOSTIP:/usr/local/xen/vmlinuz
fi

#Checking /usr/local/xen/initrd.img on Dom0
ssh -p $HOSTSSHP root@$HOSTIP "stat /usr/local/xen/initrd.img"
XRUNEXISTS=$?
if [ $XRUNEXISTS -ne 0 ]
then
   scp -P $HOSTSSHP ./files/Dom0/initrd.img root@$HOSTIP:/usr/local/xen/initrd.img
fi

cp -f ./$XKS /var/www/html/
scp -P $HOSTSSHP ./$XINST root@$HOSTIP:/etc/xen/$XINST
#XRUNEXISTS=`ssh -p $HOSTSSHP root@$HOSTIP "ls /etc/xen/$XRUN | wc -l"`
ssh -p $HOSTSSHP root@$HOSTIP "stat /etc/xen/$XRUN"
XRUNEXISTS=$?
if [ $XRUNEXISTS -eq 0 ]
then
   echo "$XRUN file is already on Dom0 at $HOSTIP. Are you sure you want to continue installing a new DomU there?"
   exit 20
   elif [ $XRUNEXISTS -eq 255 ]
   then
      echo "Error while connecting to $HOSTIP"
      exit 22
fi
scp -P $HOSTSSHP ./$XRUN root@$HOSTIP:/etc/xen/$XRUN

