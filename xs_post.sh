#!/bin/sh
# xs_post.sh - 	Post install tasks
#		Part of createvm @ ExpertSoftware
#
#

if [ $# != 8 ]
then
   cat << EOF
xen virtual machine post install tasks"

 Usage:
  $0 <dom0IP> <dom0sshPort> <domuXInst> <domuXRun> <roles> <domuID> <domuPGPort> <domUsshPort>

EOF
   exit 1
fi

HOSTIP=$1
HOSTSSHP=$2
XINST=$3
XRUN=$4
ROLES=$5
DUID=$6
DUPGPORT=$7
DUSSHP=$8

HASPOSTGRES=0

APPS="postgres"

for app in $APPS; do
        if [[ "$ROLES" == *"$app"* ]]; then
                eval HAS${app^^}=1
        fi
done

ssh -p $HOSTSSHP root@$HOSTIP "xl create -c /etc/xen/$XINST"
ssh -p $HOSTSSHP root@$HOSTIP "xl create /etc/xen/$XRUN"
ssh -p $HOSTSSHP root@$HOSTIP "iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport $DUSSHP -j DNAT --to-destination 10.1.1.$DUID:22"
if [ $HASPOSTGRES -eq 1 ]
then
   ssh -p $HOSTSSHP root@$HOSTIP "iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport $DUPGPORT -j DNAT --to-destination 10.1.1.$DUID:5434"
fi
ssh -p $HOSTSSHP root@$HOSTIP "iptables-save > /etc/sysconfig/iptables"
ssh -p $HOSTSSHP root@$HOSTIP "ln -s /etc/xen/$XRUN /etc/xen/auto/$XRUN"

