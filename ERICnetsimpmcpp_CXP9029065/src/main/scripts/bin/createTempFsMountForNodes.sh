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
# Version no    :  NSS 17.15
# Purpose       :  Script creates and mounts real node file path if configured for any node type.
# Jira No       :  NSS-14680
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2669301/
# Description   :  Handling to not create directory of nodes which have real node file path and which are in stop state.
# Date          :  5/09/2017
# Last Modified :  abhishek.mandlewala@tcs.com
####################################################

# XSURJAJ
#
# This script is responsible to create PM and PMEVENT file location directories
# under Node file system and temp file system including mount binding between them
#
#

. /netsim/netsim_cfg > /dev/null 2>&1

BIN_DIR=`dirname $0`
BIN_DIR=`cd ${BIN_DIR} ; pwd`

. ${BIN_DIR}/functions

SIM_DIR="/netsim/netsim_dbdir/simdir/netsim/netsimdir"
OUT_ROOT="/pms_tmpfs"

if [ -z "${EPG_PM_FileLocation}" ] ; then
     EPG_PM_FileLocation="/var/log/services/epg/pm/"
fi

# Create mount binding between node file system
# temp file system
createMount() {

    SIM=$1
    FILE_PATH=$2
    SIM_NAME=`ls ${SIM_DIR} | grep -w ${SIM} `

    if [ $? -eq 0 ] ; then

        NODE_LIST=`ls ${SIM_DIR}/${SIM_NAME}`

        for NODE in ${NODE_LIST} ; do
             if ! grep -q ${NODE} "/tmp/showstartednodes.txt"; then
                 continue
             fi

             NODE_PATH="${SIM_DIR}/${SIM_NAME}/${NODE}/fs/${FILE_PATH}"
             NODE_TEMP_PATH="${OUT_ROOT}/${SIM}/${NODE}/${FILE_PATH}"

             umount "${NODE_PATH}"

             rm -rf "${NODE_PATH}"

             mkdir -p "${NODE_PATH}"

             chown -R netsim:netsim "${SIM_DIR}/${SIM_NAME}/${NODE}/fs"

             mkdir -p "${NODE_TEMP_PATH}"

             chown -R netsim:netsim "${OUT_ROOT}/${SIM}/${NODE}"

             mount -B ${NODE_TEMP_PATH} ${NODE_PATH}

             mount -a
        done
    else
        log " $SIM not found"
    fi
}


