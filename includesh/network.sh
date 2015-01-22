#!/bin/bash
#
# Network related functions
#
. ./config.sh
function getDefaultIf ()
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
RETSTR=$(ssh $SSHPARAMS $SSHOPTS "route -n | grep -e \"^0.0.0.0\" | awk 'END {print \$NF}'" </dev/null)
echo -n "$RETSTR"
}

function canConnect ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
#if [ $# -eq 2 ];
#then
#  SSHPARAMS=" -p $PORT root@$IP "
#elif [ $# -eq 3 ];
#then
#  SSHPARAMS=" -p $PORT $USER@$IP "
#elif [ $# -eq 4 ];
#then
#  SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
#fi
RETSTR=$(ssh $SSHPARAMS $SSHOPTS "pwd" </dev/null)
RETVAL=$?
#>&2 echo "RETVAL=$RETVAL"
if [ $RETVAL -eq 0 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function openShell ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
ssh -t -t $SSHPARAMS
}

function getHostname ()
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
RETSTR=$(ssh $SSHPARAMS $SSHOPTS "hostname" </dev/null)
echo -n "$RETSTR"
}

function getDefaultGw ()
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
RETSTR=$(ssh $SSHPARAMS $SSHOPTS "route -n | grep -e \"^0.0.0.0\" | awk '{print \$2}'" </dev/null)
echo -n "$RETSTR"
}

function isIP ()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function getIPCountry ()
{
  IP=$1
  COUNTRY="--"
  if isIP $1;then
    COUNTRY=$(whois $IP | grep -i country\: | head -1 | awk '{print toupper($2)}')
  fi
  echo $COUNTRY
}

