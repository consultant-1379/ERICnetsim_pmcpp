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
# Version no    :  NSS 17.12
# Purpose       :  The purpose of this script to create required directory structure in /pms_tmpfs
# Jira No       :  NSS-15546
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2906126/
# Description   :  Handling for MSC nodes support.
# Date          :  14/11/2017
# Last Modified :  r.t2@tcs.com
####################################################

GENSTATS_CONSOLELOGS="/netsim/genstats/logs/rollout_console/genstats_settmpfs.log"

SIM_NAME=$1

. /netsim/netsim_cfg > /dev/null 2>&1

OUT_ROOT=/netsim_users
if [ -d /pms_tmpfs ] ; then
   OUT_ROOT=/pms_tmpfs
fi

if [ "${TYPE}" = "NRM3" ] || [ "${TYPE}" = "NRM1.2" ]; then
    echo 'Executing settmpfs for NRM deployment'
    bash /netsim_users/pms/bin/settmpfsWrapper.sh
    exit 1
fi

#Support CORE/GRAN ECIM simulation
# No tmpfs for SGSN nodes

LIST="${LIST}"

MINILINK_SIM=`ls /netsim/netsimdir/ | grep 'ML' | grep 'CORE' | grep -v .zip | tr '\n' ' ' | sed 's/.$//'`

if [ $? -eq 0 ]; then
    LIST=${LIST}" "${MINILINK_SIM}
fi

if [ ! -z "${SIM_NAME}" ] ; then
    LIST=${SIM_NAME}
fi

for SIM in $LIST ; do
  if grep -q $SIM "/tmp/showstartednodes.txt"; then

    echo "${SIM}" | egrep "SGSN|BSC|MSC" > /dev/null

    if [ $? -eq 0 ] ; then
        continue
    fi


    SIM_LIST=`ls /netsim/netsimdir | grep -w ${SIM} | grep -v zip`

    for SIM_NAME in ${SIM_LIST} ; do

        if [[ $SIM == *"LTE"* ]] || [[ $SIM == *"RNC"* ]]; then
            if [ "${SIM_NAME##*-}" != "${SIM}" ]; then
                continue
            fi
        fi

  /netsim/inst/netsim_pipe <<EOF | awk '{if ( $2 ~ /^fs$/ ) { NE = $1; } else if ( $1 ~ /^tmpfs$/ ) { printf "%s %s\n", NE, $2;} }' > /tmp/${SIM}_tmpfs.txt
.open ${SIM_NAME}
.selectnocallback network
.show fs
EOF
  NUM_NOT_SET=`cat /tmp/${SIM}_tmpfs.txt | egrep -v ": ${OUT_ROOT}/${SIM}/" | wc -l | awk '{print $0}'`
  if [ ${NUM_NOT_SET} -gt 0 ] ; then
      echo "INFO: Updating ${SIM}"
      #Check for CORE/GRAN SIM if so then SIM should be SIMNAME
      #DOG stands for GRAN DG2 SIMs

      echo "${SIM_NAME}" | egrep "DSC|ESAPC|TCU03|TCU04|DOG|CSCF|MTAS|SBG|WCG|HSS|RNNODE|VPP|VRC|VBGF|IPWORKS|C608|MRF|UPG|WMG|TCU02|SIU02|ML|EME|vPP|vRC|VTFRadioNode|5GRadioNode|VRM|vRM"

      if [ $? -eq 0 ] ; then

         SIM=${SIM_NAME}

      fi
  /netsim/inst/netsim_pipe <<EOF >> $GENSTATS_CONSOLELOGS
.open ${SIM_NAME}
.selectnocallback network
.stop -parallel
.set fs tmpfs ${OUT_ROOT}/${SIM}/%nename force
.set save
.start
EOF
            if [[ ${SIM} == *"TCU02"* || ${SIM} == *"SIU02"* || "${SIM#*"ML"}" != "${SIM}" ]]; then
                rm -rf ${OUT_ROOT}/${SIM}
                while read line
                do
                    node_name=$(echo ${line} | cut -d":" -f1 | sed 's/ //g')
                    mkdir -p ${OUT_ROOT}/${SIM}/${node_name}/c/pm_data/
                done < /tmp/${SIM}_tmpfs.txt
            fi
  else
      echo "INFO: No update required for ${SIM}"
  fi
 done
  fi
done
# Remove file locations files if any created by netsim command 'set fs tmpfs'
find ${OUT_ROOT} \( -name 'UeTraceFilesLocation'  -o -name 'CellTraceFilesLocation' \) -exec rm {} \;

