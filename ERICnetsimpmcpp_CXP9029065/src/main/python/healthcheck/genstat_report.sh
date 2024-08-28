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
# Purpose       :  This script is responisible for initiating health check w.r.t stats and events workload.
# Jira No       :  NSS-16209
# Gerrit Link   :
# Description   :  Configurable interval handling for periodic HC
# Date          :  19/12/2017
# Last Modified :  abhishek.mandlewala@tcs.com
####################################################

BIN_DIR=`dirname $0`
BIN_DIR=`cd ${BIN_DIR} ; pwd`
. /netsim/netsim_cfg

FUNC_FILE="/netsim_users/pms/bin/functions"

if [[ -f "${FUNC_FILE}" ]]; then
    . ${FUNC_FILE}
else
    echo "ERROR: ${FUNC_FILE} file not found."
    exit 1
fi

SYSTEM_DATETIME=$(date | awk -F' ' '{print $4}')
HOUR_OF_SYSTEM_TIME=$(echo ${SYSTEM_DATETIME} | cut -d':' -f1 | bc)
MINUTE_OF_SYSTEM_TIME=$(echo ${SYSTEM_DATETIME} | cut -d':' -f2 | bc)

while getopts  "p:" flag
do
    case "$flag" in
        p) periodicity="$OPTARG";;
        *) printf "Usage: %s < -p periodicity (true/false) >\n" $0
           exit 1;;
    esac
done

PHC_PRECHECK="/netsim_users/hc/bin/periodic_hc_precheck.sh"
PHC_LOGCHECK="/netsim_users/hc/bin/periodicGenstatsLogsChecking.py"
periodic_bool="false"

checkForTimeMatching(){
    time_one=$1
    time_two=$2

    if [[ ${time_one} -eq ${time_two} ]]; then
        echo "0"
        return
    fi

    echo "1"
    return
}


executeHealthCheck(){

    SIM_LIST=`eval echo '$'${HOSTNAME/-/_}_list`
    MME_SIM_LIST=`eval echo '$'${HOSTNAME/-/_}_mme_list`
    SIM_LIST="${SIM_LIST} ${MME_SIM_LIST} ${PLAYBACK_SIM_LIST}"
    CONSOLIDATED_SIM_LIST=`echo ${SIM_LIST//[[:blank:]]/}`

    GENSTATS_CHECKING="${BIN_DIR}/genstats_checking.py -l ${SIM_LIST} -ul ${LTE_UETRACE_LIST} ${MSRBS_V1_LTE_UETRACE_LIST} ${MSRBS_V2_LTE_UETRACE_LIST} ${VTF_UETRACE_LIST} -b ${SET_BANDWIDTH_LIMITING} -recwl ${RECORDING_WORKLOAD_LIST} -statswl ${STATS_WORKLOAD_LIST} -gpehwl ${GPEH_WORKLOAD_LIST} -rbsgpehwl ${GPEH_RBS_WORKLOAD} -gpehmpcells ${GPEH_MP_CONFIG_LIST} -deployment ${TYPE} -edeStatsCheck ${edeStatsCheck} -periodicHC ${periodic_bool}"

    GENSTATS_CHECKING_NRM="${BIN_DIR}/genstats_checking.py -l ${SIM_LIST} -ul ${LTE_UETRACE_LIST} ${MSRBS_V1_LTE_UETRACE_LIST} ${MSRBS_V2_LTE_UETRACE_LIST} ${VTF_UETRACE_LIST} -b ${SET_BANDWIDTH_LIMITING} -recwl ${RECORDING_WORKLOAD_LIST} -statswl ${STATS_WORKLOAD_LIST} -deployment ${TYPE} -edeStatsCheck ${edeStatsCheck} -periodicHC ${periodic_bool}"

    if [[ ! -z ${CONSOLIDATED_SIM_LIST} ]]; then
        if [ ${TYPE} == "NRM1.2" ]; then
            if [[ ! -z ${PLAYBACK_SIM_LIST} ]];then
                python ${GENSTATS_CHECKING_NRM} -playbacksimlist ${PLAYBACK_SIM_LIST}
            else
                python ${GENSTATS_CHECKING_NRM}
            fi
        else
            if [[ ! -z ${PLAYBACK_SIM_LIST} ]];then
                python ${GENSTATS_CHECKING} -playbacksimlist ${PLAYBACK_SIM_LIST}
            else
                python ${GENSTATS_CHECKING}
            fi
        fi
    fi
}


