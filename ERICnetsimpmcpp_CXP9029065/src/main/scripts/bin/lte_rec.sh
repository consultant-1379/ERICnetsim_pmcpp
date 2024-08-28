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
# Version no    :  NSS 18.03
# Purpose       :  Script is responsible for generating links for Events
# Jira No       :  NSS-16619
# Gerrit Link   :
# Description   :  Handling for SGSN mounting real node data path issue.
# Date          :  27/12/2017
# Last Modified :  tejas.lutade@tcs.com
####################################################

. /netsim/netsim_cfg > /dev/null 2>&1

BIN_DIR=`dirname $0`
BIN_DIR=`cd ${BIN_DIR} ; pwd`
. ${BIN_DIR}/functions

REC_TEMPLATE_DIR=/netsim_users/pms/rec_templates
MME_REF_CFG=/netsim_users/pms/etc/sgsn_mme_ebs_ref_fileset.cfg

OUT_ROOT=/netsim_users
if [ -d /pms_tmpfs ] ; then
    OUT_ROOT=/pms_tmpfs
fi

# Check if LTE UETRACE MCC MNC set in netsim_cfg
DEFAULT_MCC_MNC="3530570"
if [ -z "${MCC_MNC}" ] ; then
    MCC_MNC=$DEFAULT_MCC_MNC
fi

#Check if we have a node that needs a 19MB celltrace file;
if [ ! -z $LTE_CELLTRACE_19MB_NODE ] ; then

    #we have a node that needs 19MB file, so we check if the 19Mb filename is set in config file
    if [ -z $LTE_CELLTRACE_19MB_FILE ] ; then
        echo "The 19MB file variable is not set in netsim_cfg - LTE_CELLTRACE_19MB_FILE=\"your_celltrace_file_name.bin.gz\""
    else
        #filename is set, so check for the template file
        if [ ! -f $REC_TEMPLATE_DIR/$LTE_CELLTRACE_19MB_FILE ] ; then
            for req_node in ${LTE_CELLTRACE_19MB_NODE}
            do
                if grep -q "${req_node}" "/tmp/showstartednodes.txt"; then
                    echo "ERROR: 19Mb file - $LTE_CELLTRACE_19MB_FILE - not found for ${req_node}"
                fi
            done
        fi
    fi
fi

# This file is used to persist the EBS file index value for MME EBS files
if [ ! -f "${REC_TEMPLATE_DIR}/.ebs" ] ; then
    echo "1" > "${REC_TEMPLATE_DIR}/.ebs"
fi

# This file is used to persist the rop index value for MME UETRACE files
if [ ! -f "${REC_TEMPLATE_DIR}/.uetrace" ] ; then
    echo "0" > "${REC_TEMPLATE_DIR}/.uetrace"
fi


# This file is used to persist the rop index value for MME UETRACE files
if [ ! -f "${REC_TEMPLATE_DIR}/.ctum" ] ; then
    echo "0" > "${REC_TEMPLATE_DIR}/.ctum"
fi

FILE_TYPES="ALL"

while getopts  "r:f:" flag
do
    case "$flag" in
        r) ROP_PERIOD_MIN="$OPTARG";;
        f) FILE_TYPES="$OPTARG";;
        *) printf "Usage: %s [-r rop interval in mins] [-f file types EBS:EBM:CELLTRACE:UETRACE:CTUM] \n" $0
           exit 1;;
    esac
done

DATE=20`date -u '+%y%m%d'`

if [ -z ${ROP_PERIOD_MIN} ] ; then
    ROP_PERIOD_MIN=15
fi

ROP_START_TIME=`date -u "+%H%M"`
ROP_END_TIME=`date -u --date "+${ROP_PERIOD_MIN}mins" "+%H%M"`

MME_TZ=`date "+%Z"`
if [ ! -z "${SGSN_TZ}" ] ; then
    MME_TZ="${SGSN_TZ}"
fi


#FOR MME Nodes
ROP_START_DATE_LOCAL=$(TZ="${MME_TZ}" date "+%Y%m%d")
ROP_START_TIME_LOCAL=$(TZ="${MME_TZ}" date "+%H%M")

ROP_END_DATE_LOCAL=$(TZ="${MME_TZ}" date --date "+${ROP_PERIOD_MIN}mins" "+%Y%m%d")
ROP_END_TIME_LOCAL=$(TZ="${MME_TZ}" date --date "+${ROP_PERIOD_MIN}mins" "+%H%M")
ROP_LOCAL_OFFSET=$(TZ="${MME_TZ}" date "+%z")


EBS_FILENAME_PREFIX="A${ROP_START_DATE_LOCAL}.${ROP_START_TIME_LOCAL}${ROP_LOCAL_OFFSET}-${ROP_END_DATE_LOCAL}.${ROP_END_TIME_LOCAL}${ROP_LOCAL_OFFSET}_"

MME_CTUM_FILENAME_PREFIX="A${ROP_START_DATE_LOCAL}.${ROP_START_TIME_LOCAL}${ROP_LOCAL_OFFSET}-${ROP_END_DATE_LOCAL}.${ROP_END_TIME_LOCAL}${ROP_LOCAL_OFFSET}_"

