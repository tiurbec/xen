#!/bin/sh
# zbag_main.sh -	Installs zabbix agent on remote servers
#			Part of server management @ ExpertSoftware
#			We are assuming we already made ssh keys exchange
#
set -x
if [ $# != 3 ]
then
   cat << EOF
linux zabbix agent installer"

 Usage:
  $0 <ip> <sshPort> <roles>

EOF
   exit 1
fi

IP=$1
PORT=$2
ROLES=$3
MYPUBIP=`curl -s checkip.dyndns.org | sed "s/.*Current IP Address: //" | sed "s/<.*$//"`
MYGW=$(ip route | awk '/default/ {print $3}')
SSHOK=0
SAMEIP=0
OS="unknown"

APPS="nginx pgbouncer postgres php"

for app in $APPS; do
        if [[ "$ROLES" == *"$app"* ]]; then
                eval HAS${app^^}=1
        fi
done

#
if [ "$IP" == "$MYPUBIP" ];
then
   #It seems we are under the same ip
   SAMEIP=1
fi

ssh -p $PORT root@$IP pwd
if [ $? -ne 255 ];
then
   #Connection was ok
   SSHOK=1
   elif [ $SAMEIP -eq 1 ];
   then
      ssh -p 22 root@$MYGW "pwd"
      if [ $? -ne 255 ];
      then
	PORT=22
	IP=$MYGW
      else
	echo "No more ssh options!!!"
        exit 22
      fi
fi

echo "Using $IP:$PORT"

RETSTR=$(ssh -p $PORT root@$IP 'cat /etc/redhat-release  | grep "CentOS release 6.6" | wc -l')
if [ $RETSTR -eq 1 ];
then
   OS="centos_66"
   SOURCEIP=$(ssh -p $PORT root@$IP "ifconfig eth0|grep inet|grep -v inet6|awk '{print \$2}'|sed 's/addr://'")
fi
RETSTR=$(ssh -p $PORT root@$IP 'cat /etc/SDE-VERSION  | grep "OpenSDE master" | wc -l')
if [ $RETSTR -eq 1 ];
then
   OS="opensde"
   SOURCEIP=$(ssh -p $PORT root@IP "ifconfig dummy0|grep inet|grep -v inet6|awk '{print \$2}'|sed 's/addr://'")
fi

if [ "$OS" == "centos_66" ];
then
  ssh -p $PORT root@$IP 'rpm -Uvh "http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm"'
  ssh -p $PORT root@$IP 'yum -y install zabbix-agent'
  ssh -p $PORT root@$IP 'chkconfig zabbix-agent on'
cat <<EOF | ssh -p $PORT root@$IP 'cat > /etc/zabbix/zabbix_agentd.conf'
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
DebugLevel=2
SourceIP=$SOURCEIP
ServerActive=144.76.106.136
HostnameItem=system.hostname
HostMetadata=$ROLES
#ListenIP=$SOURCEIP
RefreshActiveChecks=120
StartAgents=0
EOF
#| ssh -p $PORT root@$IP 'cat > /etc/zabbix/zabbix_agentd.conf'
  ssh -p $PORT root@$IP 'service  zabbix-agent restart'
fi

if [ "$OS" == "opensde" ];
then
   ssh -p $PORT root@$IP 'useradd zabbix'
   ssh -p $PORT root@$IP 'chsh -s /bin/false zabbix'
   ssh -p $PORT root@$IP 'cd ~zabbix;lftpget http://www.zabbix.com/downloads/2.4.1/zabbix_agents_2.4.1.linux2_6.amd64.tar.gz;tar xvfz zabbix_agents_2.4.1.linux2_6.amd64.tar.gz'
cat <<EOF | ssh -p $PORT root@$IP 'cat > /home/zabbix/conf/zabbix_agentd.conf'
PidFile=/home/zabbix/zabbix_agentd.pid
LogFile=/home/zabbix/zabbix_agentd.log
LogFileSize=0
DebugLevel=2
SourceIP=$SOURCEIP
ServerActive=144.76.106.136
HostnameItem=system.hostname
HostMetadata=$ROLES
#ListenIP=$SOURCEIP
RefreshActiveChecks=120
StartAgents=0
EOF
#   ssh -p $PORT root@$IP 'mkdir /etc/zabbix_agent'
#   ssh -p $PORT root@$IP 'echo "#!/bin/sh">/etc/zabbix_agent/run'
#   ssh -p $PORT root@$IP 'echo "/home/zabbix/sbin/zabbix_agentd -c /home/zabbix/conf/zabbix_agentd.conf">>/etc/zabbix_agent/run'
#   ssh -p $PORT root@$IP 'chmod +x /etc/zabbix/zabbix_agent/run'
#   ssh -p $PORT root@$IP 'mkdir -p /var/log/zabbix'
#   ssh -p $PORT root@$IP 'chown zabbix.root /var/log/zabbix/'
#   ssh -p $PORT root@$IP 'mkdir -p /var/run/zabbix;chown zabbix.root /var/run/zabbix'
#   ssh -p $PORT root@$IP 'ln -s /etc/zabbix_agent/ /var/service/'
#   ssh -p $PORT root@$IP 'sv up /var/service/zabbix_agent'
cat <<'EOF' | ssh -p $PORT root@$IP 'cat > /etc/init.d/zabbix_agentd
title() {
	local x w="$( stty size 2>/dev/null </dev/tty | cut -d" " -f2  )"
	[ -z "$w" ] && w="$( stty size </dev/console | cut -d" " -f2  )"
	for (( x=1; x<w; x++ )) do echo -n .; done
	echo -e "\e[222G\e[3D v \r\e[36m$* \e[0m"
	error=0
}

status() {
	if [ $error -eq 0 ]
	then
		echo -e "\e[1A\e[222G\e[4D\e[32m [OK]\e[0m"
	else
		echo -e "\e[1A\e[222G\e[8D\a\e[1;31m [FAILED]\e[0m"
	fi
}

case "$1" in

   start)
	title "Starting zabbix_agentd."
       (/home/zabbix/sbin/zabbix_agentd -c /home/zabbix/conf/zabbix_agentd.conf ) || error=$?
   	status
	;;

   stop)
	title "Stopping zabbix_agentd."
       kill $(cat /home/zabbix/zabbix_agentd.pid) || error=$?
   	status
	;;

   restart)
	title "Restarting zabbix_agentd."
       kill -1 $(cat /home/zabbix/zabbix_agentd.pid) || error=$?
   	status
	;;

    *)
	echo "Usage: $0 { start | stop | restart }"
	exit 1 ;;

esac

exit 0
EOF
   ssh -p $PORT root@$IP 'chmod +x /etc/init.d/zabbix_agentd'
   ssh -p $PORT root@$IP '/etc/init.d/zabbix_agentd restart'
fi
exit 0
#ip=ifconfig|xargs|awk '{print $7}'|sed -e 's/[a-z]*:/''/'
#cat /etc/redhat-release  | grep "CentOS release 6.6" | wc -l