checkForTimeInterval(){

    interval=$1

    duration_val_in=$(echo ${interval} | rev | cut -c -1)
    time_instance=$(echo ${interval} | sed "s/${duration_val_in}//g")

    re="^[0-9]+$"

    if [[ "${duration_val_in}" != "M" ]] && [[ "${duration_val_in}" != "H" ]]; then
        echo "5"
        return
    fi

    if [[ ${time_instance} =~ $re ]]; then

        time_instance=$(echo ${time_instance} | bc)
        counter="1"

        if [[ "${duration_val_in}" == "M" ]]; then

            if [[ ${time_instance} -gt 60 ]] || [[ ${time_instance} -lt 0 ]]; then
                 echo "4"
                 return
            fi

            if [[ ${time_instance} -eq 0 ]] || [[ ${time_instance} -eq 60 ]]; then
                new_interval="7"
                re_code=$(checkForTimeMatching ${new_interval} ${MINUTE_OF_SYSTEM_TIME})
                echo "${re_code}"
                return
            else
                count_instance=$((60/${time_instance}))
                while [ ${counter} -le ${count_instance} ]
                do
                    new_interval=$((${counter}*${time_instance}))
                    new_interval=$((${new_interval}+7))
                    if [[ ${new_interval} -ge 60 ]]; then
                        new_interval=$((${new_interval}-60))
                    fi
                    re_code=$(checkForTimeMatching ${new_interval} ${MINUTE_OF_SYSTEM_TIME})
                    if [[ ${re_code} -eq 0 ]]; then
                        echo "${re_code}"
                        return
                    fi
                    counter=$((counter+1))
                done
                echo "1"
                return
            fi

        elif [[ "${duration_val_in}" == "H" ]]; then

            if [[ ${time_instance} -gt 24 ]] || [[ ${time_instance} -lt 0 ]]; then
                echo "3"
                return
            fi

            if [[ ${time_instance} -eq 0 ]] || [[ ${time_instance} -eq 24 ]]; then
                new_interval="7"

                if [[ ${HOUR_OF_SYSTEM_TIME} -eq 0 ]]; then
                    re_code=$(checkForTimeMatching ${new_interval} ${MINUTE_OF_SYSTEM_TIME})
                    echo "${re_code}"
                    return
                fi
            else
                count_instance=$((24/${time_instance}))
                while [ ${counter} -le ${count_instance} ]
                do
                    new_interval=$((${counter}*${time_instance}))
                    if [[ "${new_interval}" = "${HOUR_OF_SYSTEM_TIME}" ]]; then
                        if [[ "${MINUTE_OF_SYSTEM_TIME}" = "7" ]]; then
                            echo "0"
                            return
                        fi
                    fi
                    counter=$((counter+1))
                done
            fi

            echo "1"
            return
        fi

        echo "1"
        return

    else
        echo "2"
        return

    fi
}

