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
# Version no    :  NSS 17.13
# Purpose       :  Script is responsible for EVENTS file generation for UETR and CTR Node Types as supported by PMS
# Jira No       :  NSS-12720
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2446296/9
# Description   :  Genstat support for (TORF-198512) Add WCDMA Pico pRBS 16A, 17A and 17B simulation
# Date          :  20/07/2017
# Last Modified :  tejas.lutade@tcs.com
####################################################

. /netsim/netsim_cfg > /dev/null 2>&1

BIN_DIR=`dirname $0`
BIN_DIR=`cd ${BIN_DIR} ; pwd`
. ${BIN_DIR}/functions


REC_TEMPLATE_DIR=/netsim_users/pms/rec_templates
NETSIM_DBDIR=/netsim/netsim_dbdir/simdir/netsim/netsimdir
NETSIM_SHELL=/netsim/inst/netsim_shell

LOAD_VAL="DEFAULT"

# Default ROP value 15 MINS
ROP_PERIOD_MIN=15

while getopts  "l:r:" flag
do
    case "$flag" in

        l) LOAD_VAL="$OPTARG";;
        r) ROP_PERIOD_MIN="$OPTARG";;
        *) printf "Usage: %s [-r rop interval in mins] \n" $0
           exit 1;;
    esac
done

DATE=20`date -u '+%y%m%d'`

ROP_START_TIME=`date -u "+%H%M"`
ROP_END_TIME=`date -u --date "+${ROP_PERIOD_MIN}mins" "+%H%M"`

if [ "${LOAD_VAL}" = "PEAK" ] ; then
    CTR_SRC=${REC_TEMPLATE_DIR}/sam_ctr_walborg_1.bin.gz
    UETR_SRC=${REC_TEMPLATE_DIR}/sam_uetr_walborg_1.bin.gz
else
    CTR_SRC=${REC_TEMPLATE_DIR}/sam_ctr_walborg.bin.gz
    UETR_SRC=${REC_TEMPLATE_DIR}/sam_uetr_walborg.bin.gz
fi


CTR_ID_LIST="20000 20001"
UETR_ID_LIST="10000 10001 10002 10003 10004 10005 10006 10007 10008 10009 10010 10011 10012 10013 10014 10015"

OUT_ROOT=/netsim_users
if [ -d /pms_tmpfs ] ; then
    OUT_ROOT=/pms_tmpfs
fi

log "Start ${ROP_START_TIME}"

#This function is used to generate CELTRACE event file for mixed mode(Lrat + Grat OR NodeBFunction + ENodeBFunction) type nodes.
generate_CELLTRACE(){
    SIM_DIR=$1
    MIXED_MODE_RNC_LIST=$2
    NODE_TYPE=$3
    #For worst case scenario,using by default value for LTE_CELLTRACE_LIST.
    LTE_CELLTRACE_LIST="celltrace_256k.bin.gz:1:1 celltrace_4.7M.bin.gz:1:3"
    FILE_PATH="/c/pm_data/"

    if [[ -z ${MSRBS_V2_LTE_CELLTRACE_LIST} ]];then
        MSRBS_V2_LTE_CELLTRACE_LIST="celltrace_256k.bin.gz:1:1 celltrace_4.7M.bin.gz:1:3"
    fi

    if [[ -z ${MSRBS_V1_LTE_CELLTRACE_LIST} ]];then
        MSRBS_V1_LTE_CELLTRACE_LIST="celltrace_256k.bin.gz:JG1:1 celltrace_256k.bin.gz:JG2:1 celltrace_4.7M.bin.gz:JG3:1 celltrace_256k.bin.gz:JG1:2 celltrace_256k.bin.gz:JG2:2 celltrace_4.7M.bin.gz:JG3:2" 
    fi

    if [[ "${NODE_TYPE}" = "MSRBS-V2" ]]; then
        if [ ! -z "${MSRBS_V2_PMEvent_FileLocation}" ] ; then
            FILE_PATH=${MSRBS_V2_PMEvent_FileLocation}
        fi
        LTE_CELLTRACE_LIST="${MSRBS_V2_LTE_CELLTRACE_LIST}"
    fi

    if [[ "${NODE_TYPE}" = "PRBS" ]]; then
        LTE_CELLTRACE_LIST="${MSRBS_V1_LTE_CELLTRACE_LIST}"
    fi

    for LTE_CELLTRACE in ${LTE_CELLTRACE_LIST} ; do
        #<Type><Date>.<StartTime>-<EndTime>_CellTrace_DU<No>_<RC>.bin.gz
        IN_FILE_NAME=`echo ${LTE_CELLTRACE} | awk -F: '{print $1}'`
        DU_NUM=`echo ${LTE_CELLTRACE} | awk -F: '{print $2}'`
        REC_TYPE=`echo ${LTE_CELLTRACE} | awk -F: '{print $3}'`

        IN_FILE_PATH="${REC_TEMPLATE_DIR}/${IN_FILE_NAME}"
        OUT_FILE_NAME="A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_CellTrace_DUL${DU_NUM}_${REC_TYPE}.bin.gz"

        if [ ! -r ${IN_FILE_PATH} ] ; then
            log "ERROR: Cannot find ${IN_FILE_PATH}"
            exit 1
        fi

        for RNC_NODE in ${MIXED_MODE_RNC_LIST} ; do
            if [[ "${NODE_TYPE}" = "PRBS" ]]; then
                OUT_FILE_NAME="A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_${RNC_NODE}.Lrat_${DU_NUM}_${REC_TYPE}.bin.gz"
            fi
            NODE_PM_DATA=${SIM_DIR}/${RNC_NODE}/${FILE_PATH}
            ln -s ${IN_FILE_PATH} ${NODE_PM_DATA}/${OUT_FILE_NAME}
        done
    done

}

