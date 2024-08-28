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
# Purpose       :  The purpose of this script to call STATS and EVENTS playbacker framework as per configuration mentioned in /netsim_users/pms/bin/playback_cfg file and generate PM files for STATS and EVENTS respectively.    
# Jira No       :  NSS-14774,NSS-14665
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2688326/
# Description   :  Added support for TSP based nodes(HSS-FE,MTAS,CSCF and SAPC).
# Date          :  09/11/2017
# Last Modified :  tejas.lutade@tcs.com
####################################################

#@script: startPlaybacker.sh
#@description:This script is responsible for initialisation of all one time constant variables,getting started nodes from netsim box,dividing input files like events and stats respectively into batches and calling respective stats and events sandbox script for dumping respective stats and events file into each started node as per netsim directory structure.

######### Main Function ############

INSTALL_DIR_NAME=`dirname $0`
INSTALL_DIR=`cd ${INSTALL_DIR_NAME} ; pwd`
LOG_PATH="/netsim_users/pms/logs"
LOG_DATE=`date "+%Y_%m_%d_%H:%M:%S"`

if [ ! -d ${LOG_PATH}/.logs ] ; then
        mkdir -p ${LOG_PATH}/.logs
fi

LOG=${LOG_PATH}/.logs/log_backup_${LOG_DATE}

# Need to source this first to override some vars (e.g. PMDIR)
if [ -r /netsim/netsim_cfg ] ; then
    . /netsim/netsim_cfg > /dev/null 2>&1
fi

#Importing Sandbox_cfg file
if [ -r /${INSTALL_DIR}/playback_cfg ] ; then
. /${INSTALL_DIR}/playback_cfg
fi

#Importing common functions
if [ -r /${INSTALL_DIR}/functions ] ; then
. /${INSTALL_DIR}/functions
fi

#Check whether playback list is empty
if [[ -z ${PLAYBACK_SIM_LIST} ]];then
   log "INFO: Playback List is empty.Exiting Process."
   exit 1
fi

ROP_PERIOD_MIN=15

while getopts  "r:l:" flag
do
    case "$flag" in
        r) ROP_PERIOD_MIN="$OPTARG";;
        l) NE_TYPE_LIST="$OPTARG";;
        *) printf "Usage: %s [ -r rop interval in mins ] [ -l ne types <NE1:NE2> ] \n" $0
           exit 1;;
    esac
done

#DateTime Calculation

ZERO=00
ROP_START_DATE_UTC=`date -u "+%Y%m%d"`
ROP_START_TIME_UTC=`date -u "+%H%M"`
STARTDATE_UTC="${ROP_START_DATE_UTC}${ROP_START_TIME_UTC}"
ROP_END_DATE_UTC=`date -u --date "+${ROP_PERIOD_MIN}mins" "+%Y%m%d"`
UNIQUE_ID=`awk -v min=10000 -v max=99999 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`   
DATE=20`date -u '+%y%m%d'`
ROP_START_TIME=`date -u "+%H%M"`
ROP_END_TIME=`date -u --date "+${ROP_PERIOD_MIN}mins" "+%H%M"`
ROP_START_DATE_LOCAL=`date "+%Y%m%d"`
ROP_START_TIME_LOCAL=`date "+%H%M"`
ROP_END_DATE_LOCAL=`date --date "+${ROP_PERIOD_MIN}mins" "+%Y%m%d"`
ROP_END_TIME_LOCAL=`date --date "+${ROP_PERIOD_MIN}mins" "+%H%M"`
ROP_LOCAL_OFFSET=`date "+%z"`
FILE_beginTime=`date -u "+%Y-%m-%dT%H:%M:00%:z"`
FILE_endTime=`date -u --date "+${ROP_PERIOD_MIN}mins" "+%Y-%m-%dT%H:%M:00%:z"`
if [[ $ROP_PERIOD_MIN == 15 ]]; then
    dur="900"
elif [[ $ROP_PERIOD_MIN == 1 ]]; then
    dur="60"
else
    dur="86400"
fi

log "Start ${STARTDATE_UTC}"

