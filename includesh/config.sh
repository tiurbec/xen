#!/bin/sh

#SSHOPTS="-q -T -o \"PasswordAuthentication no\" -o \"StrictHostKeyChecking no\" -o \"BatchMode yes\" -o \"ConnectTimeout 5\""
SSHOPTS=' -q -T -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=1 '
SSHPOST=' </dev/null 2>/dev/null'
HOSTLIST='/root/hosts.spc'


function errecho ()
{
   >&2 echo "${FUNCNAME[ 1 ]} -> $@"
}
