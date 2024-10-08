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
# Version no    :  NSS 17.11
# Purpose       :  Script to create scanners for RNC, RBS, ERBS nodes
# Jira No       :  NSS-10378
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2446296/9
# Description   :  Ignoring WCDMA PICO sim for scanner perspective
# Date          :  20/06/2017
# Last Modified :  abhishek.mandlewala@tcs.com
####################################################

#!/bin/bash

BIN_DIR=`dirname $0`
BIN_DIR=`cd ${BIN_DIR} ; pwd`
. ${BIN_DIR}/functions

SIM_DATA_FILE="/netsim/genstats/tmp/sim_data.txt"

createScanners() {

    CMD_FILE=/tmp/create_scanners.cmd
    if [ -r ${CMD_FILE} ] ; then
	rm -f ${CMD_FILE}
    fi

    # By default scanner will be created with SUSPENDED state but
    # create PREDEFINED STATS scanner with state as ACTIVE unless it is mentioned as
    # PREDEFINED_STATS_SCANNER_STATE=SUSPENDED
    if [ "${PREDEFINED_STATS_SCANNER_STATE}" = "SUSPENDED"  ] ; then
	 SCANNER_STATE=""
    else
 	 SCANNER_STATE=",state=\"ACTIVE\""
    fi

    for SIM in $LIST ; do
    # WRAN
	SIM_TYPE=`getSimType ${SIM}`
	SIM_NAME=`ls /netsim/netsimdir | grep -w ${SIM} | grep -v zip`

	if [ "${SIM_TYPE}" = "WRAN" ] ; then
	    cat "${SIM_DATA_FILE}" | grep ${SIM} | grep -w "PRBS" > /dev/null 2>&1
	    if [ $? -eq 0 ]; then
	        continue
	    fi
	    cat >> ${CMD_FILE} <<EOF
.open ${SIM_NAME}

.selectnetype RNC
EOF

#UETR Scanners
scannerId=1
for scanner in {10000..10115}; do
cat >> ${CMD_FILE} <<EOF
createscanner2:id=$scannerId,measurement_name="PREDEF.$scanner.UETR";
EOF
        scannerId=$(($scannerId+1))
done

#CTR Scanners
for scanner in {20000..20001}; do
cat >> ${CMD_FILE} <<EOF
createscanner2:id=$scannerId,measurement_name="PREDEF.$scanner.CTR";
EOF
        scannerId=$(($scannerId+1))
done

#GPEH Scanners
for scanner in {30000..30023}; do
cat >> ${CMD_FILE} <<EOF
createscanner2:id=$scannerId,measurement_name="PREDEF.$scanner.GPEH";
EOF
        scannerId=$(($scannerId+1))
done

#Predef Stats Scanners
cat >> ${CMD_FILE} <<EOF
createscanner2:id=$scannerId,measurement_name="PREDEF.PRIMARY.STATS"${SCANNER_STATE};
EOF
scannerId=$(($scannerId+1))
cat >> ${CMD_FILE} <<EOF
createscanner2:id=$scannerId,measurement_name="PREDEF.SECONDARY.STATS"${SCANNER_STATE};
EOF
scannerId=$(($scannerId+1))

#GPEH Scanners
for scanner in {60000..60015}; do
cat >> ${CMD_FILE} <<EOF
createscanner2:id=$scannerId,measurement_name="PREDEF.$scanner.GPEH";
EOF
        scannerId=$(($scannerId+1))
done

#RBS Scanners
cat >> ${CMD_FILE} <<EOF
.selectnetype RBS
createscanner2:id=$scannerId,measurement_name="PREDEF.PRIMARY.STATS"${SCANNER_STATE};
EOF
scannerId=$(($scannerId+1))
cat >> ${CMD_FILE} <<EOF
createscanner2:id=$scannerId,measurement_name="PREDEF.RBS.GPEH";
EOF
scannerId=$(($scannerId+1))

	elif [ "${SIM_TYPE}" = "LTE" ] ; then
	    cat >> ${CMD_FILE} <<EOF
.open ${SIM_NAME}
.selectnetype ERBS
EOF
scannerId=1

#CELLTRACE Scanners
for scanner in {10000..10005}; do
cat >> ${CMD_FILE} <<EOF
createscanner2:id=$scannerId,measurement_name="PREDEF.$scanner.CELLTRACE";
EOF
        scannerId=$(($scannerId+1))
done

cat >> ${CMD_FILE} <<EOF
createscanner2:id=$scannerId,measurement_name="PREDEF.STATS"${SCANNER_STATE};
EOF
	fi
    done

    log "INFO: Creating scanners"
    /netsim/inst/netsim_pipe < ${CMD_FILE}
}

