#!/bin/bash

# Variabile folosite in definirea masinii:
#
# IDHOST 	- din SIS si determina adresa MAC
# HOSTIP 	- adresa masinii gazda
# HOSTSSHP 	- portul pt ssh pe gazda
# DUID		- al catelea DomU este acesta pe gazda
# DUIP		- adresa IP a masinii virtuale 10.1.1.DUID
# DUSSHP	- portul de ssh va fi 2200+DUID
# DUHOSTNAME	- hostname pentru DomU 
# DUMAC		- adresa MAC generata din IDHOST
# ROLES		- lista de servicii oferite. serviciile sunt separate cu virgula si fara spatii. 
#		  servicii posibile: postgres,pgbouncer,nginx,php
#
# DEBUG		- for debugging messages
# TESTING	- will only create config files but wil not apply anything
# 
#
# In linia de comanda se vor specifica:
# IDHOST, HOSTIP, HOSTSSHP, DUHOSTNAME, DUID, ROLES, LVSIZE
#
# Exit codes are as follows:
#	 0 - no error 
#	 1 - invalid number of params. Help message displayed
#	 2 - called script returned with error
#	10 - TESTING mode. Config files were created but nothing applied
#	20 - xlXXX.run file already on Dom0. Installation halted
#	22 - ssh connection error. Why 22? Beacuse of ssh. Anyways, installation halted
#	30 - The desired logical volume already exists. Installation halted
if [ $# != 8 ]
then
   cat << EOF
xen virtual machine creator"

 Usage:
  $0 <idhost> <hostip> <hostsshp> <domuhostname> <domuid> <roles> <lvsize> <testing>

EOF
   exit 1
fi
#
DEBUG=1
#TESTING=1
#
# numarul de parametri e corect
if [ $DEBUG -eq 1 ]
then
   echo -n "Parameters workout ... "
fi
IDHOST=$1
HOSTIP=$2
HOSTSSHP=$3
_DUHOSTNAME=$4
DUHOSTNAME="${_DUHOSTNAME//[^[:alnum:]_\-\.]/_}"
DUID=$5
ROLES=$6
LVSIZE=$7
TESTING=$8
DUIP=10.1.1.$DUID
DUSSHP=$((2200+$DUID))
DUPGPORT=$((54320+$DUID))
DUMAC=`./int2mac $IDHOST`
XINST="xl$IDHOST-$DUHOSTNAME.install"
XRUN="xl$IDHOST-$DUHOSTNAME.run"
XKS="xl$IDHOST-$DUHOSTNAME.ks"
HASNGINX=0
HASPOSTGRES=0
HASPHP=0
HASPGBOUNCER=0
APPS="nginx pgbouncer postgres php"

for app in $APPS; do
        if [[ "$ROLES" == *"$app"* ]]; then
                eval HAS${app^^}=1
        fi
done

if [ $DEBUG -eq 1 ]
then
   echo "done"
   echo -n "Creating XINST ... "
fi

sh ./xs_crxinst.sh $DUHOSTNAME $DUIP $DUMAC $XINST $XKS
if [ $? -ne 0 ]
then
   echo "Error while calling ./xs_crxinst.sh"
   exit 2
else
   if [ $DEBUG -eq 1 ]
   then
	echo "done"
   fi
fi

if [ $DEBUG -eq 1 ]
then
   echo -n "Creating XKS ... "
fi

sh ./xs_crxks.sh $DUHOSTNAME $DUIP $XKS $ROLES
if [ $? -ne 0 ]
then
   echo "Error while calling ./xs_crxks.sh"
   exit 2
else
   if [ $DEBUG -eq 1 ]
   then
        echo "done"
   fi
fi

if [ $DEBUG -eq 1 ]
then
   echo "Creating XRUN ..."
fi

sh ./xs_crxrun.sh $DUHOSTNAME $DUMAC $XRUN
if [ $? -ne 0 ]
then
   echo "Error while calling ./xs_crxrun.sh"
   exit 2
else
   if [ $DEBUG -eq 1 ]
   then
        echo "done"
   fi
fi

sh ./xs_crzbag.sh $DUHOSTNAME $DUIP $ROLES
if [ $? -ne 0 ]
then
   echo "Error while calling ./xs_crzbag.sh"
   exit 2
else
   if [ $DEBUG -eq 1 ]
   then
        echo "done"
   fi
fi

if [ $TESTING -eq 1 ]
then
   echo "Config files created. Exiting without applying them."
   exit 10
fi

if [ $DEBUG -eq 1 ]
then
   echo -n "Copying files ... "
fi

sh ./xs_cp.sh $XINST $XRUN $XKS $HOSTIP $HOSTSSHP
if [ $? -ne 0 ]
then
   echo "Error while calling ./xs_cp.sh"
   exit 2
else
   if [ $DEBUG -eq 1 ]
   then
        echo "done"
   fi
fi

if [ $DEBUG -eq 1 ]
then
   echo "Checking for lv on Dom0 ..."
fi
ssh -p $HOSTSSHP root@$HOSTIP "lvdisplay /dev/vg0/$DUHOSTNAME"
LVEXISTS=$?
if [ $LVEXISTS -eq 0 ]
then
   echo "Logical volume /dev/vg0/$DUHOSTNAME already exists on Dom0 at $HOSTIP. Installation HALTED!"
   exit 30
   elif [ $LVEXISTS -eq 255 ]
   then
      echo "Error while connecting to $HOSTIP"
      exit 22
fi
ssh -p $HOSTSSHP root@$HOSTIP "lvcreate -n $DUHOSTNAME -L $LVSIZE /dev/vg0" 

if [ $DEBUG -eq 1 ]
then
   echo "Starting installation for $DUHOSTNAME on $HOSTIP"
fi

sh ./xs_post.sh $HOSTIP $HOSTSSHP $XINST $XRUN $ROLES $DUID $DUPGPORT $DUSSHP $DUHOSTNAME
if [ $? -ne 0 ]
then
   echo "Error while calling ./xs_post.sh"
   exit 2
fi

