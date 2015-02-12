#!/bin/bash
#
# Zabbix agent related functions
#
. ./config.sh
. ./os.sh

function updateZAconfig ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
IDH=${5:-"-1"}
SISNAME=${6:-"unknown"}
NEWNAME=${7:-"empty"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
ZACFGFILE="/etc/zabbix/zabbix_agentd.conf"
ZAPIDFILE="/var/run/zabbix/zabbix_agentd.pid"
ZALOGFILE="/var/log/zabbix/zabbix_agentd.log"
ROLES="expert"
if [ $(hasZabbixAgent $IP $PORT $USER $IFILE) -eq 1 ];
then
  if [ $(isOpensde $IP $PORT $USER $IFILE) -eq 1 ];
  then
    ZACFGFILE="/home/zabbix/conf/zabbix_agentd.conf"
    ZAPIDFILE="/home/zabbix/zabbix_agentd.pid"
    ZALOGFILE="/home/zabbix/zabbix_agentd.log"
  fi
  if [ $(hasPostgres $IP $PORT $USER $IFILE) -eq 1 ];
  then
    ROLES="$ROLES,postgres"
  fi
  if [ $(hasPhp $IP $PORT $USER $IFILE) -eq 1 ];
  then
    ROLES="$ROLES,php"
  fi
  if [ $(hasNginx $IP $PORT $USER $IFILE) -eq 1 ];
  then
    ROLES="$ROLES,nginx"
  fi
  if [ $(isDom0 $IP $PORT $USER $IFILE) -eq 0 ];
  then
    ROLES="$ROLES,VirtualHost"
  else
    ROLES="$ROLES,Dom0"
  fi
  if [ "$NEWNAME" == "empty" ];
  then
    ZACFGHNAME=""
  else
    ZACFGHNAME="Hostname=$NEWNAME"
  fi
  ssh $SSHPARAMS $SSHOPTS "cat <<EOF > $ZACFGFILE
PidFile=$ZAPIDFILE
LogFile=$ZALOGFILE
LogFileSize=0
DebugLevel=2
#SourceIP=$SOURCEIP
$ZACFGHNAME
ServerActive=144.76.106.136
HostnameItem=system.hostname
HostMetadata=$ROLES
RefreshActiveChecks=120
StartAgents=0
UserParameter=expert.address,curl -s http://144.76.106.136:800
UserParameter=expert.sshport,echo \"$PORT\"
UserParameter=expert.sisname,echo \"$SISNAME\"
UserParameter=expert.sisidh,echo \"$IDH\"
UserParameter=expert.hostname,hostname
UserParameter=expert.osname,if test -f /etc/redhat-release; then cat /etc/redhat-release; else if test -f /etc/SDE-VERSION; then cat /etc/SDE-VERSION; else echo \"Unknown\";fi ;fi
UserParameter=expert.consoleusers,who -u |wc -l
UserParameter=expert.psqlpcount,ps ax|grep postgres|grep -v grep|wc -l
UserParameter=expert.load1,cat /proc/loadavg | cut -d\  -f1
UserParameter=expert.load5,cat /proc/loadavg | cut -d\  -f2
UserParameter=expert.load10,cat /proc/loadavg | cut -d\  -f3
EOF" </dev/null
restartZabbixAgent $IP $PORT $USER $IFILE
fi
}

function putZabbixAgent ()
{
IP=$1
PORT=$2
USER=$3
IFILE=$4
SSHPARAMS=""
if [ $(hasZabbixAgent $IP $PORT $USER $IFILE) -eq 0 ];
then
  if [ $(isCentos66 $IP $PORT $USER $IFILE) -eq 1 ];
  then
    putZAcentos66 $IP $PORT $USER $IFILE
  elif [ $(isCentos65 $IP $PORT $USER $IFILE) -eq 1 ];
  then
    putZAcentos66 $IP $PORT $USER $IFILE
  elif [ $(isOpensde $IP $PORT $USER $IFILE) -eq 1 ];
  then
    putZAopensde $IP $PORT $USER $IFILE
  fi
else
  echo "ZabbixAgent already installed."
fi
}

