#!/bin/bash
#
# Service related functions
#

. ./config.sh
function isProcessRunning ()
{
PROCESS=$1
IP=$2
PORT=$3
USER=$4
IFILE=$5
SSHPARAMS=""
if [ $# -eq 3 ];
then
  SSHPARAMS=" -p $PORT root@$IP "
elif [ $# -eq 4 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP "
elif [ $# -eq 5 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
fi
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'ps aux  | grep "$PROCESS" | wc -l' </dev/null)
if [ $RETSTR -gt 2 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function hasPackage ()
{
PACK=$1
IP=$2
PORT=$3
USER=$4
IFILE=$5
SSHPARAMS=""
if [ $# -eq 3 ];
then
  SSHPARAMS=" -p $PORT root@$IP "
elif [ $# -eq 4 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP "
elif [ $# -eq 5 ];
then
  SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
fi
if [ $(isCentos66 $IP $PORT $USER $IFILE) -eq 1 ];
then
RETSTR=$(ssh $SSHPARAMS $SSHOPTS "rpm -qa $PACK 2>/dev/null | wc -l" </dev/null)
  if [ $RETSTR -gt 0 ];
  then
    echo "1"
    return "1"
  fi
  echo "0"
  return "0"
elif [ $(isOpensde $IP $PORT $USER $IFILE) -eq 1 ];
then
RETSTR=$(ssh $SSHPARAMS $SSHOPTS "mine -q $PACK 2>/dev/null | wc -l" </dev/null)
  if [ $RETSTR -gt 0 ];
  then
    echo "1"
    return "1"
  fi
  echo "0"
  return "0"
fi
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
if [ $(isProcessRunning "zabbix_agentd" $IP $PORT $USER $IFILE) -eq 1 ];
then
  echo "1"
  return "1"
fi
echo "0"
return "0"
}

function isPostgresRunning ()
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
if [ $(isProcessRunning "postgres" $IP $PORT $USER $IFILE) -eq 1 ];
then
  echo "1"
  return "1"
fi
echo "0"
return "0"
}

function isNginxRunning ()
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
if [ $(isProcessRunning "nginx" $IP $PORT $USER $IFILE) -eq 1 ];
then
  echo "1"
  return "1"
fi
echo "0"
return "0"
}

function isPhpRunning ()
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
if [ $(isProcessRunning "php-fpm" $IP $PORT $USER $IFILE) -eq 1 ];
then
  echo "1"
  return "1"
fi
echo "0"
return "0"
}

function hasPostgres ()
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
if [ $(hasPackage "postgresql" $IP $PORT $USER $IFILE) -eq 1 ];
then
  echo "1"
  return "1"
fi
echo "0"
return "0"
}

function hasNginx ()
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
if [ $(hasPackage "nginx" $IP $PORT $USER $IFILE) -eq 1 ];
then
  echo "1"
  return "1"
fi
echo "0"
return "0"
}

function hasPhp ()
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
  if [ $(hasPackage "php-fpm" $IP $PORT $USER $IFILE) -eq 1 ];
  then
    echo "1"
    return "1"
  else
    echo "0"
    return "0"
  fi
else
  if [ $(hasPackage "php" $IP $PORT $USER $IFILE) -eq 1 ];
  then
    echo "1"
    return "1"
  else
    echo "0"
    return "0"
  fi
fi
echo "0"
return "0"
}