for RNC in $LIST ; do
    if grep -q $RNC "/tmp/showstartednodes.txt"; then
        SIM_TYPE=`getSimType ${RNC}`
        if [ "${SIM_TYPE}" = "WRAN" ] ; then
            MIXED_MODE_DUMPMOTREE_CMD='dumpmotree:moid=1,scope=1,includeattrs=\"Lrat,Wrat\",printattrs;'
            RNC_LIST=`ls ${OUT_ROOT}/${RNC} | grep RNC | grep -v RBS`
            MIXED_MODE_SIM=`ls ${NETSIM_DBDIR} | grep ${RNC}`
            MIXED_MODE_NODE=`ls ${OUT_ROOT}/${RNC} | grep MSRBS | grep V2 | head -1`
            MIXED_MODE_PRBS_NODE=`ls ${OUT_ROOT}/${RNC} | grep PRBS | head -1`

            if [[ ! -z ${MIXED_MODE_NODE} ]]; then
                MIXED_MODE_CMD_OUTPUT=`printf '.open '${MIXED_MODE_SIM}'\n.select '${MIXED_MODE_NODE}'\n'${MIXED_MODE_DUMPMOTREE_CMD} | ${NETSIM_SHELL}`
                echo ${MIXED_MODE_CMD_OUTPUT} | grep 'Lrat:' > /dev/null && echo ${MIXED_MODE_CMD_OUTPUT} | grep 'Wrat:' > /dev/null
                if [ $? -eq 0 ];then
                    MIXED_MODE_RNC_LIST=`ls ${OUT_ROOT}/${RNC} | grep -v -w ${RNC}`
                    generate_CELLTRACE "${OUT_ROOT}/${RNC}" "${MIXED_MODE_RNC_LIST}" "MSRBS-V2"
                fi
            fi

            if [[ ! -z ${MIXED_MODE_PRBS_NODE} ]]; then
                MIXED_MODE_CMD_OUTPUT=`printf '.open '${MIXED_MODE_SIM}'\n.select '${MIXED_MODE_PRBS_NODE}'\n'${MIXED_MODE_DUMPMOTREE_CMD} | ${NETSIM_SHELL}`
                echo ${MIXED_MODE_CMD_OUTPUT} | grep 'NodeBFunction' > /dev/null && echo ${MIXED_MODE_CMD_OUTPUT} | grep 'ENodeBFunction' > /dev/null
                if [ $? -eq 0 ];then
                    MIXED_MODE_RNC_LIST=`ls ${OUT_ROOT}/${RNC} | grep -v -w ${RNC}`
                    generate_CELLTRACE "${OUT_ROOT}/${RNC}" "${MIXED_MODE_RNC_LIST}" "PRBS"
                fi
            fi

            if [ ! -z "${RNC_LIST}" ] ; then
                for RNC_NODE in ${RNC_LIST} ; do
                    RNC_PM_DIR=${OUT_ROOT}/${RNC}/${RNC_NODE}/c/pm_data

                    # Don't know if/how sym links work with SL3/chroot

                    # Create the CTR links
                    for CTR_ID in ${CTR_ID_LIST} ; do
                        ln -s ${CTR_SRC} ${RNC_PM_DIR}/A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_CTR_${CTR_ID}.bin.gz
                    done

                    # Create the UETR links
                    for UETR_ID in ${UETR_ID_LIST} ; do
                        ln -s ${UETR_SRC} ${RNC_PM_DIR}/A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_UETR_${UETR_ID}.bin.gz
                    done
                done
            fi
        fi
    fi
done

log "End ${ROP_START_TIME}"