MME_UETRACE_FILENAME_PREFIX="B${ROP_START_DATE_LOCAL}.${ROP_START_TIME_LOCAL}${ROP_LOCAL_OFFSET}-${ROP_END_DATE_LOCAL}.${ROP_END_TIME_LOCAL}${ROP_LOCAL_OFFSET}"

processSim() {
    MY_SIM=$1
    echo "${FILE_TYPES}" | egrep -w "ALL|CELLTRACE" > /dev/null
    if [ $? -eq 0 ] ; then
        #echo "Generating CELLTRACE files"
        generateCELLTRACE ${MY_SIM}
    fi

    echo "${FILE_TYPES}" | egrep -w "ALL|UETRACE" > /dev/null
    if [ $? -eq 0 ] ; then
        #echo "Generating ERBS UETRACE files"
        generateERBSUETRACE ${MY_SIM}
    fi
}


generateCELLTRACE() {

    MY_SIM=$1

    #Ignore MSRBS_V1(pERBS) and  MSRBS_V2(dg2ERBS)
    ERBS_NODE_LIST=`ls ${OUT_ROOT}/${SIM} | grep RBS | grep -v pERBS | grep -v dg2ERBS | grep -v MSRBS-V2`
    VTF_NODE_LIST=`ls ${OUT_ROOT}/${SIM} | grep -i VTFRADIONODE`

    MSRBS_V1_NODE_LIST=`ls ${OUT_ROOT}/${SIM} | grep pERBS`

    MSRBS_V2_NODE_LIST=`ls ${OUT_ROOT}/${SIM} | egrep 'dg2ERBS|MSRBS-V2'`

    # Make sure we have the CellTraceFilesLocation
    for NODE in ${ERBS_NODE_LIST} ; do
        NODE_PM_DATA=${OUT_ROOT}/${SIM}/${NODE}/c/pm_data
        FILE="CellTraceFilesLocation"
        if [ ! -r ${NODE_PM_DATA}/${FILE} ] ; then
            log "WARN: ${NODE_PM_DATA}/${FILE} is missing, creating"
            echo "/c/pm_data" > ${NODE_PM_DATA}/${FILE}
        fi
    done

    if [ ! -z "${ERBS_NODE_LIST}" ] ; then

        if [ -z "${LTE_CELLTRACE_LIST}" ] ; then
            log "ERROR: LTE_CELLTRACE_LIST not set"
            exit 1
        fi
        #
        # CellTrace for ERBS
        #
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

            for NODE in ${ERBS_NODE_LIST} ; do
                NODE_PM_DATA=${OUT_ROOT}/${SIM}/${NODE}/c/pm_data

                if [[ $NODE = $LTE_CELLTRACE_19MB_NODE && ${REC_TYPE} = 3 ]]; then
                    ln -s ${REC_TEMPLATE_DIR}\/${LTE_CELLTRACE_19MB_FILE} ${NODE_PM_DATA}/${OUT_FILE_NAME}
                else
                    ln -s ${IN_FILE_PATH} ${NODE_PM_DATA}/${OUT_FILE_NAME}
                fi
            done
        done
    fi



    #For MSRBS_V1 nodes
    if [ ! -z "${MSRBS_V1_NODE_LIST}" ] ; then

        if [ -z "${MSRBS_V1_LTE_CELLTRACE_LIST}" ] ; then
            log "ERROR: MSRBS_V1_LTE_CELLTRACE_LIST not set"
            exit 1
        fi

        FILE_PATH="/c/pm_data/"
        if [ ! -z "${MSRBS_V1_PMEvent_FileLocation}" ] ; then
            FILE_PATH=${MSRBS_V1_PMEvent_FileLocation}
        fi
        #
        # CellTrace for MSRBS_V1
        #
        for LTE_CELLTRACE in ${MSRBS_V1_LTE_CELLTRACE_LIST} ; do
            #<Type><Date>.<StartTime>-<EndTime>_CellTrace_DU<No>_<RC>.bin.gz
            IN_FILE_NAME=`echo ${LTE_CELLTRACE} | awk -F: '{print $1}'`
            JOB_NUM=`echo ${LTE_CELLTRACE} | awk -F: '{print $2}'`
            REC_TYPE=`echo ${LTE_CELLTRACE} | awk -F: '{print $3}'`

            IN_FILE_PATH="${REC_TEMPLATE_DIR}/${IN_FILE_NAME}"

            if [ ! -r ${IN_FILE_PATH} ] ; then
                log "ERROR: Cannot find ${IN_FILE_PATH}"
                exit 1
            fi

            for NODE in ${MSRBS_V1_NODE_LIST} ; do
                NODE_PM_DATA=${OUT_ROOT}/${SIM}/${NODE}/${FILE_PATH}
                OUT_FILE_NAME="A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_${NODE}.Lrat_${JOB_NUM}_${REC_TYPE}.bin.gz"
                ln -s ${IN_FILE_PATH} ${NODE_PM_DATA}/${OUT_FILE_NAME}
            done
        done
    fi

    #For MSRBS_V2 nodes
    if [ ! -z "${MSRBS_V2_NODE_LIST}" ] ; then

        if [ -z "${MSRBS_V2_LTE_CELLTRACE_LIST}" ] ; then
            log "ERROR: MSRBS_V2_LTE_CELLTRACE_LIST not set"
            exit 1
        fi

        FILE_PATH="/c/pm_data/"
        if [ ! -z "${MSRBS_V2_PMEvent_FileLocation}" ] ; then
            FILE_PATH=${MSRBS_V2_PMEvent_FileLocation}
        fi

        #
        # CellTrace for MSRBS_V2
        #
        for LTE_CELLTRACE in ${MSRBS_V2_LTE_CELLTRACE_LIST} ; do
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

            for NODE in ${MSRBS_V2_NODE_LIST} ; do
                NODE_PM_DATA=${OUT_ROOT}/${SIM}/${NODE}/${FILE_PATH}
                ln -s ${IN_FILE_PATH} ${NODE_PM_DATA}/${OUT_FILE_NAME}
            done
        done
    fi

    if [ ! -z "${VTF_NODE_LIST}" ] ; then

        if [ -z "${VTF_CELLTRACE_LIST}" ] ; then
            log "ERROR: VTF_CELLTRACE_LIST not set"
            exit 1
        fi
        #
        # CellTrace for VTF
        #

        VTF_FILE_PATH="/c/pm_data/"
        if [ ! -z "${VTFRADIONODE_PMEvent_FileLocation}" ] ; then
            VTF_FILE_PATH=${VTFRADIONODE_PMEvent_FileLocation}
        fi

        for VTF_CELLTRACE in ${VTF_CELLTRACE_LIST} ; do
            #<Type><Date>.<StartTime>-<EndTime>_CellTrace_DU<No>_<RC>.bin.gz
            IN_FILE_NAME=`echo ${VTF_CELLTRACE} | awk -F: '{print $1}'`
            DU_NUM=`echo ${VTF_CELLTRACE} | awk -F: '{print $2}'`
            REC_TYPE=`echo ${VTF_CELLTRACE} | awk -F: '{print $3}'`

            IN_FILE_PATH="${REC_TEMPLATE_DIR}/${IN_FILE_NAME}"
            OUT_FILE_NAME="A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_CellTrace_DUL${DU_NUM}_${REC_TYPE}.bin.gz"

            if [ ! -r ${IN_FILE_PATH} ] ; then
                log "ERROR: Cannot find ${IN_FILE_PATH}"
                exit 1
            fi

            for NODE in ${VTF_NODE_LIST} ; do
                NODE_PM_DATA=${OUT_ROOT}/${SIM}/${NODE}/${VTF_FILE_PATH}
                if [ ! -d "${NODE_PM_DATA}" ] ; then
                    mkdir -p ${NODE_PM_DATA}
                fi
                ln -s ${IN_FILE_PATH} ${NODE_PM_DATA}/${OUT_FILE_NAME}
            done
        done
    fi

}


