#!/bin/sh
# xs_xks.sh - 	Creates zabbix_agentd.conf file for Xen virtual machines
#		Part of createvm @ ExpertSoftware
#
#

if [ $# != 3 ]
then
   cat << EOF
xen virtual machine zabbix_agent.conf file creator"

 Usage:
  $0 <domuHostname> <domuIP> <roles>

EOF
   exit 1
fi

DUHOSTNAME=$1
DUIP=$2
ROLES=$3
XZB="zabbix_agentd.conf.$DUHOSTNAME"
APPS="nginx pgbouncer postgres php"

for app in $APPS; do
        if [[ "$ROLES" == *"$app"* ]]; then
                eval HAS${app^^}=1
        fi
done

cat <<EOF > ./$XZB
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
Include=/etc/zabbix/zabbix_agentd.d/*
LogFileSize=0
DebugLevel=2
SourceIP=$DUIP
ServerActive=moni.easy-cloud.net
Hostname=$DUHOSTNAME
HostMetadata=$ROLES,VirtualHost
#ListenIP=$DUIP
RefreshActiveChecks=120
StartAgents=0
EOF
