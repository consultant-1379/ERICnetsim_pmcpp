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
# Version no    :  NSS 17.17
# Purpose       :  Script to setup events file generation in Genstats
# Jira No       :  NSS-15652
# Gerrit Link   :  https://gerrit.ericsson.se/2862165
# Description   :  2.8MB Ue trace file not getting copied from /netsim/genstats during rollout
# Date          :  30/10/2017
# Last Modified :  mathur.priyank@tcs.com
####################################################


BIN_DIR=`dirname $0`
BIN_DIR=`cd ${BIN_DIR} ; pwd`
. ${BIN_DIR}/functions

GENSTATS_CONSOLELOGS="/netsim/genstats/logs/rollout_console/genstats_pm_recordings_UETR_CTR.log"
CONFIGFILE=/netsim/netsim_cfg
while getopts  "s:c:" flag
do
    case "$flag" in

	c) CONFIGFILE="$OPTARG";;
	s) SERVER_LIST="$OPTARG";;
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



# RECORDING_WORKLOAD_LIST variable is must as this defines the rop configuration if not present then log
# message and exit the program execution.
if [ -z "${RECORDING_WORKLOAD_LIST}" ] ; then
    log "Variable RECORDING_WORKLOAD_LIST not found or not set in config file hence RECORDING rollout cannot be done"
    exit 1
fi


checkPMDIR
if [ $? -ne 0 ] ; then
    log "ERROR: PMDIR not set correctly"
    exit 1
fi

NETSIM_PMS_DIR=/netsim_users/pms
NETSIM_BIN_DIR=${NETSIM_PMS_DIR}/bin
NETSIM_LOG_DIR=${NETSIM_PMS_DIR}/logs
NETSIM_REC_TEMPLATE_DIR=${NETSIM_PMS_DIR}/rec_templates

