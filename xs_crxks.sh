#!/bin/sh
# xs_xks.sh - 	Creates xlXXX.ks file for Xen virtual machines
#		Part of createvm @ ExpertSoftware
#
#

if [ $# != 5 ]
then
   cat << EOF
xen virtual machine kickstart file creator"

 Usage:
  $0 <domuHostname> <domuIP> <domuKickStart> <roles> <CentOSmirrorURL>

EOF
   exit 1
fi

DUHOSTNAME=$1
DUIP=$2
XKS=$3
ROLES=$4
CENTOSMIRROR=$5
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

cat <<EOF > ./$XKS
install
url --url $CENTOSMIRROR
lang en_US.UTF-8
network --device eth0 --bootproto static --ip=$DUIP --netmask=255.255.255.0 --gateway=10.1.1.254 --nameserver=8.8.8.8,8.8.4.4 --hostname=$DUHOSTNAME
rootpw --iscrypted "\$1\$zi/J1\$XxeaJrprUlKo28fJwxVpc/"
firewall --enabled --port=22
authconfig --enableshadow --enablemd5
selinux --disabled
timezone --utc Europe/Bucharest
bootloader --location=none
reboot
zerombr
#clearpart --all --drives=xvda,xvdb,xvdc
#part /boot --fstype ext4 --size=200 --ondisk=xvdb
#part swap --fstype swap --size=256 --grow --maxsize=1024 --ondisk=xvdc
#part / --fstype ext4 --size=1024 --grow --ondisk=xvda
part /boot --fstype ext4 --onpart=xvda1
part swap --fstype swap --onpart=xvda2
part / --fstype ext4 --onpart=xvda3


%packages
@core
-*firmware
-postfix
sendmail
-b43-openfwwf
%end
%post
echo "default=0" >/boot/grub/menu.lst
echo "timeout=5" >>/boot/grub/menu.lst
echo "splashimage=(hd0)/grub/splash.xpm.gz" >>/boot/grub/menu.lst
echo "hiddenmenu" >>/boot/grub/menu.lst
echo "title CentOS 6 (2.6.32-504.el6.x86_64)" >>/boot/grub/menu.lst
echo "	root (hd0)" >>/boot/grub/menu.lst
echo "	kernel /vmlinuz-2.6.32-504.el6.x86_64 ro root=/dev/xvda3 rd_NO_LUKS LANG=en_US.UTF-8 rd_NO_MD console=hvc0  KEYTABLE=us SYSFONT=latarcyrheb-sun16 crashkernel=auto rd_NO_LVM rd_NO_DM rhgb quiet" >>/boot/grub/menu.lst
echo "	initrd /initramfs-2.6.32-504.el6.x86_64.img" >>/boot/grub/menu.lst

yum -y install centos-release-xen
yum -y install kernel

VMLINUZ=\$(ls /boot/vmlinuz-* | sort | tail -1 | sed s/\\\\/boot//)
INITRAMFS=\$(ls /boot/initramfs-* | sort | tail -1 | sed s/\\\\/boot//)
KVERSION=\$(echo "\$INITRAMFS" | sed s/\\\\/initramfs-// | sed s/.img//)
echo "title CentOS 6 (\$KVERSION)" >>/boot/grub/menu.lst
echo "  root (hd0)" >>/boot/grub/menu.lst
echo "  kernel \$VMLINUZ ro root=/dev/xvda3 rd_NO_LUKS LANG=en_US.UTF-8 rd_NO_MD console=hvc0  KEYTABLE=us SYSFONT=latarcyrheb-sun16 crashkernel=auto rd_NO_LVM rd_NO_DM rhgb quiet" >>/boot/grub/menu.lst
echo "  initrd \$KVERSION" >>/boot/grub/menu.lst
sed -i 's/default=0/default=1/' /boot/grub/menu.lst



mkdir -p /root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRbxZmL0wIzP6YhzTtL7Gq8XTtn5YlLtsYpVKUHTT2EskGTMVmdF4ja+/qt6rqILf/6w3/HQ2RyYUFv+6QKfk1rI44nLwJ/GVWXe5PD1uzD7LffUESraCrkwaVUCWWy6QMznnHx7BO8AS3il3BYeLq7f82oJLxumILUSks95UdC67wgv8ZUCsWV1gnv00HIJ3hB1fHrwqiTM4KxISwATII0kSQysXFtvdoXbvodneomzs/Si3RW3VduvjcPdBzltJcRlNp/MKlprzqtbOt5fAp/5lzeNwWZZIWiciG+YxC/bOvplJ+/Nf7SKj1vMCLOo9nIjtrNMqScAC8DF70RTG9 tiurbec@sis.easy-cloud.net" >>/root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPHyE25FBeL5PiFyC9sJzvPMYpK8vnibP9rcNX4GZ1qeMsGHt6QNEub2leJhiz+jcjDidoLO/tDZfSy7m95Kft3hPEis9Hjv9hntKbuS9eyDP33vRSM8LNOFW7CATsiUBMY9o7LNvEXaFR4ec/imBg5zsc8fDyL5QwvEwrQaWa2g5h/tN3FWzsgURlUkxmLN5rLu4wcRyRsxk21SgygXAxDRJRe0usHvV0uhKy34NBmmoNd+u0Px8Vlex6Eqi+B/pokHGZg/aYoKe2pSz+Ep0UcC6XoE112jjrpbbrvLwOhH1VgcAOukg9KX1u5PM7VM4/tgCXKu9XJONdPNccEWHV system@expert-accounting.com" >>/root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgwCXyVETsLPU4gNVTyuDv2KzoEGNbDETSU1PK170sPskgQJs4q17Kdh82qiKSOZynSGBE+QRKjtL0+CBU42WYperHFSDGK7CEq60mw+gjZu39eUFmteoLQ3xkahKnyrUuQa77JsBDZqTsMw9sUy62OigkGew82RnkaBDQ73rJRuGJJfv karasz@divto">>/root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5yMJUtJw/vWXu/wvi5W/mQaLPuxPxm5lQbxM5wggO/Ww8xWHfiw9kqB7YBxFrip1NKuLgpKT7Z7L08ak9FlWeYOMQP6UsTnqw5jewRQ8s3Kw/1YT+HjjWHw+QYWBXUgY5whwSrqRwtOHmjk1fbH6U1udDodnCLiwhKwGc6882wNQMzyGGfPKzs55Jb1lcN408zMHlAW9wb7QJhFKzw3iSsuuNjzYi5Gbp5ZYHYGmH8FJOPaJnllgJRkZdyyTh0ZX4JSZUimmKIVb9hC/IlN0qk0YqhSxwJ0MXFkpVxJUKr0a4KZQC2J7xpqGtD3P5SX2MkK0WfFbWiEPA/mWRQiZf monitor@sis.easy-cloud.net" >>/root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

#Adding zabbix
rpm -Uvh "http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm"
yum -y install zabbix-agent
chkconfig zabbix-agent on
service  zabbix-agent restart
EOF

if [ $HASPOSTGRES -eq 1 ]
then
cat <<EOF >> ./$XKS
rpm -Uvh "http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm"
yum -y groupinstall "PostgreSQL Database Server 9.2 PGDG"
/etc/init.d/postgresql-9.2 initdb
echo "local   all             all                                     trust" > /var/lib/pgsql/9.2/data/pg_hba.conf
echo "host    all             all             127.0.0.1/32            trust" >>/var/lib/pgsql/9.2/data/pg_hba.conf
echo "host    all             all             10.1.1.0/24             trust" >>/var/lib/pgsql/9.2/data/pg_hba.conf
sed -i 's/^\#port\ =\ 5432/port\ =\ 5434/g' /var/lib/pgsql/9.2/data/postgresql.conf
echo "#Override port" >/etc/sysconfig/pgsql/postgresql-9.2
echo "PGPORT=5434" >>/etc/sysconfig/pgsql/postgresql-9.2
cat <<'PGCNF' > /var/lib/pgsql/9.2/data/postgresql.conf
listen_addresses = '*'
port = 5434	
max_connections = 100
shared_buffers = 48MB
fsync=on
checkpoint_segments = 50
log_destination = 'stderr'
logging_collector = on	
log_directory = 'pg_log'
log_filename = 'postgresql-%a.log'
log_truncate_on_rotation = on	
log_rotation_age = 1d	
log_rotation_size = 0
log_timezone = 'Europe/Bucharest'
datestyle = 'iso, mdy'
timezone = 'Europe/Bucharest'
lc_messages = 'en_US.UTF-8'	
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'	
default_text_search_config = 'pg_catalog.english'

wal_level = 'hot_standby'
archive_mode = on
archive_command = 'cd .'

max_wal_senders = 10
wal_keep_segments = 500
hot_standby = on
PGCNF
/etc/init.d/postgresql-9.2 start
chkconfig postgresql-9.2 on
EOF
fi
if [ $HASPGBOUNCER -eq 1 ]
then
cat <<EOF >> ./$XKS
rpm -Uvh "http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm"
yum -y install pgbouncer
/etc/init.d/pgbouncer start
chkconfig pgbouncer on
EOF
fi
if [[ $HASPOSTGRES -eq 0 && $HASPGBOUNCER -eq 1 ]];
then
adduser postgres
chsh -s /sbin/nologin postgres
fi
if [[ $HASNGINX -eq 1 && $HASPOSTGRES -eq 0 ]];
then
rpm -Uvh "http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm"
yum -y install postgresql92
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
yum -y --enablerepo=remi install php-fpm php-bcmath php-gd php-mbstring php-mcrypt php-pgsql php-php-gettext php-soap php-xml
sed -i -e 's/apache/nginx/g; s/listen.allowed_clients\ =\ 127.0.0.1/listen.allowed_clients\ =\ 127.0.0.1,10.1.1.7/g; s/^;pm.max_requests\ =\ 500/pm.max_requests\ =\ 500/g' /etc/php-fpm.d/www.conf
/etc/init.d/php-fpm start
chkconfig php-fpm on
EOF
fi

echo "chkconfig ntpd on" >> ./$XKS
echo "%end" >> ./$XKS