for NE in ${NE_TYPE_LIST}; do
    for SIM_NAME in ${PLAYBACK_SIM_LIST}; do
      if [[ "${SIM_NAME}" == *${NE}* ]]; then
        if grep -q ${SIM_NAME} "/tmp/showstartednodes.txt"; then
            log "Processing SIM : ${SIM_NAME}"
            #Filtering SIM NAME (replacing - to _ in SIM NAME)
            NE=`echo ${NE} | sed s/-/_/g`
            #For STATS file generation
            stats="$NE"_GENRATE_STATS
            if [[ ${!stats} == "YES" ]] ; then
                stats_file_format="${NE}"_STATS_OUTPUT_FILE_FORMAT
                stats_output_type="${NE}"_STATS_OUTPUT_TYPE
                stats_input_location="${NE}"_STATS_INPUT_LOCATION
                script="startStatsPlayback.sh"
                stats_TZ="$NE"_STATS_OUTPUT_TZ
                stats_update_TZ="${NE}"_STATS_UPDATE_TZ
                append_path="$NE"_PM_FileLocation
                if [[ -z ${!append_path} ]];then
                    append_path="$NE"_STATS_APPEND_PATH
                fi
                if [[ ${!stats_TZ} == "LOCAL" ]] ; then
                    if [[ ${NE} == "SBG_IS" ]] ; then
                        ROP_START_TIME_LOCAL=`date "+%H%M"`${ZERO}
                        ROP_END_TIME_LOCAL=`date --date "+${ROP_PERIOD_MIN}mins" "+%H%M"`${ZERO}
                    fi
                    ROP_START_TIME_STATS=${ROP_START_TIME_LOCAL}${ROP_LOCAL_OFFSET}
                    ROP_END_TIME_STATS=${ROP_END_TIME_LOCAL}${ROP_LOCAL_OFFSET}
                    ROP_END_DATE=${ROP_END_DATE_LOCAL}
                else
                    if [[ ${NE} == "SBG_IS" ]] ; then
                        ROP_START_TIME=`date -u "+%H%M"`${ZERO}
                        ROP_END_TIME=`date -u --date "+${ROP_PERIOD_MIN}mins" "+%H%M"`${ZERO}
                    fi
                    ROP_START_TIME_STATS=${ROP_START_TIME}
                    ROP_END_TIME_STATS=${ROP_END_TIME}
                    ROP_END_DATE=${ROP_END_DATE_UTC}
                fi

                if [[ ${NE} == "SBG_IS" ]] ; then
                    stats_args="${PM_DIR};${!append_path};${SIM_NAME};${!stats_file_format};${!stats_output_type};${!stats_input_location};${DATE};${ROP_START_TIME_STATS};${ROP_END_TIME_STATS};${LOG};stats;${script};${ROP_PERIOD_MIN};${ROP_END_DATE};${UNIQUE_ID}"
                    /${INSTALL_DIR}/startFileDistribution.sh ${stats_args} &
                elif [[ ${NE} == "HSS_FE_TSP" ]] || [[ ${NE} == "MTAS_TSP" ]] || [[ ${NE} == "CSCF_TSP" ]] || [[ ${NE} == "SAPC_TSP" ]] ; then
                    MEASUREMENT_JOB_NAME="${NE}"_MEASUREMENT_JOB_NAME
                    stats_input_location=${!stats_input_location}
                    for JOB_NAME in ${!MEASUREMENT_JOB_NAME}; do
                        stats_args="${PM_DIR};${!append_path};${SIM_NAME};${!stats_file_format};${!stats_output_type};${stats_input_location}/${JOB_NAME};${DATE};${ROP_START_TIME_STATS};${ROP_END_TIME_STATS};${LOG}_${JOB_NAME};stats;${script};${ROP_PERIOD_MIN};${ROP_END_DATE};${JOB_NAME}"
                        /${INSTALL_DIR}/startFileDistribution.sh ${stats_args} &
                    done
                elif [[ ${NE} == "FrontHaul" ]] && [[ ${!stats_update_TZ} == "YES" ]]; then
                    stats_args="${PM_DIR};${!append_path};${SIM_NAME};${!stats_file_format};${!stats_output_type};${!stats_input_location};${DATE};${ROP_START_TIME_STATS};${ROP_END_TIME_STATS};${LOG};stats;${script};${ROP_PERIOD_MIN};${ROP_END_DATE};${FILE_beginTime};${FILE_endTime};${dur}"
                    /${INSTALL_DIR}/startFileDistribution.sh ${stats_args} &
                else
                    stats_args="${PM_DIR};${!append_path};${SIM_NAME};${!stats_file_format};${!stats_output_type};${!stats_input_location};${DATE};${ROP_START_TIME_STATS};${ROP_END_TIME_STATS};${LOG};stats;${script};${ROP_PERIOD_MIN};${ROP_END_DATE};"
                    /${INSTALL_DIR}/startFileDistribution.sh ${stats_args} &
                fi
        fi

        #For EVENTS file generation
        events="$NE"_GENRATE_EVENTS
        if [[ ${!events} == "YES" ]] ; then
            events_file_format="${NE}"_EVENTS_OUTPUT_FILE_FORMAT
            events_output_type="${NE}"_EVENTS_OUTPUT_TYPE
            events_input_location="${NE}"_EVENTS_INPUT_LOCATION
            script="startEventsPlayback.sh"
            events_TZ="$NE"_EVENTS_OUTPUT_TZ
            append_path="$NE"_PMEvent_FileLocation
            if [[ -z ${!append_path} ]];then
                append_path="$NE"_EVENTS_APPEND_PATH
            fi
            if [[ ${!events_TZ} == "LOCAL" ]] ; then
                ROP_START_TIME_EVENTS=${ROP_START_TIME_LOCAL}${ROP_LOCAL_OFFSET}
                ROP_END_TIME_EVENTS=${ROP_END_TIME_LOCAL}${ROP_LOCAL_OFFSET}
                ROP_END_DATE=${ROP_END_DATE_LOCAL}
            else
                ROP_START_TIME_EVENTS=${ROP_START_TIME}
                ROP_END_TIME_EVENTS=${ROP_END_TIME}
                ROP_END_DATE=${ROP_END_DATE_UTC}
            fi
            events_args="${PM_DIR};${!append_path};${SIM_NAME};${!events_file_format};${!events_output_type};${!events_input_location};${DATE};${ROP_START_TIME_EVENTS};${ROP_END_TIME_EVENTS};${LOG};events;${script};${ROP_PERIOD_MIN};${ROP_END_DATE}"
            /${INSTALL_DIR}/startFileDistribution.sh ${events_args} &
        fi
      fi
      fi
    done
done

log "End ${STARTDATE_UTC}"