generateERBSUETRACE() {
    MY_SIM=$1

    #Ignore MSRBS_V1(pERBS) and  MSRBS_V2(dg2ERBS)
    ERBS_NODE_LIST=($(ls ${OUT_ROOT}/${SIM}/ | grep RBS | grep -v pERBS | grep -v dg2ERBS))

    pERBS_NODE_LIST=($(ls ${OUT_ROOT}/${SIM}/ | grep pERBS))

    MSRBS_V2_NODE_LIST=($(ls ${OUT_ROOT}/${SIM}/ | egrep 'dg2ERBS|ERBS'))

    declare -a VTF_NODE_LIST
    if [[ "${ROP_PERIOD_MIN}" = "15" ]]; then
       VTF_NODE_LIST=($(ls ${OUT_ROOT}/${SIM} | grep -i VTFRADIONODE))
    fi 
  
    VTF_NODE_COUNT=0

    if [ ! -z ${VTF_NODE_LIST} ]; then
        VTF_NODE_COUNT=`ls ${OUT_ROOT}/${SIM} | grep -i VTFRADIONODE | wc -l`
    fi

    # Make sure we have the UeTraceFilesLocation
    for NODE in ${ERBS_NODE_LIST[@]} ; do
        NODE_PM_DATA=${OUT_ROOT}/${SIM}/${NODE}/c/pm_data
        FILE="UeTraceFilesLocation"
        if [ ! -r ${NODE_PM_DATA}/${FILE} ] ; then
            log "WARN: ${NODE_PM_DATA}/${FILE} is missing, creating"
            echo "/c/pm_data" > ${NODE_PM_DATA}/${FILE}
        fi

    done

    if [ ! -z "${ERBS_NODE_LIST}" ] ; then
        # removed as per https://jira-nam.lmera.ericsson.se/browse/NSS-6488
        #if [ -z "${LTE_UETRACE_LIST}" ] ; then
        #    log "ERROR: LTE_UETRACE_LIST not set"
        #    exit 1
        #fi
        #
        # UETrace
        #
        for LTE_UETRACE in ${LTE_UETRACE_LIST} ; do
            UETRACE_SIM=`echo ${LTE_UETRACE} | awk -F: '{print $2}'`
            if [ "${UETRACE_SIM}" = "${MY_SIM}" ] ; then
                UETRACE_FILE=`echo ${LTE_UETRACE} | awk -F: '{print $1}'`
                START_NE=`echo ${LTE_UETRACE} | awk -F: '{print $3}'`
                NUM_NE=`echo ${LTE_UETRACE} | awk -F: '{print $4}'`
                START_REF=`echo ${LTE_UETRACE} | awk -F: '{print $5}'`
                NUM_REF=`echo ${LTE_UETRACE} | awk -F: '{print $6}'`

                IN_FILE_PATH="${REC_TEMPLATE_DIR}/${UETRACE_FILE}"
                if [ ! -r ${IN_FILE_PATH} ] ; then
                    log "ERROR: Cannot find ${IN_FILE_PATH}"
                    exit 1
                fi

                if [ ${#ERBS_NODE_LIST[@]} -lt ${NUM_NE} ]; then
                    NUM_NE=${#ERBS_NODE_LIST[@]}
                fi

                CURR_REF=${START_REF}
                END_REF=`expr ${START_REF} + ${NUM_REF} - 1`

                CURR_NE=${START_NE}
                END_NE=`expr ${START_NE} + ${NUM_NE} - 1`

                while [ ${CURR_REF} -le ${END_REF} ] ; do

                    REF=`printf "%s1%04X" ${MCC_MNC} ${CURR_REF}`
                    NODE=`echo ${ERBS_NODE_LIST[${CURR_NE} - 1]}`

                    ln -s ${IN_FILE_PATH} ${OUT_ROOT}/${SIM}/${NODE}/c/pm_data/A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_uetrace_${REF}.bin.gz

                    CURR_REF=`expr ${CURR_REF} + 1`
                    CURR_NE=`expr ${CURR_NE} + 1`
                    if [ ${CURR_NE} -gt ${END_NE} ] ; then
                        CURR_NE=${START_NE}
                    fi
                done
            fi
        done
    fi

    if [ ! -z "${MSRBS_V2_NODE_LIST}" ] ; then
        # removed as per https://jira-nam.lmera.ericsson.se/browse/NSS-6488
        #if [ -z "${MSRBS_V2_LTE_UETRACE_LIST}" ] ; then
        #    log "ERROR: MSRBS_V2_LTE_UETRACE_LIST not set"
        #    exit 1
        #fi
        FILE_PATH="/c/pm_data/"
        if [ ! -z "${MSRBS_V2_PMEvent_FileLocation}" ] ; then
            FILE_PATH=${MSRBS_V2_PMEvent_FileLocation}
        fi

        #
        # UETrace
        #
        for LTE_UETRACE in ${MSRBS_V2_LTE_UETRACE_LIST} ; do
            UETRACE_SIM=`echo ${LTE_UETRACE} | awk -F: '{print $2}'`
            if [ "${UETRACE_SIM}" = "${MY_SIM}" ] ; then
                UETRACE_FILE=`echo ${LTE_UETRACE} | awk -F: '{print $1}'`
                START_NE=`echo ${LTE_UETRACE} | awk -F: '{print $3}'`
                NUM_NE=`echo ${LTE_UETRACE} | awk -F: '{print $4}'`
                START_REF=`echo ${LTE_UETRACE} | awk -F: '{print $5}'`
                NUM_REF=`echo ${LTE_UETRACE} | awk -F: '{print $6}'`

                IN_FILE_PATH="${REC_TEMPLATE_DIR}/${UETRACE_FILE}"
                if [ ! -r ${IN_FILE_PATH} ] ; then
                    log "ERROR: Cannot find ${IN_FILE_PATH}"
                    exit 1
                fi

                if [ ${#MSRBS_V2_NODE_LIST[@]} -lt ${NUM_NE} ]; then
                    NUM_NE=${#MSRBS_V2_NODE_LIST[@]}
                fi

                CURR_REF=${START_REF}
                END_REF=`expr ${START_REF} + ${NUM_REF} - 1`

                CURR_NE=${START_NE}
                END_NE=`expr ${START_NE} + ${NUM_NE} - 1`

                while [ ${CURR_REF} -le ${END_REF} ] ; do

                    REF=`printf "%s1%04X" ${MCC_MNC} ${CURR_REF}`
                    NODE=`echo ${MSRBS_V2_NODE_LIST[${CURR_NE} - 1]}`

                    ln -s ${IN_FILE_PATH} ${OUT_ROOT}/${SIM}/${NODE}/${FILE_PATH}/A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_uetrace_${REF}.bin.gz

                    CURR_REF=`expr ${CURR_REF} + 1`
                    CURR_NE=`expr ${CURR_NE} + 1`
                    if [ ${CURR_NE} -gt ${END_NE} ] ; then
                        CURR_NE=${START_NE}
                    fi
                done
            fi
        done
    fi


    if [ ! -z "${MSRBS_V1_NODE_LIST}" ] ; then
        # removed as per https://jira-nam.lmera.ericsson.se/browse/NSS-6488
        #if [ -z "${MSRBS_V1_LTE_UETRACE_LIST}" ] ; then
        #    log "ERROR: MSRBS_V1_LTE_UETRACE_LIST not set"
        #    exit 1
        #fi

        FILE_PATH="/c/pm_data/"
        if [ ! -z "${MSRBS_V1_PMEvent_FileLocation}" ] ; then
            FILE_PATH=${MSRBS_V1_PMEvent_FileLocation}
        fi

        if [ ${#pERBS_NODE_LIST[@]} -eq 0 ] ; then
            log "WARN: pERBS nodes are not available in ${SIM} simulation."
            return
        fi

        #
        # UETrace
        #
        for LTE_UETRACE in ${MSRBS_V1_LTE_UETRACE_LIST} ; do
            UETRACE_SIM=`echo ${LTE_UETRACE} | awk -F: '{print $2}'`
            if [ "${UETRACE_SIM}" = "${MY_SIM}" ] ; then
                UETRACE_FILE=`echo ${LTE_UETRACE} | awk -F: '{print $1}'`
                START_NE=`echo ${LTE_UETRACE} | awk -F: '{print $3}'`
                NUM_NE=`echo ${LTE_UETRACE} | awk -F: '{print $4}'`
                START_REF=`echo ${LTE_UETRACE} | awk -F: '{print $5}'`
                NUM_REF=`echo ${LTE_UETRACE} | awk -F: '{print $6}'`

                IN_FILE_PATH="${REC_TEMPLATE_DIR}/${UETRACE_FILE}"
                if [ ! -r ${IN_FILE_PATH} ] ; then
                    log "ERROR: Cannot find ${IN_FILE_PATH}"
                    exit 1
                fi

                if [ ${#pERBS_NODE_LIST[@]} -lt ${NUM_NE} ]; then
                    NUM_NE=${#pERBS_NODE_LIST[@]}
                fi

                CURR_REF=${START_REF}
                END_REF=`expr ${START_REF} + ${NUM_REF} - 1`

                CURR_NE=${START_NE}
                END_NE=`expr ${START_NE} + ${NUM_NE} - 1`

                while [ ${CURR_REF} -le ${END_REF} ] ; do

                    REF=`printf "%s1%04X" ${MCC_MNC} ${CURR_REF}`
                    NODE=`echo ${pERBS_NODE_LIST[${CURR_NE} - 1]}`

                    ln -s ${IN_FILE_PATH} ${OUT_ROOT}/${SIM}/${NODE}/${FILE_PATH}/A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_uetrace_${REF}.bin.gz

                    CURR_REF=`expr ${CURR_REF} + 1`
                    CURR_NE=`expr ${CURR_NE} + 1`
                    if [ ${CURR_NE} -gt ${END_NE} ] ; then
                        CURR_NE=${START_NE}
                    fi
                done
            fi
        done
    fi

if [ ! -z "${VTF_NODE_LIST}" ] ; then

        VTF_FILE_PATH="/c/pm_data/"
        if [ ! -z "${VTFRADIONODE_PMEvent_FileLocation}" ] ; then
            VTF_FILE_PATH=${VTFRADIONODE_PMEvent_FileLocation}
        fi

        for VTF_UETRACE in ${VTF_UETRACE_LIST} ; do
            UETRACE_SIM=`echo ${VTF_UETRACE} | awk -F: '{print $2}'`
            if [[ $MY_SIM == *"-VTFR"* ]]; then
                UETRACE_FILE=`echo ${VTF_UETRACE} | awk -F: '{print $1}'`
                START_NE=`echo ${VTF_UETRACE} | awk -F: '{print $3}'`
                NUM_NE=`echo ${VTF_UETRACE} | awk -F: '{print $4}'`
                START_REF=`echo ${VTF_UETRACE} | awk -F: '{print $5}'`
                NUM_REF=`echo ${VTF_UETRACE} | awk -F: '{print $6}'`

                if [[ ${VTF_NODE_COUNT} -gt 0 ]]; then
                    NUM_NE=${VTF_NODE_COUNT}
                    NUM_REF=$((${NUM_NE} * 16))
                fi

                IN_FILE_PATH="${REC_TEMPLATE_DIR}/${UETRACE_FILE}"
                if [ ! -r ${IN_FILE_PATH} ] ; then
                    log "ERROR: Cannot find ${IN_FILE_PATH}"
                    exit 1
                fi

                if [ ${#VTF_NODE_LIST[@]} -lt ${NUM_NE} ]; then
                    NUM_NE=${#VTF_NODE_LIST[@]}
                fi

                CURR_REF=${START_REF}
                END_REF=`expr ${START_REF} + ${NUM_REF} - 1`

                CURR_NE=${START_NE}
                END_NE=`expr ${START_NE} + ${NUM_NE} - 1`

                while [ ${CURR_REF} -le ${END_REF} ] ; do

                    REF=`printf "%s1%04X" ${MCC_MNC} ${CURR_REF}`
                    NODE=`echo ${VTF_NODE_LIST[${CURR_NE} - 1]}`

                    ln -s ${IN_FILE_PATH} ${OUT_ROOT}/${SIM}/${NODE}/${VTF_FILE_PATH}/A${DATE}.${ROP_START_TIME}-${ROP_END_TIME}_uetrace_${REF}.bin.gz

                    CURR_REF=`expr ${CURR_REF} + 1`
                    CURR_NE=`expr ${CURR_NE} + 1`
                    if [ ${CURR_NE} -gt ${END_NE} ] ; then
                        CURR_NE=${START_NE}
                    fi
                done
            fi
        done
    fi
}

# ebs file generation

updateEBSTemplates() {

    CURR_ROP=${ROP_START_TIME_LOCAL}
    STARTTIME="${ROP_START_DATE_LOCAL}.${ROP_START_TIME_LOCAL}"
    ENDTIME="${ROP_END_DATE_LOCAL}.${ROP_END_TIME_LOCAL}"

    STARTTIME_STR=`echo "$STARTTIME" | sed 's/\(....\)\(..\)\(..\)\.\(..\)\(..\)/\1 \2 \3 \4 \5/'`
    YEAR=`echo ${STARTTIME_STR} | awk '{print $1}'`
    MON=`echo ${STARTTIME_STR} | awk '{print $2}'`
    MON=${MON#0}
    DAY=`echo ${STARTTIME_STR} | awk '{print $3}'`
    DAY=${DAY#0}
    HOUR=`echo ${STARTTIME_STR} | awk '{print $4}'`
    HOUR=${HOUR#0}
    MIN=`echo ${STARTTIME_STR} | awk '{print $5}'`
    MIN=${MIN#0}
    SEC="00"

    EBS_TEMPLATE_DIRS=`cat ${MME_REF_CFG} | awk -F':' '{print $3}' | sort | uniq`

    for DIR in ${EBS_TEMPLATE_DIRS} ; do

        if [ -d "$DIR" ] ; then

            FILES=`ls $DIR | grep "A.\{8\}\.${CURR_ROP}"`

            if [ -z "$FILES" ] ; then

                echo "ERROR : No reference files found under $DIR for ROP ${STARTTIME}"

            else

                for FILE in $FILES  ; do

                    NEWFILE=`echo $FILE | sed "s/A.............\(.....\)-..................\(.*$\)/A${STARTTIME}\1-${ENDTIME}\1\2/"`
                    #Move old file to new file with current timestamp in filename only
                    mv $DIR/$FILE $DIR/$NEWFILE
                    #Update current timestamp in new file
                    printf "%.4x%.2x%.2x%.2x%.2x%.2x" $YEAR $MON $DAY $HOUR $MIN $SEC | xxd -r -p | dd of=$DIR/$NEWFILE bs=1 count=7 seek=5 conv=notrunc
                done
            fi
        else
            echo "ERROR : Reference EBS file directory not present $DIR"
        fi

    done

}

#Generated the EBS files as per the configuration
#Defined in ME_REF_CFG
makeEBS() {

    SIM_DIR="/netsim/netsim_dbdir/simdir/netsim/netsimdir"

    while read LINE ; do

        if [ ! -z "$LINE" ] ; then

            SIM=`echo ${LINE} | awk -F: '{print $1}'`
            NODE=`echo ${LINE} | awk -F: '{print $2}'`
            FILE_SET=`echo ${LINE} | awk -F: '{print $3}'`

            if [ -d "${FILE_SET}" ] ; then

                NODE_DIR="${SIM_DIR}/${SIM}/${NODE}"

                if [ -d "${NODE_DIR}" ] ; then

                    EBS_OUTPUT_DIR="${NODE_DIR}/fs/tmp/OMS_LOGS/ebs/ready"
                    # Create ebs dir structure if not present
                    if [ ! -d "${EBS_OUTPUT_DIR}" ] ; then
                        mkdir -p ${EBS_OUTPUT_DIR}
                    fi

                    EBS_FILES=`ls ${FILE_SET} | grep "A${ROP_START_DATE_LOCAL}.${ROP_START_TIME_LOCAL}"`

                    if [ ! -z "${EBS_FILES}" ] ; then

                        for FILE in ${EBS_FILES}  ; do
                            EVENT_FILENAME=`echo $FILE | sed "s/A......................................\(.*$\)/${EBS_FILENAME_PREFIX}\1/"`

                            ln -s  "${FILE_SET}/${FILE}" "${EBS_OUTPUT_DIR}/${EVENT_FILENAME}"
                        done

                    else
                        echo "ERROR : No reference files found under ${FILE_SET} for ROP ${STARTTIME} for the Node : $NODE "
                    fi

                else
                    echo "ERROR : Invalid NODE/SIM, ${NODE_DIR} not present for Node : $NODE"
                fi

            else
                echo "ERROR : Reference EBS file directory ${FILE_SET}  not present for Node : $NODE"
            fi
        fi

    done < "${MME_REF_CFG}"

}


generateCTUM() {

    # Get last ROP UETRACE file index
    CTUM_INDEX=`cat "${REC_TEMPLATE_DIR}/.ctum"`


    if [ -z "${MME_CTUM_LIST}" ] ; then
        log "WRAN: MME_CTUM_LIST not found or empty. MME CTUM files will be not be generated"
    else
        CTUM_INDEX=`expr ${CTUM_INDEX} + 1`
    fi

    SIM_DIR="/netsim/netsim_dbdir/simdir/netsim/netsimdir"


    for SIM in ${MME_SIM_LIST}  ; do

        echo `ls ${SIM_DIR}` | grep ${SIM} > /dev/null

        if [ $? -eq 0 ] ; then

            # Get the NE List
            NE_LIST=`ls ${SIM_DIR}/${SIM}`

            for NE in $NE_LIST; do

                if [ ! -z "${MME_CTUM_LIST}" ] ; then
                    CTUM_OUTPUTDIR="${SIM_DIR}/${SIM}/${NE}/fs/tmp/OMS_LOGS/ctum/ready/"
                    # Create uetrace dir structure if not present
                    if [ ! -d "${CTUM_OUTPUTDIR}" ] ; then
                        mkdir -p ${CTUM_OUTPUTDIR}
                    fi
                    for MME_CTUM in ${MME_CTUM_LIST} ; do

                        IN_FILE_NAME=`echo ${MME_CTUM} | awk -F: '{print $1}'`
                        ROP_INDEX=`echo ${MME_CTUM} | awk -F: '{print $2}'`

                        IN_FILE="${REC_TEMPLATE_DIR}/${IN_FILE_NAME}"
                        OUT_FILE_NAME="${MME_CTUM_FILENAME_PREFIX}${ROP_INDEX}_ctum.${CTUM_INDEX}"

                        if [ ! -r ${IN_FILE} ] ; then
                            log "ERROR: Cannot find ${IN_FILE}"
                            exit 1
                        fi
                        ln "${IN_FILE}" "${CTUM_OUTPUTDIR}/${OUT_FILE_NAME}"
                    done
                fi
            done
        fi
    done

    # Persist rop index value for ctum fiels
    echo ${CTUM_INDEX} > "${REC_TEMPLATE_DIR}/.ctum"

}


generateMMEUETRACE() {

    # Get last ROP UETRACE  file index
    UETRACE_INDEX=`cat "${REC_TEMPLATE_DIR}/.uetrace"`

    if [ -z "${MME_UETRACE_LIST}" ] ; then
        log "WRAN: MME_UETRACE_LIST not found or empty. MME UETRACE files will be not be generated"
    else
        UETRACE_INDEX=`expr ${UETRACE_INDEX} + 1`
    fi


    SIM_DIR="/netsim/netsim_dbdir/simdir/netsim/netsimdir"

    for SIM in ${MME_SIM_LIST}  ; do

        echo `ls ${SIM_DIR}` | grep ${SIM} > /dev/null

        if [ $? -eq 0 ] ; then

            # Get the NE List
            NE_LIST=`ls ${SIM_DIR}/${SIM}`

            for NE in $NE_LIST; do

                if [ ! -z "${MME_UETRACE_LIST}" ] ; then
                    UETRACE_OUTPUTDIR="${SIM_DIR}/${SIM}/${NE}/fs/tmp/OMS_LOGS/ue_trace/ready"
                    # Create uetrace dir structure if not present
                    if [ ! -d "${UETRACE_OUTPUTDIR}" ] ; then
                        mkdir -p ${UETRACE_OUTPUTDIR}
                    fi
                    for MME_UETRACE in ${MME_UETRACE_LIST} ; do

                        IN_FILE_NAME=`echo ${MME_UETRACE} | awk -F: '{print $1}'`
                        FILE_VER=`echo ${MME_UETRACE} | awk -F: '{print $2}'`
                        ROP_INDEX=`echo ${MME_UETRACE} | awk -F: '{print $3}'`

                        IN_FILE="${REC_TEMPLATE_DIR}/${IN_FILE_NAME}"
                        OUT_FILE_NAME="${MME_UETRACE_FILENAME_PREFIX}-MME.${NE}.${FILE_VER}_${ROP_INDEX}_ue_trace.${UETRACE_INDEX}"

                        if [ ! -r ${IN_FILE} ] ; then
                            log "ERROR: Cannot find ${IN_FILE}"
                            exit 1
                        fi
                        ln "${IN_FILE}" "${UETRACE_OUTPUTDIR}/${OUT_FILE_NAME}"
                    done
                fi

            done
        fi
    done
    # Persist rop index value for uetrace fiels
    echo ${UETRACE_INDEX} > "${REC_TEMPLATE_DIR}/.uetrace"

}


generateEBS() {

    EBS_GEN_DONE="NO"

    # If this file present the update the EBS templates
    if [ -f "${MME_REF_CFG}" ] ; then
        cfg_line_data=$(cat ${MME_REF_CFG} | head -1 | awk -F: '{print $3}')
        if [[ -d ${cfg_line_data} ]]; then
            makeEBS
            # Make EBS_GEN_DONE="YES" so that again EBS files will not  be generated
            EBS_GEN_DONE="YES"
        else
            log "WARN: Real Node data path ${cfg_line_data} not present. Replaying ebs design templates."
        fi
    else
        if [ -z "${MME_EBS_FILE_LIST}" ] ; then
            log "WRAN: MME_EBS_FILE_LIST variable is empty or not present in /netsim/netsim_cfg"
        fi
    fi

    # Get last ROP EBS file index
    EBS_FILE_INDEX=`cat "${REC_TEMPLATE_DIR}/.ebs"`

    SIM_DIR="/netsim/netsim_dbdir/simdir/netsim/netsimdir"

    FILE_INDEX=1;

    for SIM in ${MME_SIM_LIST}  ; do

        echo `ls ${SIM_DIR}` | grep ${SIM} > /dev/null

        if [ $? -eq 0 ] ; then

            # Get the NE List
            NE_LIST=`ls ${SIM_DIR}/${SIM}`

            for NE in $NE_LIST; do

                if [ "${EBS_GEN_DONE}" = "NO" ] ; then
                    EBS_OUTPUTFILE="${SIM_DIR}/${SIM}/${NE}/fs/tmp/OMS_LOGS/ebs/ready"
                    # Create ebs dir structure if not present
                    if [ ! -d "${EBS_OUTPUTFILE}" ] ; then
                        mkdir -p ${EBS_OUTPUTFILE}
                    fi

                    EBS_FILE_INDEX=`cat "${REC_TEMPLATE_DIR}/.ebs"`

                    for FILE in ${MME_EBS_FILE_LIST} ; do
                        EVENT_FILENAME="${EBS_FILENAME_PREFIX}${FILE_INDEX}_ebs"
                        IN_FILE="${REC_TEMPLATE_DIR}/${FILE}"
                        if [ ! -r ${IN_FILE} ] ; then
                            log "ERROR: Cannot find ${IN_FILE}"
                            exit 1
                        fi

                        ln "${IN_FILE}" "${EBS_OUTPUTFILE}/${EVENT_FILENAME}.${EBS_FILE_INDEX}"
                        EBS_FILE_INDEX=`expr ${EBS_FILE_INDEX} + 1`
                        FILE_INDEX=`expr ${FILE_INDEX} + 1`
                    done
                    # Reset EBS file index
                    FILE_INDEX=1;
                fi

            done
        fi
    done

    #Total file per day = 8 * 4 * 24 = 768 after that reset the value

    TOTAL_FILES_PER_DAY=`expr ${FILE_INDEX} \* 60 \/ ${ROP_PERIOD_MIN}  \* 24`
    if [[ ${EBS_FILE_INDEX} -ge ${TOTAL_FILES_PER_DAY} ]] ; then
        EBS_FILE_INDEX=1
    fi
    # Persist EBS file index value
    echo ${EBS_FILE_INDEX} > "${REC_TEMPLATE_DIR}/.ebs"

}


# For MME sims /pms_tmpfs path will not be used
processMMESim() {

    echo "${FILE_TYPES}" | egrep -w "ALL|EBM|EBS" > /dev/null
    if [ $? -eq 0 ] ; then
        #echo "Generating EBS files"
        generateEBS
    fi


    echo "${FILE_TYPES}" | egrep -w "ALL|UETRACE" > /dev/null
    if [ $? -eq 0 ] ; then
        #echo "Generating MME UETRACE files"
        generateMMEUETRACE
    fi

    echo "${FILE_TYPES}" | egrep -w "ALL|CTUM" > /dev/null
    if [ $? -eq 0 ] ; then
        #echo "Generating CTUM files"
        generateCTUM
    fi

}

log "Start ${ROP_START_TIME}"


# If this file present the update the EBS templates
if [ -f "${MME_REF_CFG}" ] ; then

    echo "${FILE_TYPES}" | egrep -w "ALL|EBM|EBS" > /dev/null
    if [ $? -eq 0 ] ; then
        cfg_line=$(cat ${MME_REF_CFG} | head -1 | awk -F: '{print $3}')
        if [[ -d ${cfg_line} ]]; then
            updateEBSTemplates
        fi
    fi
fi


for SIM in $LIST ; do
    if grep -q $SIM "/tmp/showstartednodes.txt"; then
        SIM_TYPE=`getSimType ${SIM}`
        if [ "${SIM_TYPE}" = "LTE" ] || [ "${SIM_TYPE}" = "VTFRADIONODE" ] ; then
            processSim ${SIM}
        elif [ "${SIM_TYPE}" = "WRAN" ] ; then
            MY_HAS_LTE=$(eval "echo \$$(echo ${SIM}_HAS_LTE)")
            if [ ! -z "${MY_HAS_LTE}" ] && [ ${MY_HAS_LTE} -eq 1 ] ; then
                processSim $SIM
            fi
        fi
    fi
done

# Process SGSN simulation if any
if [ ! -z "${MME_SIM_LIST}" ] ; then
    processMMESim
fi

log "End ${ROP_START_TIME}"