for SERVER in $SERVERS ; do
    # As this script gets run from the pm_setup_stats_recordings.sh which is common for LTE/WRAN
    # we should only setup rec if the server has any WRAN sims
    SERVER_HAS_WRAN=0
    SERVER_HAS_LTE=0
    SERVER_HAS_MME=0
    SERVER_SIM_LIST=`getSimListForServer ${SERVER}`
    for SIM in ${SERVER_SIM_LIST} ; do
	SIM_TYPE=`getSimType ${SIM}`
	if [ "${SIM_TYPE}" = "WRAN" ] ; then
	    SERVER_HAS_WRAN=1
	elif [ "${SIM_TYPE}" = "LTE" ] || [ "${SIM_TYPE}" = "VTF" ] ; then
	    SERVER_HAS_LTE=1
	fi
    done

    SERVER_MME_SIM_LIST=`getMMESimListForServer ${SERVER}`
    SERVER_MME_SIM_LIST="${SERVER_MME_SIM_LIST} ${SERVER_SIM_LIST}"

    if [ ! -z "${SERVER_MME_SIM_LIST}" ] ; then
    	SERVER_HAS_MME=1
    fi

    if [ ${SERVER_HAS_WRAN} -eq 1 ] || [ ${SERVER_HAS_LTE} -eq 1 ] || [ ${SERVER_HAS_MME} -eq 1 ] ; then
	log "INFO: ${SERVER}" >> $GENSTATS_CONSOLELOGS
	/usr/bin/rsh -l root ${SERVER} "if [ ! -d ${NETSIM_REC_TEMPLATE_DIR} ] ; then mkdir -p ${NETSIM_REC_TEMPLATE_DIR} ; chown -R netsim:netsim ${NETSIM_REC_TEMPLATE_DIR}; fi"

	FILE_LIST=""
	if [ ${SERVER_HAS_WRAN} -eq 1 ] ; then
	    FILE_LIST="${FILE_LIST} sam_uetr_walborg.bin.gz sam_ctr_walborg.bin.gz sam_uetr_walborg_1.bin.gz sam_ctr_walborg_1.bin.gz"
	fi

	if [ ${SERVER_HAS_LTE} -eq 1 ] ; then
	    # UeTrace
	    LTE_UETRACE_FILE_LIST="${LTE_UETRACE_LIST}"

	    if [[ -z "${LTE_UETRACE_LIST}" && -z "${MSRBS_V1_LTE_UETRACE_LIST}" && -z "${MSRBS_V2_LTE_UETRACE_LIST}" ]] ; then
		log "ERROR: LTE_UETRACE_LIST not set"
		exit 1
	    fi

	    if [[ -z "${LTE_UETRACE_LIST}" && -z "${MSRBS_V2_LTE_UETRACE_LIST}" ]] ; then
	        LTE_UETRACE_FILE_LIST="${MSRBS_V1_LTE_UETRACE_LIST}"
	    else
	        LTE_UETRACE_FILE_LIST="${LTE_UETRACE_FILE_LIST} ${MSRBS_V2_LTE_UETRACE_LIST}"
	    fi

	    for LTE_UETRACE in ${LTE_UETRACE_FILE_LIST} ; do
		LTE_UETRACE_FILE=`echo ${LTE_UETRACE} | awk -F: '{print $1}'`
		# Add the file to the list (if it's not already in the list)
		echo "${FILE_LIST}" | grep -w ${LTE_UETRACE_FILE} > /dev/null
		if [ $? -ne 0 ] ; then
		    FILE_LIST="${FILE_LIST} ${LTE_UETRACE_FILE}"
		fi
	    done

	    # CellTrace
	    if [ -z "${LTE_CELLTRACE_LIST}" ] ; then
		log "ERROR: LTE_CELLTRACE_LIST not set"
		exit 1
	    fi
	    for LTE_CELLTRACE in ${LTE_CELLTRACE_LIST} ; do
		LTE_CELLTRACE_FILE=`echo ${LTE_CELLTRACE} | awk -F: '{print $1}'`
		# Add the file to the list (if it's not already in the list)
		echo "${FILE_LIST}" | grep -w ${LTE_CELLTRACE_FILE} > /dev/null
		if [ $? -ne 0 ] ; then
		    FILE_LIST="${FILE_LIST} ${LTE_CELLTRACE_FILE}"
		fi
	    done
            if [ ! -z ${LTE_CELLTRACE_19MB_NODE} ] ; then
               echo "${FILE_LIST}" | grep -w ${LTE_CELLTRACE_19MB_FILE} > /dev/null
               if [ $? -ne 0 ] ; then
                  FILE_LIST="${FILE_LIST} ${LTE_CELLTRACE_19MB_FILE}"
               fi
           fi

	fi

        if [ ${SERVER_HAS_MME} -eq 1 ] ; then

	    if [ -z "${MME_EBS_FILE_LIST}" ] ; then
		log "ERROR: MME_EBS_FILE_LIST not set"
		exit 1
	    fi
	    for EBS_FILE in ${MME_EBS_FILE_LIST} ; do
		    FILE_LIST="${FILE_LIST} ${EBS_FILE}"
	    done

	    if [ -z "${MME_UETRACE_LIST}" ] ; then
		log "ERROR: MME_UETRACE_LIST not set"
		exit 1
	    fi

	    for UETRACE in ${MME_UETRACE_LIST} ; do
		UETRACE_FILE=`echo ${UETRACE} | awk -F: '{print $1}'`
		# Add the file to the list (if it's not already in the list)
		echo "${FILE_LIST}" | grep -w ${UETRACE_FILE} > /dev/null
		if [ $? -ne 0 ] ; then
		    FILE_LIST="${FILE_LIST} ${UETRACE_FILE}"
		fi
	    done

	    for CTUM in ${MME_CTUM_LIST} ; do
		CTUM_FILE=`echo ${CTUM} | awk -F: '{print $1}'`
		# Add the file to the list (if it's not already in the list)
		echo "${FILE_LIST}" | grep -w ${CTUM_FILE} > /dev/null
		if [ $? -ne 0 ] ; then
		    FILE_LIST="${FILE_LIST} ${CTUM_FILE}"
		fi
	    done

        fi

       if [ "${TYPE}" = "NSS" ]; then
           recording_files="recording_files"
       else
           recording_files="recording_files_NRM3"
       fi
	for FILE in  ${FILE_LIST}; do
	    if [ ! -r ${PMDIR}/${recording_files}/${FILE} ] ; then
		echo "ERROR: Could not find file ${PMDIR}/${recording_files}/${FILE}"
		exit 1
	    fi

	    log "INFO:  Copying ${FILE}" >> $GENSTATS_CONSOLELOGS
	    /bin/cp ${PMDIR}/${recording_files}/${FILE} ${NETSIM_REC_TEMPLATE_DIR}/${FILE}
	done

       if [ ${SERVER_HAS_WRAN} -eq 1 ] && [ ${SERVER_HAS_LTE} -ne 1 ];then
           for LTE_CELLTRACE in ${LTE_CELLTRACE_LIST} ; do
              LTE_CELLTRACE_FILE=`echo ${LTE_CELLTRACE} | awk -F: '{print $1}'`
              if [ ! -r ${PMDIR}/${recording_files}/${LTE_CELLTRACE_FILE} ] ; then
		   echo "INFO: Could not find file ${PMDIR}/${recording_files}/${LTE_CELLTRACE_FILE}" >> $GENSTATS_CONSOLELOGS
	       fi

		/bin/cp ${PMDIR}/${recording_files}/${LTE_CELLTRACE_FILE} ${NETSIM_REC_TEMPLATE_DIR}/${LTE_CELLTRACE_FILE}
           done
       fi

	/usr/bin/rsh -l netsim ${SERVER} "crontab -l | egrep -v '^# |wran_rec.sh|lte_rec.sh|red.sh|genLTECelltrace.sh|copy_UETraceloc.sh|genLTEUETrace.sh' > /tmp/rec_new_crontab"

	if [ ${SERVER_HAS_WRAN} -eq 1 ] ; then

	   for RECORDING_WORKLOAD in $RECORDING_WORKLOAD_LIST; do

               ROP_PERIOD=`echo ${RECORDING_WORKLOAD} | awk -F: '{print $1}'`

               case "${ROP_PERIOD}" in
                      1) DEFAULT_MINUTE_FIELD='0-9,16-59 *';
                         PEAK_MINUTE_FIELD='10-15 *';;
                     15) DEFAULT_MINUTE_FIELD='0,15,30,45 0-9,16-23';
                         PEAK_MINUTE_FIELD='0,15,30,45 10-15';;
                      *) printf " Invalid ROP interval : ${ROP_PERIOD} \n" $0
                          exit 1;;
               esac

               /usr/bin/rsh -l netsim ${SERVER} "echo \"${DEFAULT_MINUTE_FIELD} * * * ${NETSIM_BIN_DIR}/wran_rec.sh -l DEFAULT -r ${ROP_PERIOD} >> ${NETSIM_LOG_DIR}/wran_rec.log 2>&1\" >> /tmp/rec_new_crontab"
	           /usr/bin/rsh -l netsim ${SERVER} "echo \"${PEAK_MINUTE_FIELD} * * * ${NETSIM_BIN_DIR}/wran_rec.sh -l PEAK -r ${ROP_PERIOD} >> ${NETSIM_LOG_DIR}/wran_rec.log 2>&1\" >> /tmp/rec_new_crontab"

       done
	fi

	if [ ${SERVER_HAS_LTE} -eq 1 ] || [ ${SERVER_HAS_MME} -eq 1 ] ; then

		for RECORDING_WORKLOAD in $RECORDING_WORKLOAD_LIST; do

			ROP_PERIOD=`echo ${RECORDING_WORKLOAD} | awk -F: '{print $1}'`
                	NE_TYPES=`echo ${RECORDING_WORKLOAD} | awk -F: '{print $2}'`

			case "${ROP_PERIOD}" in
                	         1) MINUTE_FIELD="*";;
				15) MINUTE_FIELD="0,15,30,45";;
				 *) printf " Invalid ROP interval : ${ROP_PERIOD} \n" $0
				exit 1;;
		        esac
                     if [ "${TYPE}" = "NSS" ] ; then
                         if [ ${NE_TYPES} = "ALL" ] ; then
                            /usr/bin/rsh -l netsim ${SERVER} "echo \"${MINUTE_FIELD} * * * * ${NETSIM_BIN_DIR}/lte_rec.sh -r ${ROP_PERIOD} >> ${NETSIM_LOG_DIR}/lte_rec_${ROP_PERIOD}min.log 2>&1\" >> /tmp/rec_new_crontab"
                         else
                            NE_TYPES=$(echo $NE_TYPES | sed 's/,/ /g')
                            CMD="${MINUTE_FIELD} * * * * ${NETSIM_BIN_DIR}/lte_rec.sh -r ${ROP_PERIOD} -l \\\"${NE_TYPES}\\\""
                            /usr/bin/rsh -l netsim ${SERVER} "echo \"${CMD}  >> ${NETSIM_LOG_DIR}/lte_rec.sh_${ROP_PERIOD}min.log 2>&1 \" >> /tmp/_new_crontab"
			    fi
                     else
                         /usr/bin/rsh -l netsim ${SERVER} "echo \"${MINUTE_FIELD} * * * * /netsim_users/pms/bin/lte_rec.sh -r 15 -f CELLTRACE:UETRACE:CTUM >> /netsim_users/pms/logs/lte_rec_15min.log 2>&1 \" >> /tmp/rec_new_crontab"
                         /usr/bin/rsh -l netsim ${SERVER} "echo \"* * * * * /netsim_users/pms/bin/lte_rec.sh -r 1 -f EBS:EBM >> /netsim_users/pms/logs/lte_rec_1min.log 2>&1 \" >> /tmp/rec_new_crontab"
                     fi
		done
	fi

	/usr/bin/rsh -l netsim ${SERVER} "crontab /tmp/rec_new_crontab"
    else
	log "INFO: ${SERVER} has no WRAN or LTE sims, recordings setup not performed" >> $GENSTATS_CONSOLELOGS
    fi
done
