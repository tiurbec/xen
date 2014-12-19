#!/bin/bash

if [ -r "/etc/lsb-release" ]; then
        DISTRO=$(grep "DISTRIB_ID" /etc/lsb-release | cut -d'=' -f2)
        echo "This is $DISTRO, i know not much about it, I die."
        exit
fi

[ -r "/etc/SDE-VERSION" ] && cat /etc/SDE-VERSION
[ -r "/etc/VERSION" ] && cat /etc/VERSION

[ -e "/bin/mine" ] || (echo "Awww!!";  exit 1 )

installed(){

arg="$1"
if mine -q $arg 2>&1 | grep -q "GEM"; then
         echo 0
else
        echo 1
fi

}


getver(){

ver=""
arg="$1"
ver=$(mine -q "$arg" | cut -d' ' -f2)
echo $ver

}

echo -e "\nInstalled services:\n"

for pack in lighttpd postgresql pgbouncer nginx php; do
        if [ $(installed $pack) = "1" ]; then
                echo "   " $pack "  version" $(getver $pack)
        fi
done

echo -e "\nService flavors:\n"

if [ $(installed postgresql) = "1" ]; then
  [ -d "/opt/postgresql/bin" ] || echo "  PostgreSQL is FHS"
fi

if [ $(installed nginx) = "1" ]; then
  [ -e "/opt/nginx/sbin/nginx" ] || echo "  NginX is FHS"
fi


if [ $(installed php) = "1" ]; then
   if file "/opt/php/sbin/php-fpm" | grep -q "ELF"; then
        echo "  PHP is FPM"
   fi
fi

