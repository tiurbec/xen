# Let's prepare Dom0 for xen on Centos 6.6
if [ $# -ne 3 ];
then
  echo "Use: $0 <hostname> <ip> <port>"
  exit 0
fi
HOSTNAME=$1
IP=$2
SSHPORT=$3
SSHPARAMS=" -p $SSHPORT root@$IP "

echo "Preparing $HOSTNAME[$IP] to be Dom0 ..."

echo "Installing /root/.ssh/authorized_keys"
cat <<'EOF' | ssh $SSHPARAMS 'cat >> /root/.ssh/authorized_keys'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRbxZmL0wIzP6YhzTtL7Gq8XTtn5YlLtsYpVKUHTT2EskGTMVmdF4ja+/qt6rqILf/6w3/HQ2RyYUFv+6QKfk1rI44nLwJ/GVWXe5PD1uzD7LffUESraCrkwaVUCWWy6QMznnHx7BO8AS3il3BYeLq7f82oJLxumILUSks95UdC67wgv8ZUCsWV1gnv00HIJ3hB1fHrwqiTM4KxISwATII0kSQysXFtvdoXbvodneomzs/Si3RW3VduvjcPdBzltJcRlNp/MKlprzqtbOt5fAp/5lzeNwWZZIWiciG+YxC/bOvplJ+/Nf7SKj1vMCLOo9nIjtrNMqScAC8DF70RTG9 tiurbec@sis.easy-cloud.net
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgwCXyVETsLPU4gNVTyuDv2KzoEGNbDETSU1PK170sPskgQJs4q17Kdh82qiKSOZynSGBE+QRKjtL0+CBU42WYperHFSDGK7CEq60mw+gjZu39eUFmteoLQ3xkahKnyrUuQa77JsBDZqTsMw9sUy62OigkGew82RnkaBDQ73rJRuGJJfv karasz@divto
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5yMJUtJw/vWXu/wvi5W/mQaLPuxPxm5lQbxM5wggO/Ww8xWHfiw9kqB7YBxFrip1NKuLgpKT7Z7L08ak9FlWeYOMQP6UsTnqw5jewRQ8s3Kw/1YT+HjjWHw+QYWBXUgY5whwSrqRwtOHmjk1fbH6U1udDodnCLiwhKwGc6882wNQMzyGGfPKzs55Jb1lcN408zMHlAW9wb7QJhFKzw3iSsuuNjzYi5Gbp5ZYHYGmH8FJOPaJnllgJRkZdyyTh0ZX4JSZUimmKIVb9hC/IlN0qk0YqhSxwJ0MXFkpVxJUKr0a4KZQC2J7xpqGtD3P5SX2MkK0WfFbWiEPA/mWRQiZf monitor@sis.easy-cloud.net
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwot7GHBhswQexXk3kHCRS9igSkqKAb4MhNH2dMYz5CtQumaq9Qd0qyOeCXWrZ60+DmNfd5JTTsDwayRmgPe1evrZVEkzKuTBQkhkZDhuOpvpF3sEH4VQTX2qc/Ud0D0mC9ymPXAQbHj0uoWOJiF6VEyfrDl/6pF0fEUyCbzST5MnNOOScJ/eZByPNzerIK1K76S0CEcYxPV9N0NhOe7vyvC41d9RmwpUs64spHTcNROkRrypGS4s/RMTQpcqB5syBwEdCk3Iv21ha5Clv3YVG0rleqHSJ5TBqkspTiS2m61srWwSLwU8pqbIFfHablhwswmpyy2q8W5zvelT6ZpwEQ== root@tiurbec
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPHyE25FBeL5PiFyC9sJzvPMYpK8vnibP9rcNX4GZ1qeMsGHt6QNEub2leJhiz+jcjDidoLO/tDZfSy7m95Kft3hPEis9Hjv9hntKbuS9eyDP33vRSM8LNOFW7CATsiUBMY9o7LNvEXaFR4ec/imBg5zsc8fDyL5QwvEwrQaWa2g5h/tN3FWzsgURlUkxmLN5rLu4wcRyRsxk21SgygXAxDRJRe0usHvV0uhKy34NBmmoNd+u0Px8Vlex6Eqi+B/pokHGZg/aYoKe2pSz+Ep0UcC6XoE112jjrpbbrvLwOhH1VgcAOukg9KX1u5PM7VM4/tgCXKu9XJONdPNccEWHV system@expert-accounting.com
EOF
ssh $SSHPARAMS "chmod 600 /root/.ssh/authorized_keys"

ssh $SSHPARAMS "yum -y install centos-release-xen"
ssh $SSHPARAMS "yum -y install xen"

echo "Rebooting"
ssh $SSHPARAMS "reboot"
sleep 20
while ! ssh $SSHPARAMS "pwd"
do
    echo "Waiting for Dom0 to boot up..." >&2
done

echo -n "Installed kernel is: "
ssh $SSHPARAMS "uname -r"
echo "xl info"
ssh $SSHPARAMS "xl info"
echo "Turning off xend..."
ssh $SSHPARAMS "service xend stop;chkconfig xend off"

ssh $SSHPARAMS "wget http://mirror.centos.org/centos/6/os/x86_64/images/pxeboot/initrd.img -O /usr/local/xen/initrd.img;wget http://mirror.centos.org/centos/6/os/x86_64/images/pxeboot/vmlinuz -O /usr/local/xen/vmlinuz"

echo "Setting up xenbr0..."
ssh $SSHPARAMS "brctl addbr xenbr0;ip addr add 10.1.1.254/24 dev xenbr0;ifconfig xenbr0 up"

cat <<'EOF' | ssh $SSHPARAMS 'cat > /etc/sysconfig/network-scripts/ifcfg-xenbr0'
DEVICE=xenbr0
TYPE=Bridge
BOOTPROTO=none
ONBOOT=yes
#HWADDR=00:1E:67:AD:4F:93
IPADDR=10.1.1.254
NETMASK=255.255.255.0
EOF

echo "Updating /etc/hosts ..."
ssh $SSHPARAMS "echo \"$IP	$HOSTNAME\" >> /etc/hosts"
echo "Updating /etc/sysconfig/network ..."
ssh $SSHPARAMS "sed -i -e s/^HOSTNAME.*/HOSTNAME=$HOSTNAME/ /etc/sysconfig/network"
echo "Updating /etc/sysctl.conf ..."
ssh $SSHPARAMS "sed -i -e s/^#net\.ipv4\.ip_forward.*/net\.ipv4\.ip_forward\ =\ 1/ /etc/sysctl.conf" 
echo "Rewriting iptables rules ..."
ssh $SSHPARAMS "iptables -F"
ssh $SSHPARAMS "iptables -t filter -A INPUT -i eth0 -p tcp -m tcp --dport 2200 -j ACCEPT"
ssh $SSHPARAMS "iptables -t filter -A INPUT -i eth0 -p tcp -m tcp --dport 22 -j ACCEPT" 
ssh $SSHPARAMS "iptables -t filter -A INPUT -i eth0 -p tcp -m tcp --dport 80 -j ACCEPT "
ssh $SSHPARAMS "iptables -t filter -A INPUT -i eth0 -p tcp -m tcp --dport 443 -j ACCEPT "
ssh $SSHPARAMS "iptables -t filter -A INPUT -p icmp -j ACCEPT"
ssh $SSHPARAMS "iptables -t filter -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT"
ssh $SSHPARAMS "iptables -t filter -A INPUT -i eth0 -j DROP"
ssh $SSHPARAMS "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
ssh $SSHPARAMS "iptables-save > /etc/sysconfig/iptables"
echo "Updating /etc/ssh/sshd_config ..."
ssh $SSHPARAMS "sed -i -e s/#UseDNS\ yes/UseDNS\ no/ /etc/ssh/sshd_config"
ssh $SSHPARAMS "sed -i -e s/#Port\ 22/Port\ 2200/ /etc/ssh/sshd_config"
echo "Restarting SSH on new port 2200 ..."
ssh $SSHPARAMS "service sshd restart"
SSHPARAMS=" -p 3200 root@$IP "
echo "Restarting iptables ..."
ssh $SSHPARAMS "service iptables restart;chkconfig iptables on"
echo "Installing nginx ..."
ssh $SSHPARAMS "rpm -Uvh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm"
ssh $SSHPARAMS "yum -y install nginx"
ssh $SSHPARAMS "chkconfig nginx on"
echo "Activating xendomains ..."
ssh $SSHPARAMS "chkconfig xendomains on"
echo "Done."
echo "!!! Patch xendomains by hand and restart the service !!!"
echo "Bye!"
