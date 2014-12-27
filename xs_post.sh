#!/bin/sh
# xs_post.sh - 	Post install tasks
#		Part of createvm @ ExpertSoftware
#
#

if [ $# != 10 ]
then
   cat << EOF
xen virtual machine post install tasks"

 Usage:
  $0 <dom0IP> <dom0sshPort> <domuXInst> <domuXRun> <roles> <domuID> <domuPGPort> <domUsshPort> <domUhostname> <dom0DefIf>

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
DUHOSTNAME=$9
HOSTDEFIF=${10}

HASPOSTGRES=0

APPS="postgres"

for app in $APPS; do
        if [[ "$ROLES" == *"$app"* ]]; then
                eval HAS${app^^}=1
        fi
done

ssh -p $HOSTSSHP root@$HOSTIP "xl create -c /etc/xen/$XINST"
ssh -p $HOSTSSHP root@$HOSTIP "xl create /etc/xen/$XRUN"
ssh -p $HOSTSSHP root@$HOSTIP "iptables -t nat -A PREROUTING -i $HOSTDEFIF -p tcp -m tcp --dport $DUSSHP -j DNAT --to-destination 10.1.1.$DUID:22"
if [ $HASPOSTGRES -eq 1 ]
then
   ssh -p $HOSTSSHP root@$HOSTIP "iptables -t nat -A PREROUTING -i $HOSTDEFIF -p tcp -m tcp --dport $DUPGPORT -j DNAT --to-destination 10.1.1.$DUID:5434"
fi
ssh -p $HOSTSSHP root@$HOSTIP "iptables-save > /etc/sysconfig/iptables"
ssh -p $HOSTSSHP root@$HOSTIP "ln -s /etc/xen/$XRUN /etc/xen/auto/$XRUN"

#Wait until DomU starts
while ! ssh -p $DUSSHP root@$HOSTIP "pwd"
do
    echo "Waiting for DomU to boot up..." >&2
done
ssh -p $DUSSHP root@$HOSTIP "iptables -F;iptables-save > /etc/sysconfig/iptables;chkconfig iptables off"
#Copy zabbix-agent files
scp -P $DUSSHP ./zabbix_agentd.conf.$DUHOSTNAME root@$HOSTIP:/etc/zabbix/zabbix_agentd.conf
if [ $HASPOSTGRES -eq 1 ]
then
   scp -P $DUSSHP ./files/zabbix-agent/postgres/etc/* root@$HOSTIP:/etc/zabbix/zabbix_agentd.d/
   scp -P $DUSSHP ./files/zabbix-agent/postgres/usr/* root@$HOSTIP:/usr/local/bin/
fi
ssh -p $DUSSHP root@$HOSTIP "service zabbix-agent restart"
