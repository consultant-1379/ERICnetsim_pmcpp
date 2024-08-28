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
# Version no    :  NSS 17.10
# Purpose       :  The purpose of this script to call playbackGenerator framework to generate STATS PM files.
# Jira No       :  NSS-12596
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2333640/
# Description   :  Genstats - Fronthaul Simulation Delivery - Updated PM model + port change
# Date          :  01/06/2017
# Last Modified :  tejas.lutade@tcs.com
####################################################

#Fetching input arguments
ARGS=$1
PM_DIR=`echo $ARGS|cut -d";" -f1`
APPEND_PATH=`echo $ARGS|cut -d";" -f2`
NE_TYPE=`echo $ARGS|cut -d";" -f3`
FILE_FORMAT=`echo $ARGS|cut -d";" -f4`
OUTPUT_TYPE=`echo $ARGS|cut -d";" -f5`
INPUT_LOCATION=`echo $ARGS|cut -d";" -f6`
DATE=`echo $ARGS|cut -d";" -f7`
ROP_START_TIME=`echo $ARGS|cut -d";" -f8`
ROP_END_TIME=`echo $ARGS|cut -d";" -f9`
INSTALL_DIR=`echo $ARGS|cut -d";" -f10`
LOG=`echo $ARGS|cut -d";" -f11`
START_INDEX=`echo $ARGS|cut -d";" -f12`
END_INDEX=`echo $ARGS|cut -d";" -f13`
FINAL_MAPPED_FILE=`echo $ARGS|cut -d";" -f14`
SCRIPT_NUMBER=`echo $ARGS|cut -d";" -f15`
PROCESS_TYPE=`echo $ARGS|cut -d";" -f16`
ROP_PERIOD=`echo $ARGS|cut -d";" -f17`
ROP_END_DATE=`echo $ARGS|cut -d";" -f18`
UNIQUE_ID="99999"
dur=`echo ${ARGS}|cut -d";" -f21`

if [[ $NE_TYPE == *"SBG-IS"* ]]; then
    UNIQUE_ID=`echo $ARGS|cut -d";" -f19`
fi

if [[ $NE_TYPE == *"HSS-FE-TSP"* ]] || [[ $NE_TYPE == *"MTAS-TSP"* ]] || [[ $NE_TYPE == *"CSCF-TSP"* ]] || [[ $NE_TYPE == *"SAPC-TSP"* ]] ; then
    MEASUREMENT_JOB_ID=`echo ${ARGS}|cut -d";" -f19`
fi

if [[ $NE_TYPE == *"FrontHaul"* ]] && [[ $dur == "900" ]] || [[ $dur == "60" ]] || [[ $dur == "86400" ]]; then
	FILE_beginTime=`echo ${ARGS}|cut -d";" -f19`
	FILE_endTime=`echo ${ARGS}|cut -d";" -f20`
	dur=`echo ${ARGS}|cut -d";" -f21`
fi
targetFile="$LOG/$NE_TYPE"_"$PROCESS_TYPE"_"$ROP_PERIOD/mappedfile_$SCRIPT_NUMBER"

sed -n ${START_INDEX},${END_INDEX}p $FINAL_MAPPED_FILE > $targetFile

BCK_FILE_FORMAT=${FILE_FORMAT}

for fname in `cat $targetFile`; do
        sourceFile=`echo $fname | cut -d";" -f1`
        targetDir=`echo $fname | cut -d";" -f2`
        sourceFile=$INPUT_LOCATION/$sourceFile
        FILE_FORMAT=${BCK_FILE_FORMAT}
        FILE_FORMAT="${FILE_FORMAT/DATE/$DATE}"
        FILE_FORMAT="${FILE_FORMAT/ROP_START_TIME/$ROP_START_TIME}"
        FILE_FORMAT="${FILE_FORMAT/ROP_END_TIME/$ROP_END_TIME}"
        FILE_FORMAT="${FILE_FORMAT/ROP_END_DATE/$ROP_END_DATE}"
        FILE_FORMAT="${FILE_FORMAT/UNIQUE_ID/$UNIQUE_ID}"
        FILE_FORMAT="${FILE_FORMAT/MEASUREMENT_JOB_NAME/$MEASUREMENT_JOB_ID}"
        FILE_FORMAT="${FILE_FORMAT/MANAGED_ELEMENT_ID/$targetDir}"
        OUTPUT_PATH=$PM_DIR/$NE_TYPE/$targetDir/fs/$APPEND_PATH
        if [[ ${APPEND_PATH} == *"fs"* ]];then
            OUTPUT_PATH=$PM_DIR/$NE_TYPE/$targetDir/$APPEND_PATH
        fi
        if [ ! -d ${OUTPUT_PATH} ];then
            mkdir -p ${OUTPUT_PATH}
        fi
        outputFile=${OUTPUT_PATH}/$FILE_FORMAT
        if [ $OUTPUT_TYPE == "COPY" ]; then
                /${INSTALL_DIR}/playbackGenerator.sh $sourceFile $outputFile -c &
        elif [ $OUTPUT_TYPE == "ZIP" ]; then
                /${INSTALL_DIR}/playbackGenerator.sh $sourceFile $outputFile -g &
		elif [ $OUTPUT_TYPE == "STAMPED" ]; then
                if [[ $NE_TYPE == *"FrontHaul"* ]]; then
				/${INSTALL_DIR}/playbackGenerator.sh $sourceFile $outputFile -s $NE_TYPE $FILE_beginTime $FILE_endTime $dur &
				fi
        else
                /${INSTALL_DIR}/playbackGenerator.sh $sourceFile $outputFile -l &
        fi
done
