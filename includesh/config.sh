#!/bin/sh

#SSHOPTS="-q -T -o \"PasswordAuthentication no\" -o \"StrictHostKeyChecking no\" -o \"BatchMode yes\" -o \"ConnectTimeout 5\""
SSHOPTS=' -q -T -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=4 '
SSHPOST=' </dev/null 2>/dev/null'
HOSTLIST='/root/hosts.spc'
ZAFILES='/root/git/xen/files/'


function errecho ()
{
   >&2 echo "${FUNCNAME[ 1 ]} -> $@"
}
