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
# Version no    :  NSS 18.1
# Purpose       :  The script is responsible for generation of metadata of PM Files in CSV format
# Jira No       :  EQEV-44371
# Description   :  genaration of csv file for input of FLS
# Date          :  12/01/2017
# Last Modified :  d.nadkarni@tcs.com
####################################################

PM_ROP_INFO_FILE="/netsim/etc/Pm_Rop_Info.txt"
META_DATA_FILE="/netsim/etc/csv/Pm_Rop_Info.csv"
FLS_STARTUP_SCRIPT="/fls/fls_client/bin/startup.sh"

#
# Main
#

if [ ! -s ${PM_ROP_INFO_FILE} ]; then
    echo " `date -u "+%Y/%m/%d %H:%M"` : There is no ROPs to process in ${PM_ROP_INFO_FILE} "
    exit 1
fi

for file in `cat ${PM_ROP_INFO_FILE}`;
    do
    filename=${file#*segment1/}
    filename=${filename%_*}
    subnetwork=${filename#*_}
    echo -n $subnetwork'|' >> ${META_DATA_FILE}
    nodeName=${subnetwork#*MeContext=}
    if [[ ( $nodeName == *"dg2"* ) || ( $nodeName == *"MSRBS-V2"* ) ]]; then
        neType="MSRBS-V2"
    elif [[ $nodeName == *"pERBS"* ]];  then
        neType="MSRBS-V1"
    elif [[ $nodeName == *"ERBS"* ]];  then
        neType="ERBS"
    elif [[ $nodeName == *"PRBS"* ]];  then
        neType="PRBS"
    elif [[ $nodeName == *"RBS"* ]];  then
        neType="RBS"
    elif [[ $nodeName == "RNC"* ]];  then
        neType="RNC"
    else
        echo " `date -u "+%Y/%m/%d %H:%M"` : no NeType found for ${filename}"
        sed -i '1,1 d' ${PM_ROP_INFO_FILE}
        continue
    fi

    echo -n $neType'|' >> ${META_DATA_FILE}
    echo -n PM_STATISTICAL'|' >> ${META_DATA_FILE}
    echo -n xml'|' >> ${META_DATA_FILE}
    fileSize=`ls -l $file | cut -d' ' -f5` 2> /dev/null
    echo -n  $fileSize'|' >> ${META_DATA_FILE}
    echo -n $file'|' >> ${META_DATA_FILE}
    if [[ "${filename:14:1}" == "+" ]]; then
        rop_start=${filename:1:${#filename}}
        rop_start=${rop_start:0:18}
        rop_start=${rop_start/./T}
        rop_start=${rop_start:0:4}-${rop_start:4:2}-${rop_start:6:2}${rop_start:8:3}:${rop_start:11:2}:00${rop_start:13:3}:${rop_start:16:3}
        rop_end=${rop_start:0:11}${filename:20:9}
        rop_end=${rop_end:0:13}:${rop_end:13:2}:00${rop_end:15:3}:${rop_end:18:2}
        echo -n $rop_start'|' >> ${META_DATA_FILE}
        echo -n $rop_start'|' >> ${META_DATA_FILE}
        echo -n $rop_end  >> ${META_DATA_FILE}
    else
        rop_start=${filename:1:${#filename}}
        rop_start=${rop_start:0:13}
        rop_start=${rop_start/./T}
        rop_start=${rop_start:0:4}-${rop_start:4:2}-${rop_start:6:2}${rop_start:8:3}:${rop_start:11:2}:00+00:00
        rop_end=${rop_start:0:11}${filename:15:4}
        rop_end=${rop_end:0:13}:${rop_end:13:2}:00+00:00
        echo -n $rop_start'|' >> ${META_DATA_FILE}
        echo -n $rop_start'|' >> ${META_DATA_FILE}
        echo -n $rop_end  >> ${META_DATA_FILE}
    fi
    echo "" >> ${META_DATA_FILE}
    sed -i '1,1 d' ${PM_ROP_INFO_FILE}
    done

if [ -e $FLS_STARTUP_SCRIPT ]; then
    $FLS_STARTUP_SCRIPT
else
    echo " `date -u "+%Y/%m/%d %H:%M"` : No FLS setup on the sever"
fi