createTempFsMounting() {

   log "createTempFsMountForNodes start"

   for SIM in $LIST ; do
        if grep -q $SIM "/tmp/showstartednodes.txt"; then

        NODE_TYPE=""

        SIM_TYPE=`getSimType ${SIM}`

        if [ "${SIM_TYPE}" = "WRAN" ] || [ "${SIM_TYPE}" = "RBS" ] ; then

            #Check for DG2 nodes
            MSRBS_V2_LIST=`ls ${OUT_ROOT}/${SIM} | grep MSRBS-V2`
            #Check for PRBS nodes
            PRBS_LIST=`ls ${OUT_ROOT}/${SIM} | grep PRBS`
            #Check for RBS nodes
            RBS_LIST=`ls ${OUT_ROOT}/${SIM} | grep RBS`
            if [ ! -z "${MSRBS_V2_LIST}" ] ; then
                NODE_TYPE="MSRBS_V2"
            elif [ ! -z "${PRBS_LIST}" ] ; then
                NODE_TYPE="PRBS"
            elif [ ! -z "${RBS_LIST}" ] ; then
                NODE_TYPE="RBS"
            else
                NODE_TYPE="RNC"
            fi

        elif [ "${SIM_TYPE}" = "LTE" ] ; then
            MSRBS_V1_LIST=`ls ${OUT_ROOT}/${SIM} | grep pERBS`
            MSRBS_V2_LIST=`ls ${OUT_ROOT}/${SIM} | grep dg2ERBS`
            if [ ! -z "${MSRBS_V1_LIST}" ] ; then
                NODE_TYPE="MSRBS_V1"
            elif [ ! -z "${MSRBS_V2_LIST}" ] ; then
                NODE_TYPE="MSRBS_V2"
            fi

        elif [ "${SIM_TYPE}" = "SPITFIRE" ] ; then
            NODE_TYPE="SPITFIRE"
        elif [ "${SIM_TYPE}" = "R6274" ] ; then
            NODE_TYPE="R6274"
        elif [ "${SIM_TYPE}" = "R6672" ] ; then
            NODE_TYPE="R6672"
        elif [ "${SIM_TYPE}" = "R6675" ] ; then
            NODE_TYPE="R6675"
        elif [ "${SIM_TYPE}" = "R6371" ] ; then
            NODE_TYPE="R6371"
        elif [ "${SIM_TYPE}" = "R6471-1" ] ; then
            NODE_TYPE="R6471-1"
        elif [ "${SIM_TYPE}" = "R6471-2" ] ; then
            NODE_TYPE="R6471-2"
        elif [ "${SIM_TYPE}" = "TCU04" ] || [ "${SIM_TYPE}" = "C608" ] ; then
            NODE_TYPE="TCU04"
        elif [ "${SIM_TYPE}" = "TCU03" ] ; then
            NODE_TYPE="TCU"
        elif [ "${SIM_TYPE}" = "DSC" ] ; then
            NODE_TYPE="DSC"
        elif [ "${SIM_TYPE}" = "ESAPC" ] ; then
            NODE_TYPE="ESAPC"
        elif [ "${SIM_TYPE}" = "GSM_DG2" ] ; then
            NODE_TYPE="MSRBS_V2"
        elif [ "${SIM_TYPE}" = "MTAS" ] ; then
            NODE_TYPE="MTAS"
        elif [ "${SIM_TYPE}" = "SBG" ] ; then
            NODE_TYPE="SBG"
        elif [ "${SIM_TYPE}" = "CSCF" ] ; then
            NODE_TYPE="CSCF"
        elif [ "${SIM_TYPE}" = "HSS" ] ; then
            NODE_TYPE="HSS_FE"
        elif [ "${SIM_TYPE}" = "EPG-SSR" ] || [ "${SIM_TYPE}" = "EPG-EVR" ]; then
            NODE_TYPE="EPG"
        elif [ "${SIM_TYPE}" = "RNNODE" ] ; then
            NODE_TYPE="RNNODE"
        elif [ "${SIM_TYPE}" = "VPP" ] ; then
            NODE_TYPE="VPP"
        elif [ "${SIM_TYPE}" = "VRM" ] ; then
            NODE_TYPE="VRM"
        elif [ "${SIM_TYPE}" = "VRC" ] ; then
            NODE_TYPE="VRC"
        elif [ "${SIM_TYPE}" = "VBGF" ] ; then
            NODE_TYPE="MRSV"
        elif [ "${SIM_TYPE}" = "IPWORKS" ] ; then
            NODE_TYPE="IPWORKS"
        elif [ "${SIM_TYPE}" = "MRF" ] ; then
            NODE_TYPE="MRFV"
        elif [ "${SIM_TYPE}" = "WCG" ] ; then
            NODE_TYPE="WCG"
        elif [ "${SIM_TYPE}" = "UPG" ] ; then
            NODE_TYPE="UPG"
        elif [ "${SIM_TYPE}" = "WMG" ] ; then
            NODE_TYPE="WMG"
        elif [ "${SIM_TYPE}" = "EME" ] ; then
            NODE_TYPE="EME"
        elif [ "${SIM_TYPE}" = "VTFRADIONODE" ] ; then
            NODE_TYPE="VTFRADIONODE"
        elif [ "${SIM_TYPE}" = "5GRADIONODE" ] ; then
            NODE_TYPE="FIVEGRADIONODE"
        fi

        # For STATS
        ne_file_location="${NODE_TYPE}"_PM_FileLocation
        PMDIR=${!ne_file_location}

        if [ ! -z "${PMDIR}" ] ; then
            createMount "${SIM}" "${PMDIR}"
        fi

        # For EVENTS
        ne_file_location="${NODE_TYPE}"_PMEvent_FileLocation
        PMDIR=${!ne_file_location}

        if [ ! -z "${PMDIR}" ] ; then
            createMount "${SIM}" "${PMDIR}"
        fi
        fi
    done

    log "createTempFsMountForNodes end"
}


createTempFsMounting

