#!/bin/bash

################################################################################
# COPYRIGHT Ericsson 2016
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
################################################################################

###################################################
# Version no    :  NSS 17.10
# Purpose       :  Script is responsible to add crontab entry for STATS as well as EVENTS ROP generation for all Nodes types supported by PMS
# Jira No       :  NSS-12035 
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2363479/
# Description   :  Support for NRM3
# Date          :  12/06/2017
# Last Modified :  arwa.nawab@tcs.com
####################################################

#This script is responsible to add crontab entry for STATS as well as EVENTS ROP generation as per configuration in netsim_cfg file.

BIN_DIR=`dirname $0`
BIN_DIR=`cd ${BIN_DIR} ; pwd`
. ${BIN_DIR}/functions

CONFIGFILE=/netsim/netsim_cfg
while getopts  "s:c:b:" flag
do
    case "$flag" in

    c) CONFIGFILE="$OPTARG";;
    s) SERVER_LIST="$OPTARG";;
    b) BULK_PM_ENABLED="$OPTARG";;
    *) printf "Usage: %s < -c configfile > <-s serverlist>\n" $0
           exit 1;;
    esac
done
if [ ! -r ${CONFIGFILE} ] ; then
    echo "ERROR: Cannot find ${CONFIGFILE}"
    exit 1
fi

. ${CONFIGFILE} > /dev/null 2>&1
if [ ! -z "${SERVER_LIST}" ] ; then
    SERVERS="${SERVER_LIST}"
fi



# STATS_WORKLOAD_LIST variable is must as this defines the rop configuration if not present then log
# message and exit the program execution.
if [ -z "${STATS_WORKLOAD_LIST}" ] ; then
    log "Variable STATS_WORKLOAD_LIST not found or not set in config file hence STATS rollout cannot be done"
    exit 1
fi


NETSIM_BIN_DIR=/netsim_users/pms/bin
NETSIM_LOG_DIR=/netsim_users/pms/logs
HOST=`hostname`
HOST_NAME=`echo $HOST`

for SERVER in $SERVERS ; do
    log "INFO: Templates"
    ${BIN_DIR}/rollout_xml_templates.sh -c ${CONFIGFILE} -s ${SERVER}
    if [ $? -ne 0 ] ;then
    log "ERROR: Template rollout failed for ${SERVER}"
    exit 1
    fi

    #  STATS_WORKLOAD_LIST=<ROP Interval>:<NE_TYPE/ALL[,NE_TYPE ..]>
    log "INFO: Crontab"
    /usr/bin/rsh -l netsim ${SERVER} "crontab -l | egrep -v '^# |genStats|rmPmFiles|getStartedNodes|removeLogFiles.py|startPlaybacker.sh' > /tmp/_new_crontab"

    if [ "${HOST_NAME}" = "netsim" ]; then
        /usr/bin/rsh -l netsim ${SERVER} "echo \"4,9,14,19,24,29,34,39,44,49,54,59 * * * * ${NETSIM_BIN_DIR}/getStartedNodes \" >> /tmp/_new_crontab"
    elif [ "${TYPE}" = "NSS" ]; then
        /usr/bin/rsh -l netsim ${SERVER} "echo \"14,29,44,59 * * * * ${NETSIM_BIN_DIR}/getStartedNodes \" >> /tmp/_new_crontab"
    fi
    if [ "${BULK_PM_ENABLED}" != "True" ]; then 
    for STATS_WORKLOAD in $STATS_WORKLOAD_LIST; do
        ROP_PERIOD=`echo ${STATS_WORKLOAD} | awk -F: '{print $1}'`
        NE_TYPES=`echo ${STATS_WORKLOAD} | awk -F: '{print $2}'`

        #Added HOUR_FIELD to support for 24hrs ROP generation.
        case "${ROP_PERIOD}" in
             1) MINUTE_FIELD="*";HOUR_FIELD="*";;
             5) MINUTE_FIELD="0,5,10,15,20,25,30,35,40,45,50,55";HOUR_FIELD="*";;
            15) MINUTE_FIELD="0,15,30,45";HOUR_FIELD="*";;
            60) MINUTE_FIELD="0";HOUR_FIELD="*";;
            1440) MINUTE_FIELD="0";HOUR_FIELD="0";;
             *) printf " Invalid ROP interval : ${ROP_PERIOD} \n" $0
             exit 1;;
        esac

        if [ ${NE_TYPES} = "ALL" ] ; then

            /usr/bin/rsh -l netsim ${SERVER} "echo \"${MINUTE_FIELD} ${HOUR_FIELD} * * * ${NETSIM_BIN_DIR}/genStats -r ${ROP_PERIOD} >> ${NETSIM_LOG_DIR}/genStats_${ROP_PERIOD}min.log 2>&1 \" >> /tmp/_new_crontab"

            /usr/bin/rsh -l netsim ${SERVER} "echo \"${MINUTE_FIELD} ${HOUR_FIELD} * * * ${NETSIM_BIN_DIR}/startPlaybacker.sh -r ${ROP_PERIOD} >> ${NETSIM_LOG_DIR}/playbacker_${ROP_PERIOD}min.log 2>&1 \" >> /tmp/_new_crontab"
        else

            NE_TYPES=$(echo $NE_TYPES | sed 's/,/ /g')
            CMD="${MINUTE_FIELD} ${HOUR_FIELD} * * * ${NETSIM_BIN_DIR}/genStats -r ${ROP_PERIOD} -l \\\"${NE_TYPES}\\\""
            /usr/bin/rsh -l netsim ${SERVER} "echo \"${CMD}  >> ${NETSIM_LOG_DIR}/genStats_${ROP_PERIOD}min.log 2>&1 \" >> /tmp/_new_crontab"

            CMD_Playbacker="${MINUTE_FIELD} ${HOUR_FIELD} * * * ${NETSIM_BIN_DIR}/startPlaybacker.sh -r ${ROP_PERIOD} -l \\\"${NE_TYPES}\\\""
            /usr/bin/rsh -l netsim ${SERVER} "echo \"${CMD_Playbacker}  >> ${NETSIM_LOG_DIR}/playbacker_${ROP_PERIOD}min.log 2>&1 \" >> /tmp/_new_crontab"
        fi
    done

    /usr/bin/rsh -l netsim ${SERVER} "echo \"0 * * * * ${NETSIM_BIN_DIR}/rmPmFiles >> ${NETSIM_LOG_DIR}/rmFiles.log 2>&1 \" >> /tmp/_new_crontab"

    fi

    /usr/bin/rsh -l netsim ${SERVER} "crontab /tmp/_new_crontab"
done

if [ ! -z "${LOG_FILE_RETENTION}" ] ; then

   if [ "${LOG_FILE_RETENTION}" -gt "23" ] ; then
        REMOVAL_TIME_IN_DAYS="*/"$((${LOG_FILE_RETENTION}/24))
        REMOVAL_TIME_IN_HOURS="*"
   else
        REMOVAL_TIME_IN_DAYS="*"
        REMOVAL_TIME_IN_HOURS="*/"${LOG_FILE_RETENTION}
   fi
   /usr/bin/rsh -l netsim ${SERVER} "echo \"0 ${REMOVAL_TIME_IN_HOURS} ${REMOVAL_TIME_IN_DAYS} * * ${NETSIM_BIN_DIR}/removeLogFiles.py \" >> /tmp/_new_crontab"
   /usr/bin/rsh -l netsim ${SERVER} "crontab /tmp/_new_crontab"
fi