if [[ ! -z "${periodicity}" ]]; then

    periodicity=$(echo ${periodicity} | tr '[:upper:]' '[:lower:]')

    if [[ "${periodicity}" == "true" ]]; then
        param_check=$(cat /netsim/netsim_cfg | grep PERIODIC_HC_INTERVAL | grep -v '#' | wc -l)
        
        if [[ "${TYPE}" = "NSS" ]]; then
            log "WARN: Periodic HC can not be executed for deployment ${TYPE}."
            exit 1
        fi
        
        if [[ ${param_check} -ne 1 ]]; then
            log "WARN: Multiple or No entry defined in /netsim/netsim_cfg for periodic HC."
            exit 1
        fi

        PERIODIC_HC_INTERVAL=$(echo ${PERIODIC_HC_INTERVAL} | tr '[:lower:]' '[:upper:]' | sed 's/ //g')
        check=$(checkForTimeInterval ${PERIODIC_HC_INTERVAL})
        if [[ ${check} -eq 0 ]]; then
            if [[ -f "${PHC_PRECHECK}" ]] && [[ -f "${PHC_LOGCHECK}" ]]; then
                periodic_file_check="/tmp/.first_periodic_hc_exec"
                if [[ -f ${periodic_file_check} ]]; then
                    periodic_bool="true"
                else
                    touch ${periodic_file_check}
                    exit 0
                fi
            else
                log "WARNING: ${PHC_PRECHECK} or ${PHC_LOGCHECK} script not available."
                exit 1
            fi
        elif [[ ${check} -eq 2 ]]; then
            log "ERROR: Time interval value is not provided properly in periodic interval value."
        elif [[ ${check} -eq 3 ]]; then
            log "ERROR: Time interval hour value can not be greater than 24."
        elif [[ ${check} -eq 4 ]]; then
            log "ERROR: Time interval minute value can not be greater than 59."
        elif [[ ${check} -eq 5 ]]; then
            log "ERROR: Minute or Hour character not found in periodic interval value."
        fi

        if [[ "${periodic_bool}" != "true" ]]; then
            exit 1
        fi

    else
        exit 1
    fi
fi


# print installed genStats RPM version
RPM_VERSION=`rpm -q ERICnetsimpmcpp_CXP9029065`
log "INFO: genStats RPM version: ${RPM_VERSION}"

if [[ "${periodic_bool}" == "true" ]]; then
    log "INFO: Initializing periodic Health Check"
    log "INFO: Calling ${PHC_PRECHECK} script."
    ${PHC_PRECHECK}
    log "INFO: Calling ${PHC_LOGCHECK} scripts to check PM file generation logs."
    python ${PHC_LOGCHECK}

    executeHealthCheck
else
    QA_LOG_FILE="/netsim/genstats/logs/genstatsQA.log"

    echo "INFO: Starting GenStats rollout verification "

    if [ -f ${QA_LOG_FILE} ]; then
        rm -rf ${QA_LOG_FILE}
        echo "INFO: removed existing ${QA_LOG_FILE} "
    fi

    if [ ! -f /netsim/genstats/tmp/sim_data.txt ]; then
        echo "INFO: Generating /netsim/genstats/tmp/sim_data.txt file."
        /netsim_users/auto_deploy/bin/getSimulationData.py
        echo "INFO: /netsim/genstats/tmp/sim_data.txt file generated."
    fi

    START_TIMESTAMP=$(date "+%F %T %Z")
    echo "INFO: GenStats QA logging started: ${START_TIMESTAMP}" >> ${QA_LOG_FILE}

    # remove old log files
    /usr/bin/rsh -l root $HOST "python /netsim_users/pms/bin/removeLogFiles.py"

    # execute 15 min ROP
    crontab -l | grep -v '^#' | grep -i gpeh | sed 's/.* \* \//\//' | while read line;
    do
        if [[ "${line}" = *"genGPEH"* ]] && [[ "${line}" = *"15_max"* ]]; then
            continue
        fi

        if [[ ${TYPE} == "NSS" ]] && [[ "${line}" = *"genGPEH"* ]] && [[ "${line}" = *"1_default"* ]] ; then
            continue
        fi

        command=$(echo $line | sed 's/ >> .*//');
        log_file=$(echo $line | rev | cut -d' ' -f2 | rev);
        eval $command >> $log_file;
    done &

    /netsim_users/pms/bin/genStats -r 15 >> /netsim_users/pms/logs/genStats_15min.log 2>&1 &
    /netsim_users/pms/bin/lte_rec.sh -r 15 >> /netsim_users/pms/logs/lte_rec_15min.log 2>&1 &
    /netsim_users/pms/bin/startPlaybacker.sh -r 15 >> /netsim_users/pms/logs/playbacker_15min.log 2>&1 &
    /netsim_users/pms/bin/wran_rec.sh -l DEFAULT -r 15 >> /netsim_users/pms/logs/wran_rec.log 2>&1 &

    wait

    executeHealthCheck

    END_TIMESTAMP=$(date "+%F %T %Z")
    echo "INFO: GenStats QA logging ended: ${END_TIMESTAMP}" >> ${QA_LOG_FILE}
    echo "INFO: GenStats rollout verification complete"
fi

