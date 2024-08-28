#!/bin/bash
################################################################################
# COPYRIGHT Ericsson 2017
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
################################################################################

###################################################
# Version no    :  OSS
# Purpose       :  The purpose of this script to run pre-install steps required for netsim_stub installation 
# Jira No       :  EQEV-44613
# Gerrit Link   :
# Description   :  Created the script as a part of the netsim stub
# Date          :  13/11/2017
# Last Modified :  sudheep.mandava@tcs.com
####################################################

HOSTNAME=`hostname`
if [[  "${HOSTNAME}" == "netsim" ]]; then
    IP=`cat /exthostname/IP`
else
    IP=`ip  -f inet a show eth0 | grep inet | awk '{ print $2}' | cut -d/ -f1`
    echo ${IP} | grep "does not exist" > /dev/null
    if [ $? -eq 0 ]; then
       echo " here"
        IP=`ip  -f inet a show net0 | grep inet| awk '{ print $2}'| cut -d/ -f1`
    fi
fi
REAL_FILE_DIR="/ossrc *(rw,sync)"
TOPOLOGY_DIR="/eniq *(rw,sync)"
HOSTFILE="/etc/hosts"
TMP_HOSTFILE="/tmp/hosts_tmp"
RSH_FILE="/etc/pam.d/rsh"
EQIV_FILE="/etc/hosts.equiv"
SECURETTY_FILE="/etc/securetty"
EXPORT_FILE="/etc/exports"

setup_rsh()
{
egrep "$IP netsim" "$HOSTFILE" > /dev/null
if [ $? -ne 0 ];then
    sed '/netsim/d' "$HOSTFILE" > "$TMP_HOSTFILE"
    echo "$IP netsim"  >> "$TMP_HOSTFILE"
    mv "$TMP_HOSTFILE" "$HOSTFILE"
fi

cat "$RSH_FILE" | egrep "#session" | egrep "pam_keyinit.so"  > /dev/null
if [ $? -ne 0 ];then
    sed -i '/pam_keyinit\.so/s/^/#/' "$RSH_FILE"
fi

cat "$RSH_FILE" | egrep "#session" | egrep "pam_loginuid.so"  > /dev/null
if [ $? -ne 0 ];then
    sed -i '/pam_loginuid\.so/s/^/#/' "$RSH_FILE"
fi

echo "+ +" > "$EQIV_FILE"

egrep "rsh" "$SECURETTY_FILE"  > /dev/null
if [ $? -ne 0 ];then
    echo "rsh" >> "$SECURETTY_FILE"
fi

egrep "$IP netsim" ~/.rhosts > /dev/null
if [ $? -ne 0 ];then
    echo "$IP netsim"  >> ~/.rhosts
fi

egrep -w "ossrc" "$EXPORT_FILE" > /dev/null
if [ $? -ne 0 ];then
    echo "$REAL_FILE_DIR" >> "$EXPORT_FILE"
    /etc/init.d/nfs restart > /dev/null
fi

egrep -w "eniq" "$EXPORT_FILE" > /dev/null
if [ $? -ne 0 ];then
    echo "$TOPOLOGY_DIR" >> "$EXPORT_FILE"
    /etc/init.d/nfs restart > /dev/null
fi

}

unmount_dirs()
{

mount | grep pms_tmpfs | cut -d" " -f3 > /tmp/mounted_dirs
while read line
do
    umount $line
done </tmp/mounted_dirs


}
setup_rsh
unmount_dirs

