#!/bin/bash
#
# Service related functions
#

. ./config.sh
function isProcessRunning ()
{
PROCESS=${1:-"zxcv"}
IP=${2:-"127.0.0.1"}
PORT=${3:-"22"}
USER=${4:-"root"}
IFILE=${5:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS "ps aux  | grep \"$PROCESS\" | wc -l" </dev/null)
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
PACK=${1:-"zxcv"}
IP=${2:-"127.0.0.1"}
PORT=${3:-"22"}
USER=${4:-"root"}
IFILE=${5:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
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
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
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
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
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
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
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
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
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
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
haspg=0
if [ $(hasPackage "postgresql" $IP $PORT $USER $IFILE) -eq 1 ];
then
   haspg=1
fi
if [ $(hasPackage "pg82" $IP $PORT $USER $IFILE) -eq 1 ];
then
  haspg=1
fi
if [ $(hasPackage "postgresql92" $IP $PORT $USER $IFILE) -eq 1 ];
then
  haspg=1
fi
if [ $haspg -eq 1 ];
then
  echo "1"
  return "1"
fi
echo "0"
return "0"
}

function hasNginx ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
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
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
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