function hasZabbixAgent ()
{
IP=$1
PORT=$2
USER=$3
IFILE=$4
SSHPARAMS=""
if [ $# -eq 2 ];
then
  SSHPARAMS=" -p $PORT root@$IP "
elif [ $# -eq 3 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP "
elif [ $# -eq 4 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
fi
if [ $(isCentos66 $IP $PORT $USER $IFILE) -eq 1 ];
then
   RETSTR=$(ssh $SSHPARAMS $SSHOPTS "stat /etc/zabbix/zabbix_agentd.conf 2>/dev/null" </dev/null)
   RETSTR=$?
   if [ $RETSTR -eq 0 ];
   then
      echo "1"
      return 1
   else
      echo "0"
      return 0
   fi
elif [ $(isCentos65 $IP $PORT $USER $IFILE) -eq 1 ];
then
   RETSTR=$(ssh $SSHPARAMS $SSHOPTS "stat /etc/zabbix/zabbix_agentd.conf 2>/dev/null" </dev/null)
   RETSTR=$?
   if [ $RETSTR -eq 0 ];
   then
      echo "1"
      return 1
   else
      echo "0"
      return 0
   fi
elif [ $(isOpensde $IP $PORT $USER $IFILE) -eq 1 ];
then
   RETSTR=$(ssh $SSHPARAMS $SSHOPTS "stat /home/zabbix/conf/zabbix_agentd.conf 2>/dev/null" </dev/null)
   RETSTR=$?
   if [ $RETSTR -eq 0 ];
   then
      echo "1"
      return 1
   else
      echo "0"
      return 0
   fi
elif [ $(isCentos510 $IP $PORT $USER $IFILE) -eq 1 ];
then
   RETSTR=$(ssh $SSHPARAMS $SSHOPTS "stat /etc/zabbix/zabbix_agentd.conf 2>/dev/null" </dev/null)
   RETSTR=$?
   if [ $RETSTR -eq 0 ];
   then
      echo "1"
      return 1
   else
      echo "0"
      return 0
   fi
fi
echo "0"
return 0
}

function isZabbixAgentRunning ()
{
IP=$1
PORT=$2
USER=$3
IFILE=$4
SSHPARAMS=""
if [ $# -eq 2 ];
then
  SSHPARAMS=" -p $PORT root@$IP "
elif [ $# -eq 3 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP "
elif [ $# -eq 4 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
fi
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'ps aux  | grep "zabbix_agentd" | wc -l' </dev/null)
if [ $RETSTR -gt 0 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function restartZabbixAgent ()
{
IP=$1
PORT=$2
USER=$3
IFILE=$4
SSHPARAMS=""
if [ $# -eq 2 ];
then
  SSHPARAMS=" -p $PORT root@$IP "
elif [ $# -eq 3 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP "
elif [ $# -eq 4 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
fi
RETSTR=$(ssh $SSHPARAMS $SSHOPTS '/etc/init.d/zabbix_agentd stop >/dev/null 2>/dev/null' </dev/null)
RETSTR=$(ssh $SSHPARAMS $SSHOPTS '/etc/init.d/zabbix_agentd start >/dev/null 2>/dev/null' </dev/null)
if [ $? -eq 0 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function setZAboot ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
if [ $(isCentos66 $IP $PORT $USER $IFILE) -eq 1 ];then
  ssh $SSHPARAMS $SSHOPTS "chkconfig zabbix-agent on" </dev/null
elif [ $(isCentos65 $IP $PORT $USER $IFILE) -eq 1 ];then
  ssh $SSHPARAMS $SSHOPTS "chkconfig zabbix-agent on" </dev/null
elif [ $(isCentos510 $IP $PORT $USER $IFILE) -eq 1 ];then
  ssh $SSHPARAMS $SSHOPTS "chkconfig zabbix-agent on" </dev/null
elif [ $(isOpensde $IP $PORT $USER $IFILE) -eq 1 ];then
  ssh $SSHPARAMS $SSHOPTS "ln -s /etc/init.d/zabbix_agentd /etc/runit/1.d/99zabbix_agentd" </dev/null
fi
#ln -s /etc/init.d/zabbix_agentd /etc/runit/1.d/99zabbix_agentd
}

function putZAcentos66 ()
{
IP=$1
PORT=$2
USER=$3
IFILE=$4
SSHPARAMS=""
SCPPARAMS=""
ROLES="base"
if [ $# -eq 2 ];
then
  SSHPARAMS=" -p $PORT root@$IP "
  USER="root"
elif [ $# -eq 3 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP "
elif [ $# -eq 4 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
  SCPPARAMS=" -i $IFILE "
fi
SOURCEIP=$(ssh $SSHPARAMS $SSHOPTS "ifconfig eth0|grep inet|grep -v inet6|awk '{print \$2}'|sed 's/addr://'" </dev/null)
errecho $SOURCEIP
ssh $SSHPARAMS $SSHOPTS 'rpm -Uvh "http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm"' </dev/null
ssh $SSHPARAMS $SSHOPTS "yum -y install zabbix-agent" </dev/null
ssh $SSHPARAMS $SSHOPTS "chkconfig zabbix-agent on" </dev/null
#cat <<EOF | ssh -e none $SSHPARAMS 'cat > /etc/zabbix/zabbix_agentd.conf' </dev/null
#PidFile=/var/run/zabbix/zabbix_agentd.pid
#LogFile=/var/log/zabbix/zabbix_agentd.log
#LogFileSize=0
#DebugLevel=2
#SourceIP=$SOURCEIP
#ServerActive=144.76.106.136
#HostnameItem=system.hostname
#HostMetadata=$ROLES
#RefreshActiveChecks=120
#StartAgents=0
#EOF
ssh $SSHPARAMS $SSHOPTS "cat <<EOF > /etc/zabbix/zabbix_agentd.conf
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
DebugLevel=2
SourceIP=$SOURCEIP
ServerActive=144.76.106.136
HostnameItem=system.hostname
HostMetadata=$ROLES
RefreshActiveChecks=120
StartAgents=0
EOF" </dev/null

scp -P $PORT $SCPPARAMS /root/git/xen/files/zabbix-agent/postgres/etc/* $USER@$IP:/etc/zabbix/zabbix_agentd.d/
scp -P $PORT $SCPPARAMS /root/git/xen/files/zabbix-agent/postgres/usr/* $USER@$IP:/usr/local/bin/
ssh $SSHPARAMS $SSHOPTS "service zabbix-agent restart" </dev/null
}

function putZAopensde ()
{
IP=$1
PORT=$2
USER=$3
IFILE=$4
SSHPARAMS=""
SCPPARAMS=""
ROLES="base"
DEFIF="dummy0"
if [ $# -eq 2 ];
then
  SSHPARAMS=" -p $PORT root@$IP "
  USER="root"
elif [ $# -eq 3 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP "
elif [ $# -eq 4 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
  SCPPARAMS=" -i $IFILE "
fi
DEFIF=$(getDefaultIf $IP $PORT $USER $IFILE)
SOURCEIP=$(ssh $SSHPARAMS $SSHOPTS "ifconfig $DEFIF|grep inet|grep -v inet6|awk '{print \$2}'|sed 's/addr://'" </dev/null)
if [ $(isOpensdeTrunk $IP $PORT $USER $IFILE) -eq 1 ];
then
# if [ $(isOpensdeTrunk2007 $IP $PORT $USER $IFILE) -eq 1 ];
# then
  echo "This OpenSDE is too old skipping ..."
#  return 99
# else
#  ssh $SSHPARAMS '/usr/sbin/useradd -m -s /bin/false zabbix'
# fi
#else
# ssh $SSHPARAMS $SSHOPTS "/usr/sbin/useradd -m zabbix" </dev/null
fi
ssh $SSHPARAMS $SSHOPTS "/usr/sbin/useradd -m zabbix" </dev/null
ssh $SSHPARAMS $SSHOPTS "chsh -s /bin/false zabbix" </dev/null
ssh $SSHPARAMS $SSHOPTS "cd ~zabbix;lftpget http://www.zabbix.com/downloads/2.4.1/zabbix_agents_2.4.1.linux2_6.amd64.tar.gz;tar xvfz zabbix_agents_2.4.1.linux2_6.amd64.tar.gz" </dev/null
#cat <<EOF | ssh $SSHPARAMS $SSHOPTS "cat > /home/zabbix/conf/zabbix_agentd.conf" </dev/null
#PidFile=/home/zabbix/zabbix_agentd.pid
#LogFile=/home/zabbix/zabbix_agentd.log
#LogFileSize=0
#DebugLevel=2
#SourceIP=$SOURCEIP
#ServerActive=144.76.106.136
#HostnameItem=system.hostname
#HostMetadata=$ROLES
#RefreshActiveChecks=120
#StartAgents=0
#EOF
ssh $SSHPARAMS $SSHOPTS "cat <<EOF >/home/zabbix/conf/zabbix_agentd.conf
PidFile=/home/zabbix/zabbix_agentd.pid
LogFile=/home/zabbix/zabbix_agentd.log
LogFileSize=0
DebugLevel=2
ServerActive=144.76.106.136
HostnameItem=system.hostname
HostMetadata=$ROLES
RefreshActiveChecks=120
StartAgents=0
EOF
"</dev/null
#cat <<'EOF' | ssh $SSHPARAMS $SSHOPTS "cat > /etc/init.d/zabbix_agentd" </dev/null
#title() {
#        local x w="$( stty size 2>/dev/null </dev/tty | cut -d" " -f2  )"
#        [ -z "$w" ] && w="$( stty size </dev/console | cut -d" " -f2  )"
#        for (( x=1; x<w; x++ )) do echo -n .; done
#        echo -e "\e[222G\e[3D v \r\e[36m$* \e[0m"
#        error=0
#}
#
#status() {
#        if [ $error -eq 0 ]
#        then
#                echo -e "\e[1A\e[222G\e[4D\e[32m [OK]\e[0m"
#        else
#                echo -e "\e[1A\e[222G\e[8D\a\e[1;31m [FAILED]\e[0m"
#        fi
#}
#
#case "$1" in
#
#   start)
#        title "Starting zabbix_agentd."
#       (/home/zabbix/sbin/zabbix_agentd -c /home/zabbix/conf/zabbix_agentd.conf ) || error=$?
#        status
#        ;;
#
#   stop)
#        title "Stopping zabbix_agentd."
#       kill $(cat /home/zabbix/zabbix_agentd.pid) || error=$?
#        status
#        ;;
#
#   restart)
#        title "Restarting zabbix_agentd."
#       kill -1 $(cat /home/zabbix/zabbix_agentd.pid) || error=$?
#        status
#        ;;
#
#    *)
#        echo "Usage: $0 { start | stop | restart }"
#        exit 1 ;;
#
#esac
#
#exit 0
#EOF
ssh $SSHPARAMS $SSHOPTS 'touch /etc/init.d/zabbix_agentd' </dev/null
ssh $SSHPARAMS $SSHOPTS 'cat <<'"'"'EOF'"'"' >/etc/init.d/zabbix_agentd
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
' </dev/null
ssh $SSHPARAMS $SSHOPTS "chmod +x /etc/init.d/zabbix_agentd" </dev/null
scp -P $PORT $SCPPARAMS /root/git/xen/files/zabbix-agent/postgres/etc/* $USER@$IP:/home/zabbix/conf/zabbix_agentd/
scp -P $PORT $SCPPARAMS /root/git/xen/files/zabbix-agent/postgres/usr/* $USER@$IP:/usr/local/bin/

ssh $SSHPARAMS $SSHOPTS "/etc/init.d/zabbix_agentd stop" </dev/null
ssh $SSHPARAMS $SSHOPTS "/etc/init.d/zabbix_agentd start" </dev/null

}

