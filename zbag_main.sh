#!/bin/sh
# xs_xks.sh - 	Creates zabbix_agentd.conf file for some linux host
#		Part of server management @ ExpertSoftware
#		We are assuming we already made ssh keys exchange
#

if [ $# != 3 ]
then
   cat << EOF
linux zabbix agent installer"

 Usage:
  $0 <ip> <sshPort>

EOF
   exit 1
fi

IP=$1
PORT=$2


#ip=ifconfig|xargs|awk '{print $7}'|sed -e 's/[a-z]*:/''/'
#cat /etc/redhat-release  | grep "CentOS release 6.6" | wc -l
cat <<EOF > ./$XZB
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
Include=/etc/zabbix/zabbix_agentd.d/*
LogFileSize=0
DebugLevel=2
SourceIP=$SIP
ServerActive=10.1.1.10
Hostname=$HOSTNAME
HostMetadata=$ROLES
ListenIP=$DUIP
RefreshActiveChecks=120
StartAgents=0
EOF
