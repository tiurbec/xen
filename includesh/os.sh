#!/bin/bash
#
# OS related functions
#

. ./config.sh
function isCentos67 () 
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'cat /etc/redhat-release 2>/dev/null | grep "CentOS release 6.7" | wc -l' </dev/null)
if [ $RETSTR -eq 1 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function isCentos66 () 
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'cat /etc/redhat-release 2>/dev/null | grep "CentOS release 6.6" | wc -l' </dev/null)
if [ $RETSTR -eq 1 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function isCentos65 ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'cat /etc/redhat-release 2>/dev/null | grep "CentOS release 6.5" | wc -l' </dev/null)
if [ $RETSTR -eq 1 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function isCentos510 ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'cat /etc/redhat-release 2>/dev/null | grep "CentOS release 5.10" | wc -l' </dev/null)
if [ $RETSTR -eq 1 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function isOpensde ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'cat /etc/SDE-VERSION 2>/dev/null | grep "OpenSDE" | wc -l' </dev/null)
if [ $RETSTR -eq 1 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function isOpensdeTrunk ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'cat /etc/SDE-VERSION 2>/dev/null | grep "OpenSDE trunk" | wc -l' </dev/null)
if [ $RETSTR -eq 1 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function isOpensdeTrunk2007 ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'cat /etc/SDE-VERSION 2>/dev/null | grep "OpenSDE trunk" | grep 2007 | wc -l' </dev/null)
if [ $RETSTR -eq 1 ];
then
   echo "1"
   return 1
fi
echo "0"
return 0
}

function isDom0 ()
{
IP=${1:-"127.0.0.1"}
PORT=${2:-"22"}
USER=${3:-"root"}
IFILE=${4:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
if [ $(isCentos66 $IP $PORT $USER $IFILE) -eq 1 ];
then
   RETSTR=$(ssh $SSHPARAMS $SSHOPTS "stat /usr/sbin/xl 2>/dev/null" </dev/null)
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
   RETSTR=$(ssh $SSHPARAMS $SSHOPTS "stat /usr/sbin/vserver 2>/dev/null" </dev/null)
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
}

function hasFile ()
{
FILE=${1:-"somefile"}
IP=${2:-"127.0.0.1"}
PORT=${3:-"22"}
USER=${4:-"root"}
IFILE=${5:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS "stat $FILE 2>/dev/null" </dev/null)
RETVAL=$?
   if [ $RETVAL -eq 0 ];
   then
      echo "1"
      return 1
   else
      echo "0"
      return 0
   fi
}

function hasUser ()
{
USERNAME=${1:-"root"}
IP=${2:-"127.0.0.1"}
PORT=${3:-"22"}
USER=${4:-"root"}
IFILE=${5:-"/root/.ssh/id_rsa"}
SSHPARAMS=" -p $PORT $USER@$IP -i $IFILE "
RETSTR=$(ssh $SSHPARAMS $SSHOPTS 'cat /etc/passwd | cut -d\: -f1 | grep -e "^$USERNAME" | cut -f1' </dev/null)
RETVAL=$?
if [ -z "$RETSTR" ];
then
   echo "0"
   return "0"
elif [ $RETSTR == $USERNAME ];
then
   echo "1"
   return 1
else
   echo "0"
   return 0
fi
}

