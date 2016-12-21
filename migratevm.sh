#!/bin/bash

#ssh -p 2200 176.9.38.140 "dd if=/dev/vg0/amatic-boot     |gzip"|gunzip|dd of=/dev/vg0/amatic-boot
REMOTEHOST="176.9.38.140"
REMOTEMHPORT="2200"
REMOTEVHPORT="2251"
VMNAME="amatic"
#REMOTEVG="vg0"
LOCALVG="vg0"
XENCFG="xl293-amatic"
DOZEROING=0
B="\033[1m"
N="\033[0m"

echodf()
{
	if [ "$?" -eq "0" ];then
		echo -e "${B}done${N}"
	else
		echo -e "${B}failed${N}"
		exit 1
	fi
}

echo -ne "${B}Finding local IP address ${N}"
LOCALIP=$(ssh -p $REMOTEVHPORT $REMOTEHOST "ip addr show dev eth0 |grep inet\ | awk '{print \$2}'|cut -f1 -d/")
echo $LOCALIP

if [ "$DOZEROING" -eq "1" ];then
	echo -e "${B}Zeroing free space on /boot${N}"
	ssh -p $REMOTEVHPORT $REMOTEHOST "dd if=/dev/zero of=/boot/delete.me bs=1024000;rm -f /boot/delete.me"

	echo -e "${B}Zeroing free space on /${N}"
	ssh -p $REMOTEVHPORT $REMOTEHOST "dd if=/dev/zero of=/delete.me bs=102400000;rm -f /delete.me"
fi

echo -e "${B}Reading LVS info about $VMNAME${N}"
ssh -p $REMOTEMHPORT $REMOTEHOST "lvs | grep ${VMNAME}- "

echo -e "${B}Creating LVS locally ... ${N}"
bash -c "$(ssh -p $REMOTEMHPORT $REMOTEHOST "lvs | grep ${VMNAME}- " | awk '{print "lvcreate -W y -Z y -n "$1" -L "$4" /dev/"$2}')"
echodf
#echo -e "${B}done${N}"

echo -e "${B}Shutting down VPS $VMNAME ... ${N}"
ssh -p $REMOTEMHPORT $REMOTEHOST "xl shutdown -w $VMNAME"
echodf

echo -e "${B}Migrating LVS data${N}"
##bash -c "$(ssh -p $REMOTEMHPORT $REMOTEHOST "lvs | grep ${VMNAME}- " | awk '{print "ssh -p $REMOTEMHPORT $REMOTEHOST \"dd if=/dev/$2/$1     |gzip\"|gunzip|dd of=/dev/$LOCALVG/$1"}')"
##ssh -p $REMOTEMHPORT $REMOTEHOST "lvs | grep ${VMNAME}- " 
bash -c "$(ssh -p $REMOTEMHPORT $REMOTEHOST "lvs | grep ${VMNAME}- " | awk -v IP="$REMOTEHOST" -v PORT="$REMOTEMHPORT" -v VG="$LOCALVG" '{$4=gensub("\\.00","",1,$4);print "ssh -p "PORT" "IP" \"dd if=/dev/"$2"/"$1" 2>/dev/null | gzip\" | gunzip | pv -s "$4"| dd of=/dev/"VG"/"$1" 2>/dev/null"}')"

echo -ne "${B}Copying xen config ... ${N}"
scp -P $REMOTEMHPORT $REMOTEHOST:/etc/xen/$XENCFG.run /etc/xen
scp -P $REMOTEMHPORT $REMOTEHOST:/etc/xen/$XENCFG.install /etc/xen
echo -e "${B}done${N}"

echo -ne "${B}Activating VPS $VMNAME to start at boot ... ${N}"
ln -s /etc/xen/$XENXFG.run  /etc/xen/auto/$XENCFG.run
echo -e "${B}done${N}"

echo -e "${B}Setting iptables rules${N}"
ssh -p $REMOTEMHPORT $REMOTEHOST "iptables -S -t nat | grep -e \"${LOCALIP}:\" -e \"${LOCALIP}\$\"" | sed s/^/iptables\ -t\ nat\ /g
bash -c "$(ssh -p $REMOTEMHPORT $REMOTEHOST "iptables -S -t nat | grep -e \"${LOCALIP}:\" -e \"${LOCALIP}\$\"" | sed s/^/iptables\ -t\ nat\ /g)"

echo -ne "${B}Saving iptables rules ... ${N}"
iptables-save > /etc/sysconfig/iptables
echodf
#echo -e "${B}done${N}"

echo -e "${B}Starting newly created VPS ... ${N}"
xl create /etc/xen/$XENCFG.run
#echo -e "${B}done${N}"
echodf
