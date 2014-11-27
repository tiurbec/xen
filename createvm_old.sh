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
#	10 - TESTING mode. Config files were created but nothing applied
#	20 - xlXXX.run file already on Dom0. Installation halted
#	30 - The desired logical volume already exists. Installation halted
if [ $# != 7 ]
then
   cat << EOF
xen virtual machine creator"

 Usage:
  createvm.sh <idhost> <hostip> <hostsshp> <domuhostname> <domuid> <roles> <lvsize>

EOF
   exit 1
fi
#
DEBUG=1
TESTING=1
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
#   set
   echo "Creating XINST ..."
fi
cat <<EOF > ./$XINST
name = "$DUHOSTNAME"
kernel = "/usr/local/xen/vmlinuz"
ramdisk = "/usr/local/xen/initrd.img"
extra = "root=/dev/xvda1 ip=$DUIP netmask=255.255.255.0 gateway=10.1.1.1 dns=8.8.8.8 text ks=http://10.1.1.10/$XKS"
memory = 1024
maxmem = 2048
vcpus = 2
vif = [ 'mac=$DUMAC, bridge=xenbr0' ]
disk = [ '/dev/vg0/$DUHOSTNAME,raw,xvda,rw' ]
on_reboot = 'destroy'
on_crash = 'destroy'
EOF

if [ $DEBUG -eq 1 ]
then
   echo "Creating XKS ..."
fi

cat <<EOF > ./$XKS
install
url --url http://mirror.centos.org/centos/6/os/x86_64/
lang en_US.UTF-8
network --device eth0 --bootproto static --ip=$DUIP --netmask=255.255.255.0 --gateway=10.1.1.1 --nameserver=8.8.8.8,8.8.4.4 --hostname=$DUHOSTNAME
rootpw bogus
firewall --enabled --port=22
authconfig --enableshadow --enablemd5
selinux --disabled
timezone --utc Europe/Bucharest
bootloader --location=mbr
reboot
zerombr
clearpart --all --drives=xvda
part /boot --fstype ext3 --size=200 --ondisk=xvda
part swap --fstype swap --size=256 --grow --maxsize=1024 --ondisk=xvda
part / --fstype ext4 --size=1024 --grow --ondisk=xvda
%packages
@core
-*firmware
-postfix
sendmail
-b43-openfwwf
%end
%post
mkdir -p /root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRbxZmL0wIzP6YhzTtL7Gq8XTtn5YlLtsYpVKUHTT2EskGTMVmdF4ja+/qt6rqILf/6w3/HQ2RyYUFv+6QKfk1rI44nLwJ/GVWXe5PD1uzD7LffUESraCrkwaVUCWWy6QMznnHx7BO8AS3il3BYeLq7f82oJLxumILUSks95UdC67wgv8ZUCsWV1gnv00HIJ3hB1fHrwqiTM4KxISwATII0kSQysXFtvdoXbvodneomzs/Si3RW3VduvjcPdBzltJcRlNp/MKlprzqtbOt5fAp/5lzeNwWZZIWiciG+YxC/bOvplJ+/Nf7SKj1vMCLOo9nIjtrNMqScAC8DF70RTG9 tiurbec@sis.easy-cloud.net" >>/root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPHyE25FBeL5PiFyC9sJzvPMYpK8vnibP9rcNX4GZ1qeMsGHt6QNEub2leJhiz+jcjDidoLO/tDZfSy7m95Kft3hPEis9Hjv9hntKbuS9eyDP33vRSM8LNOFW7CATsiUBMY9o7LNvEXaFR4ec/imBg5zsc8fDyL5QwvEwrQaWa2g5h/tN3FWzsgURlUkxmLN5rLu4wcRyRsxk21SgygXAxDRJRe0usHvV0uhKy34NBmmoNd+u0Px8Vlex6Eqi+B/pokHGZg/aYoKe2pSz+Ep0UcC6XoE112jjrpbbrvLwOhH1VgcAOukg9KX1u5PM7VM4/tgCXKu9XJONdPNccEWHV system@expert-accounting.com" >>/root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgwCXyVETsLPU4gNVTyuDv2KzoEGNbDETSU1PK170sPskgQJs4q17Kdh82qiKSOZynSGBE+QRKjtL0+CBU42WYperHFSDGK7CEq60mw+gjZu39eUFmteoLQ3xkahKnyrUuQa77JsBDZqTsMw9sUy62OigkGew82RnkaBDQ73rJRuGJJfv karasz@divto">>/root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5yMJUtJw/vWXu/wvi5W/mQaLPuxPxm5lQbxM5wggO/Ww8xWHfiw9kqB7YBxFrip1NKuLgpKT7Z7L08ak9FlWeYOMQP6UsTnqw5jewRQ8s3Kw/1YT+HjjWHw+QYWBXUgY5whwSrqRwtOHmjk1fbH6U1udDodnCLiwhKwGc6882wNQMzyGGfPKzs55Jb1lcN408zMHlAW9wb7QJhFKzw3iSsuuNjzYi5Gbp5ZYHYGmH8FJOPaJnllgJRkZdyyTh0ZX4JSZUimmKIVb9hC/IlN0qk0YqhSxwJ0MXFkpVxJUKr0a4KZQC2J7xpqGtD3P5SX2MkK0WfFbWiEPA/mWRQiZf monitor@sis.easy-cloud.net" >>/root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
EOF

if [ $HASPOSTGRES -eq 1 ]
then
cat <<EOF >> ./$XKS
rpm -Uvh "http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm"
yum -y groupinstall "PostgreSQL Database Server 9.2 PGDG"
/etc/init.d/postgresql-9.2 initdb
echo "local   all             all                                     trust" > /var/lib/pgsql/9.2/data/pg_hba.conf
echo "host    all             all             127.0.0.1/32            trust" >>/var/lib/pgsql/9.2/data/pg_hba.conf
sed -i 's/^\#port\ =\ 5432/port\ =\ 5434/g' /var/lib/pgsql/9.2/data/postgresql.conf
/etc/init.d/postgresql-9.2 start
chkconfig postgresql-9.2 on
EOF
fi
if [ $HASPGBOUNCER -eq 1 ]
then
cat <<EOF >> ./$XKS
yum -y install pgbouncer
/etc/init.d/pgbouncer start
chkconfig pgbouncer on
EOF
fi
if [ $HASNGINX -eq 1 ]
then
cat <<EOF >> ./$XKS
rpm -Uvh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
yum -y install nginx
### momentan
rm -f /etc/nginx/conf.d/*
EOF
fi
if [ $HASPHP -eq 1 ]
then
cat <<EOF >> ./$XKS
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
yum -y --enablerepo=remi install php-fpm php-bcmath php-gd php-mbstring php-mcrypt php-pgsql php-php-gettext php-soap
sed -i -e 's/apache/nginx/g; s/listen.allowed_clients\ =\ 127.0.0.1/listen.allowed_clients\ =\ 127.0.0.1,10.1.1.7/g; s/^;pm.max_requests\ =\ 500/pm.max_requests\ =\ 500/g' /etc/php-fpm.d/www.conf
/etc/init.d/php-fpm start
chkconfig php-fpm on
EOF
fi
echo "chkconfig ntpd on" >> ./$XKS
echo "%end" >> ./$XKS

if [ $DEBUG -eq 1 ]
then
#   set
   echo "Creating XRUN ..."
fi
cat <<EOF > ./$XRUN
name = "$DUHOSTNAME"
kernel = "/usr/lib/xen/boot/pv-grub-x86_64.gz"
extra = "(hd0,0)/grub/menu.lst console=hvc0"
memory = 1024
maxmem = 2048
vcpus = 2
vif = [ 'mac=$DUMAC, bridge=xenbr0, vifname=vif.$DUHOSTNAME' ]
disk = [ '/dev/vg0/$DUHOSTNAME,raw,xvda,rw' ]
EOF

if [ $TESTING -eq 1 ]
then
   echo "Config files created. Exiting without applying them."
   exit 10
fi

if [ $DEBUG -eq 1 ]
then
   echo -n "Copying files ... "
fi
cp -f ./$XKS /var/www/html/
if [ $DEBUG -eq 1 ]
then
   echo -n "$XKS "
fi
scp -P $HOSTSSHP ./$XINST root@$HOSTIP:/etc/xen/$XINST
if [ $DEBUG -eq 1 ]
then
   echo -n "$XINST "
fi
XRUNEXISTS=`ssh -p $HOSTSSHP root@$HOSTIP "ls /etc/xen/$XRUN | wc -l"` 
if [ $XRUNEXISTS -ne 0 ]
then
   echo "$XRUN file is already on Dom0 at $HOSTIP. Are you sure you want to continue installing a new DomU there?"
   exit 20
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
   exit 30
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