deleteScanners() {
    CMD_FILE=/tmp/delete_scanners.cmd
    if [ -r ${CMD_FILE} ] ; then
	rm -f ${CMD_FILE}
	rm -f /tmp/scannerlist.txt
    fi

    for SIM in $LIST ; do
	SIM_TYPE=`getSimType ${SIM}`
	SIM_NAME=`ls /netsim/netsimdir | grep -w ${SIM} | grep -v zip`

	log "INFO: Reading scanners in ${SIM}"

	NE_TYPE_LIST=""
	if [ "${SIM_TYPE}" = "WRAN" ] ; then
	    cat "${SIM_DATA_FILE}" | grep ${SIM} | grep -w "PRBS" > /dev/null 2>&1
	    if [ $? -eq 0 ]; then
	        continue
	    fi
	    NE_TYPE_LIST="RNC RBS"
	elif [ "${SIM_TYPE}" = "LTE" ] ; then
	    NE_TYPE_LIST="ERBS"
	fi

	echo ".open ${SIM_NAME}" >> ${CMD_FILE}

	for NE_TYPE in ${NE_TYPE_LIST} ; do
	    /netsim/inst/netsim_pipe <<EOF > /tmp/scannerlist.txt
.open ${SIM_NAME}
.selectnetype ${NE_TYPE}
showscanners2;
EOF
	    echo ".selectnetype ${NE_TYPE}" >> ${CMD_FILE}
	    # New a sort -u cause now we're get an output per NE
            cat /tmp/scannerlist.txt | awk '{ if ( $2 ~ /^PREDEF/ ) {print $1} }' | sort -un \
                | awk '{ printf "deletescanner2:id=%d;\n", $1; }' \
                >> ${CMD_FILE}
	done
    done

    log "INFO: Deleting scanners"
    /netsim/inst/netsim_pipe < ${CMD_FILE}
}

DEPLOY=0
ACTION=""
while getopts "a:s:d" flag ; do
    case "$flag" in
	a) ACTION="${OPTARG}";;
        d) DEPLOY=1;;
        s) SERVERS="${OPTARG}";;

	*) echo "ERROR: Unknown arg $flag"
	   exit 1;;
    esac
done

if [ -z "${ACTION}" ]; then
    echo  "ERROR: Usage $0 -g cfg -d [-s servers]"
    exit 1
fi

if [ ${DEPLOY} -eq 1 ] ; then
    if [ -z "${SERVERS}" ] ; then
	. ${CFG} > /dev/null
    fi
    if [ -z "${SERVERS}" ] ; then
	log "ERROR: SERVERS not set"
	exit 1
    fi

    for SERVER in ${SERVERS} ; do
	log ${SERVER}
	rsh -l netsim ${SERVER} "/netsim_users/pms/bin/scanners.sh -a ${ACTION} > /netsim_users/pms/logs/scanners.log 2>&1"
	rsh -l netsim ${SERVER} "grep -i error /netsim_users/pms/logs/scanners.log" | grep -i error > /dev/null
	if [ $? -eq 0 ] ; then
	    log "ERROR: Failed, see /netsim_users/pms/logs/scanners.log on ${SERVER} for more detail"
	    exit 1
	fi
    done
else
    . /netsim/netsim_cfg > /dev/null 2>&1

    if [ "${ACTION}" = "create" ] ; then
	deleteScanners
	createScanners
    else
	deleteScanners
    fi
fi

