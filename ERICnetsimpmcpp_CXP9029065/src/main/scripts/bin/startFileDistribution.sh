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
# Version no    :  NSS 17.9
# Purpose       :  The purpose of this script to distribute files amongst respective child scripts.
# Jira No       :  NSS-10470
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2333640/
# Description   :  Genstats- PM for Fronthaul 6080 R17
# Date          :  5/10/2017
# Last Modified :  tejas.lutade@tcs.com
####################################################

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
LOG=`echo $ARGS|cut -d";" -f10`
PROCESS_TYPE=`echo $ARGS|cut -d";" -f11`
SCRIPT=`echo $ARGS|cut -d";" -f12`
ROP_PERIOD=`echo $ARGS|cut -d";" -f13`
ROP_END_DATE=`echo $ARGS|cut -d";" -f14`

INSTALL_DIR_NAME=`dirname $0`
INSTALL=`cd ${INSTALL_DIR_NAME} ; pwd`

targetDir=$LOG/$NE_TYPE"_"$PROCESS_TYPE"_"$ROP_PERIOD
rm -rf $targetDir
if [ ! -d "$targetDir" ]; then
        mkdir -p $targetDir
fi

completeOutDirsList="$targetDir/allOutputDirslist"
completeMappedFileList="$targetDir/mappedFilelist"
number_of_scripts=32

ls $PM_DIR/$NE_TYPE | sort > $completeOutDirsList

