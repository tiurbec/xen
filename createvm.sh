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
# ROLES		- lista de servicii oferite. serviciile sunt separate cu virgula si fara spatii. servicii posibile: postgres,pgbouncer,nginx,php
#
# DEBUG		- pentru testare
#
# In linia de comanda se vor specifica:
# IDHOST, HOSTIP, HOSTSSHP, DUHOSTNAME, DUID, ROLES, LVSIZE
#
# De adaugat port fw pt ssh 22xx si 54320+x ps postgresx
if [ $# != 7 ]
then
   echo "xen virtual machine creator"
   echo " "
   echo " Usage:"
   echo "  createvm.sh <idhost> <hostip> <hostsshp> <domuhostname> <domuid> <roles> <lvsize>"
   echo " "
   exit 0
fi
#
DEBUG=1
#
# numarul de parametri e corect
if [ $DEBUG -eq 1 ]
then
   echo "Parameters workout ..."
fi
IDHOST=$1
HOSTIP=$2
HOSTSSHP=$3
DUHOSTNAME=$4
DUID=$5
ROLES=$6
LVSIZE=$7
DUIP=10.1.1.$DUID
DUSSHP=$((2200+$DUID))
DUPGPORT=$((54320+$DUID))
DUMAC=`./int2mac $IDHOST | sed s/\ /0/g`
XINST="xl$IDHOST.install"
XRUN="xl$IDHOST.run"
XKS="xl$IDHOST.ks"
HASNGINX=`echo $ROLES | grep nginx | wc -l`
HASPGBOUNCER=`echo $ROLES | grep pgbouncer | wc -l`
HASPOSTGRES=`echo $ROLES | grep postgres | wc -l`
HASPHP=`echo $ROLES | grep php | wc -l`

echo $ROLES
if [ $DEBUG -eq 1 ]
then
#   set
   echo "Creating XINST ..."
fi
echo "name = \"$DUHOSTNAME\"" > ./$XINST
echo "kernel = \"/usr/local/xen/vmlinuz\"" >> ./$XINST
echo "ramdisk = \"/usr/local/xen/initrd.img\"" >> ./$XINST
echo "extra = \"root=/dev/xvda1 ip=$DUIP netmask=255.255.255.0 gateway=10.1.1.1 dns=8.8.8.8 text ks=http://10.1.1.10/$XKS\"" >> ./$XINST
echo "memory = 1024" >> ./$XINST
echo "maxmem = 2048" >> ./$XINST
echo "vcpus = 2" >> ./$XINST
echo "vif = [ 'mac=$DUMAC, bridge=xenbr0' ]" >> ./$XINST
echo "disk = [ '/dev/vg0/$DUHOSTNAME,raw,xvda,rw' ]" >> ./$XINST
echo "on_reboot = 'destroy'" >> ./$XINST
echo "on_crash = 'destroy'" >> ./$XINST

if [ $DEBUG -eq 1 ]
then
   echo "Creating XKS ..."
fi
echo "install" > ./$XKS
echo "url --url http://mirror.centos.org/centos/6/os/x86_64/" >> ./$XKS
echo "lang en_US.UTF-8" >> ./$XKS
echo "network --device eth0 --bootproto static --ip=$DUIP --netmask=255.255.255.0 --gateway=10.1.1.1 --nameserver=8.8.8.8,8.8.4.4 --hostname=$DUHOSTNAME" >> ./$XKS
echo "rootpw bogus" >> ./$XKS
echo "firewall --enabled --port=22" >> ./$XKS
echo "authconfig --enableshadow --enablemd5" >> ./$XKS
echo "selinux --disabled" >> ./$XKS
echo "timezone --utc Europe/Bucharest" >> ./$XKS
echo "bootloader --location=mbr" >> ./$XKS
echo "reboot" >> ./$XKS
echo "zerombr" >> ./$XKS
echo "clearpart --all --drives=xvda" >> ./$XKS
echo "part /boot --fstype ext3 --size=200 --ondisk=xvda" >> ./$XKS
echo "part swap --fstype swap --size=256 --grow --maxsize=1024 --ondisk=xvda" >> ./$XKS
echo "part / --fstype ext4 --size=1024 --grow --ondisk=xvda" >> ./$XKS
echo "%packages" >> ./$XKS
echo "@core" >> ./$XKS
echo "-*firmware" >> ./$XKS
echo "-postfix" >> ./$XKS
echo "sendmail" >> ./$XKS
echo "-b43-openfwwf" >> ./$XKS
echo "%end" >> ./$XKS
echo "%post" >> ./$XKS
echo "mkdir -p /root/.ssh" >> ./$XKS
echo "echo \"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRbxZmL0wIzP6YhzTtL7Gq8XTtn5YlLtsYpVKUHTT2EskGTMVmdF4ja+/qt6rqILf/6w3/HQ2RyYUFv+6QKfk1rI44nLwJ/GVWXe5PD1uzD7LffUESraCrkwaVUCWWy6QMznnHx7BO8AS3il3BYeLq7f82oJLxumILUSks95UdC67wgv8ZUCsWV1gnv00HIJ3hB1fHrwqiTM4KxISwATII0kSQysXFtvdoXbvodneomzs/Si3RW3VduvjcPdBzltJcRlNp/MKlprzqtbOt5fAp/5lzeNwWZZIWiciG+YxC/bOvplJ+/Nf7SKj1vMCLOo9nIjtrNMqScAC8DF70RTG9 tiurbec@sis.easy-cloud.net\" >>/root/.ssh/authorized_keys" >> ./$XKS
echo "echo \"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPHyE25FBeL5PiFyC9sJzvPMYpK8vnibP9rcNX4GZ1qeMsGHt6QNEub2leJhiz+jcjDidoLO/tDZfSy7m95Kft3hPEis9Hjv9hntKbuS9eyDP33vRSM8LNOFW7CATsiUBMY9o7LNvEXaFR4ec/imBg5zsc8fDyL5QwvEwrQaWa2g5h/tN3FWzsgURlUkxmLN5rLu4wcRyRsxk21SgygXAxDRJRe0usHvV0uhKy34NBmmoNd+u0Px8Vlex6Eqi+B/pokHGZg/aYoKe2pSz+Ep0UcC6XoE112jjrpbbrvLwOhH1VgcAOukg9KX1u5PM7VM4/tgCXKu9XJONdPNccEWHV system@expert-accounting.com\" >>/root/.ssh/authorized_keys" >> ./$XKS
echo "echo \"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgwCXyVETsLPU4gNVTyuDv2KzoEGNbDETSU1PK170sPskgQJs4q17Kdh82qiKSOZynSGBE+QRKjtL0+CBU42WYperHFSDGK7CEq60mw+gjZu39eUFmteoLQ3xkahKnyrUuQa77JsBDZqTsMw9sUy62OigkGew82RnkaBDQ73rJRuGJJfv karasz@divto\">>/root/.ssh/authorized_keys" >> ./$XKS
echo "echo \"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5yMJUtJw/vWXu/wvi5W/mQaLPuxPxm5lQbxM5wggO/Ww8xWHfiw9kqB7YBxFrip1NKuLgpKT7Z7L08ak9FlWeYOMQP6UsTnqw5jewRQ8s3Kw/1YT+HjjWHw+QYWBXUgY5whwSrqRwtOHmjk1fbH6U1udDodnCLiwhKwGc6882wNQMzyGGfPKzs55Jb1lcN408zMHlAW9wb7QJhFKzw3iSsuuNjzYi5Gbp5ZYHYGmH8FJOPaJnllgJRkZdyyTh0ZX4JSZUimmKIVb9hC/IlN0qk0YqhSxwJ0MXFkpVxJUKr0a4KZQC2J7xpqGtD3P5SX2MkK0WfFbWiEPA/mWRQiZf monitor@sis.easy-cloud.net\" >>/root/.ssh/authorized_keys" >> ./$XKS
echo "chmod 700 /root/.ssh" >> ./$XKS
echo "chmod 600 /root/.ssh/authorized_keys" >> ./$XKS

if [ $HASPOSTGRES -eq 1 ]
then
 echo "rpm -Uvh \"http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm\"" >> ./$XKS
 echo "yum -y groupinstall \"PostgreSQL Database Server 9.2 PGDG\"" >> ./$XKS
 echo "/etc/init.d/postgresql-9.2 initdb" >> ./$XKS
 echo "echo \"local   all             all                                     trust\" > /var/lib/pgsql/9.2/data/pg_hba.conf" >> ./$XKS
 echo "echo \"host    all             all             127.0.0.1/32            trust\" >>/var/lib/pgsql/9.2/data/pg_hba.conf" >> ./$XKS
 echo "sed -i 's/^\#port\ =\ 5432/port\ =\ 5434/g' /var/lib/pgsql/9.2/data/postgresql.conf" >> ./$XKS
 echo "/etc/init.d/postgresql-9.2 start" >> ./$XKS
 echo "chkconfig postgresql-9.2 on">> ./$XKS
fi
if [ $HASPGBOUNCER -eq 1 ]
then
 echo "yum -y install pgbouncer" >> ./$XKS
 echo "/etc/init.d/pgbouncer start" >> ./$XKS
 echo "chkconfig pgbouncer on" >> ./$XKS
fi
if [ $HASNGINX -eq 1 ]
then
 echo "rpm -Uvh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm" >> ./$XKS
 echo "yum -y install nginx" >> ./$XKS
 echo "### momentan" >> ./$XKS
 echo "rm -f /etc/nginx/conf.d/*" >> ./$XKS
fi
if [ $HASPHP -eq 1 ]
then
 echo "rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm" >> ./$XKS
 echo "rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm" >> ./$XKS
 echo "yum -y --enablerepo=remi install php-fpm php-bcmath php-gd php-mbstring php-mcrypt php-pgsql php-php-gettext php-soap" >> ./$XKS
 echo "sed -i -e 's/apache/nginx/g; s/listen.allowed_clients\ =\ 127.0.0.1/listen.allowed_clients\ =\ 127.0.0.1,10.1.1.7/g; s/^;pm.max_requests\ =\ 500/pm.max_requests\ =\ 500/g' /etc/php-fpm.d/www.conf" >> ./$XKS
 echo "/etc/init.d/php-fpm start" >> ./$XKS
 echo "chkconfig php-fpm on" >> ./$XKS
fi
echo "chkconfig ntpd on" >> ./$XKS
echo "%end" >> ./$XKS

if [ $DEBUG -eq 1 ]
then
#   set
   echo "Creating XRUN ..."
fi
echo "name = \"$DUHOSTNAME\"" > ./$XRUN
echo "kernel = \"/usr/lib/xen/boot/pv-grub-x86_64.gz\"" >> ./$XRUN
echo "extra = \"(hd0,0)/grub/menu.lst console=hvc0\"" >> ./$XRUN
echo "memory = 1024" >> ./$XRUN
echo "maxmem = 2048" >> ./$XRUN
echo "vcpus = 2" >> ./$XRUN
echo "vif = [ 'mac=$DUMAC, bridge=xenbr0, vifname=vif.$DUHOSTNAME' ]" >> ./$XRUN
echo "disk = [ '/dev/vg0/$DUHOSTNAME,raw,xvda,rw' ]" >> ./$XRUN

if [ $DEBUG -eq 1 ]
then
   echo -n "Copying files ... "
fi
cp -f ./$XKS /var/www/html/
if [ $DEBUG -eq 1 ]
then
   echo -n "$XKS "
fi
dd if=./$XINST | ssh -p $HOSTSSHP root@$HOSTIP "dd of=/etc/xen/$XINST"
if [ $DEBUG -eq 1 ]
then
   echo -n "$XINST "
fi
XRUNEXISTS=`ssh -p $HOSTSSHP root@$HOSTIP "ls /etc/xen/$XRUN | wc -l"` 
if [ $XRUNEXISTS -ne 0 ]
then
   echo "$XRUN file is already on Dom0 at $HOSTIP. Are you sure you want to continue installing a new DomU there?"
   exit 1
fi
scp -P $HOSTSSHP ./$XRUN root@$HOSTIP:/etc/xen/$XRUN 
#dd if=./$XRUN | ssh -p $HOSTSSHP root@$HOSTIP dd of=/etc/xen/$XRUN
if [ $DEBUG -eq 1 ]
then
   echo "$XINST "
fi
if [ $DEBUG -eq 1 ]
then
   echo "Checking for lv on Dom0 ..."
fi
LVEXISTS=`ssh -p $HOSTSSHP root@$HOSTIP "lvdisplay | grep /dev/vg0/$DUHOSTNAME | wc -l"`
if [ $LVEXISTS -ne 0 ]
then
   echo "Logical volume /dev/vg0/$DUHOSTNAME already exists on Dom0 at $HOSTIP. Installation HALTED!"
   exit 2
fi
ssh -p $HOSTSSHP root@$HOSTIP "lvcreate -n $DUHOSTNAME -L $LVSIZE /dev/vg0" 
if [ $DEBUG -eq 1 ]
then
   echo "Starting installation for $DUHOSTNAME on $HOSTIP"
fi
ssh -p $HOSTSSHP root@$HOSTIP "xl create -c /etc/xen/$XINST"
ssh -p $HOSTSSHP root@$HOSTIP "xl create /etc/xen/$XRUN"
ssh -p $HOSTSSHP root@$HOSTIP "iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport $DUSSHP -j DNAT --to-destination 10.1.1.$DUID:22"
if [ $HASPOSTGRES -eq 1 ]
then
   ssh -p $HOSTSSHP root@$HOSTIP "iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport $DUPGPORT -j DNAT --to-destination 10.1.1.$DUID:5434"
fi
ssh -p $HOSTSSHP root@$HOSTIP "iptables-save > /etc/sysconfig/iptables"
ssh -p $HOSTSSHP root@$HOSTIP "ln -s /etc/xen/$XRUN /etc/xen/auto/$XRUN"