arrayOfInputFiles=( `ls $INPUT_LOCATION` )
index=0
while IFS='' read -r outDir || [[ -n "$outDir" ]]; do
       echo ${arrayOfInputFiles[$index]}";"$outDir >> $completeMappedFileList
       index=$((index+1))
       last_idx=$(( ${#arrayOfInputFiles[@]} - 1 ))
       if [ $index -gt $last_idx ];then
           index=0
       fi
done < $completeOutDirsList

start_index=1
end_index=$number_of_scripts
countOfMappedList=`wc -l < $completeOutDirsList`
counter=$(($countOfMappedList/$number_of_scripts))

target_out="$targetDir/batchfile"$$

if [ $counter -eq 0 ]; then
    if [[ $NE_TYPE == *"SBG-IS"* ]]; then
        UNIQUE_ID=`echo $ARGS|cut -d";" -f15`
        args="$PM_DIR;$APPEND_PATH;$NE_TYPE;$FILE_FORMAT;$OUTPUT_TYPE;$INPUT_LOCATION;$DATE;$ROP_START_TIME;$ROP_END_TIME;$INSTALL;$LOG;$start_index;$countOfMappedList;$completeMappedFileList;$start_index;$PROCESS_TYPE;$ROP_PERIOD;$ROP_END_DATE;$UNIQUE_ID"
    elif [[ $NE_TYPE == *"HSS-FE-TSP"* ]] || [[ $NE_TYPE == *"MTAS-TSP"* ]] || [[ $NE_TYPE == *"CSCF-TSP"* ]] || [[ $NE_TYPE == *"SAPC-TSP"* ]] ; then
        MEASUREMENT_JOB_NAME=`echo ${ARGS}|cut -d";" -f15`
        args="$PM_DIR;$APPEND_PATH;$NE_TYPE;$FILE_FORMAT;$OUTPUT_TYPE;$INPUT_LOCATION;$DATE;$ROP_START_TIME;$ROP_END_TIME;$INSTALL;$LOG;$start_index;$countOfMappedList;$completeMappedFileList;$start_index;$PROCESS_TYPE;$ROP_PERIOD;$ROP_END_DATE;${MEASUREMENT_JOB_NAME}"
    elif [[ $NE_TYPE == *"FrontHaul"* ]]; then
            FILE_beginTime=`echo ${ARGS}|cut -d";" -f15`
            FILE_endTime=`echo ${ARGS}|cut -d";" -f16`
            dur=`echo ${ARGS}|cut -d";" -f17`
            args="$PM_DIR;$APPEND_PATH;$NE_TYPE;$FILE_FORMAT;$OUTPUT_TYPE;$INPUT_LOCATION;$DATE;$ROP_START_TIME;$ROP_END_TIME;$INSTALL;$LOG;$start_index;$end_index;$completeMappedFileList;$c;$PROCESS_TYPE;$ROP_PERIOD;$ROP_END_DATE;$FILE_beginTime;$FILE_endTime;$dur"
    else
        args="$PM_DIR;$APPEND_PATH;$NE_TYPE;$FILE_FORMAT;$OUTPUT_TYPE;$INPUT_LOCATION;$DATE;$ROP_START_TIME;$ROP_END_TIME;$INSTALL;$LOG;$start_index;$countOfMappedList;$completeMappedFileList;$start_index;$PROCESS_TYPE;$ROP_PERIOD;$ROP_END_DATE"
    fi
        /${INSTALL}/$SCRIPT $args &
else
    for(( c=0; c < $counter; c++ ));do
        if [[ $NE_TYPE == *"SBG-IS"* ]]; then
            UNIQUE_ID=`echo $ARGS|cut -d";" -f15`
            args="$PM_DIR;$APPEND_PATH;$NE_TYPE;$FILE_FORMAT;$OUTPUT_TYPE;$INPUT_LOCATION;$DATE;$ROP_START_TIME;$ROP_END_TIME;$INSTALL;$LOG;$start_index;$end_index;$completeMappedFileList;$c;$PROCESS_TYPE;$ROP_PERIOD;$ROP_END_DATE;$UNIQUE_ID"
        elif [[ $NE_TYPE == *"HSS-FE-TSP"* ]] || [[ $NE_TYPE == *"MTAS-TSP"* ]] || [[ $NE_TYPE == *"CSCF-TSP"* ]] || [[ $NE_TYPE == *"SAPC-TSP"* ]] ; then
            MEASUREMENT_JOB_NAME=`echo ${ARGS}|cut -d";" -f15`
            args="$PM_DIR;$APPEND_PATH;$NE_TYPE;$FILE_FORMAT;$OUTPUT_TYPE;$INPUT_LOCATION;$DATE;$ROP_START_TIME;$ROP_END_TIME;$INSTALL;$LOG;$start_index;$countOfMappedList;$completeMappedFileList;$start_index;$PROCESS_TYPE;$ROP_PERIOD;$ROP_END_DATE;${MEASUREMENT_JOB_NAME}"
        elif [[ $NE_TYPE == *"FrontHaul"* ]]; then
            FILE_beginTime=`echo ${ARGS}|cut -d";" -f15`
            FILE_endTime=`echo ${ARGS}|cut -d";" -f16`
            dur=`echo ${ARGS}|cut -d";" -f17`
            args="$PM_DIR;$APPEND_PATH;$NE_TYPE;$FILE_FORMAT;$OUTPUT_TYPE;$INPUT_LOCATION;$DATE;$ROP_START_TIME;$ROP_END_TIME;$INSTALL;$LOG;$start_index;$end_index;$completeMappedFileList;$c;$PROCESS_TYPE;$ROP_PERIOD;$ROP_END_DATE;$FILE_beginTime;$FILE_endTime;$dur"
        else
            args="$PM_DIR;$APPEND_PATH;$NE_TYPE;$FILE_FORMAT;$OUTPUT_TYPE;$INPUT_LOCATION;$DATE;$ROP_START_TIME;$ROP_END_TIME;$INSTALL;$LOG;$start_index;$end_index;$completeMappedFileList;$c;$PROCESS_TYPE;$ROP_PERIOD;$ROP_END_DATE"
        fi
            /${INSTALL}/$SCRIPT $args &
            start_index=$((end_index+1))
        if [ $c -eq $((counter-2)) ]; then
            end_index=$countOfMappedList
        else
            end_index=$((end_index+$number_of_scripts))
        fi
    done
fi
