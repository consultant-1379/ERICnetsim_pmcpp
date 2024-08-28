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
# Version no    :  NSS 18.04
# Purpose       :  The purpose of this script to copy and link source to target file.
# Jira No       :  NSS-16745
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/3183695/
# Description   :  Unreal time-stamp in PM file collected for Fronthaul-6080 node
# Date          :  18/01/2018
# Last Modified :  r.t2@tcs.com
####################################################

source=$1
target=$2
type=$3
NE_TYPE=$4
if [[ $NE_TYPE == *"FrontHaul"* ]]; then
    FILE_beginTime=$5
    FILE_endTime=$6
    dur=$7
fi

if [ $type == "-c" ]; then
    cp $source $target &
elif [ $type == "-g" ];then
    gzip -c $source > $target.gz
elif [ $type == "-s" ];then
    if [[ $dur == "900" ]]; then
        sed -e "s/beginTime=\"2017-07-19T12:45:01+03:00\"/beginTime=\"${FILE_beginTime}\"/g" -e "s/endTime=\"2017-07-19T12:45:59+03:00\"/endTime=\"${FILE_endTime}\"/g" -e "s/endTime=\"2017-07-19T13:00:01+03:00\"/endTime=\"${FILE_endTime}\"/g" $source > $target
    elif [[ $dur == "60" ]]; then
        sed -e "s/beginTime=\"2017-07-19T12:45:01+03:00\"/beginTime=\"${FILE_beginTime}\"/g" -e "s/endTime=\"2017-07-19T12:45:59+03:00\"/endTime=\"${FILE_endTime}\"/g" -e "s/endTime=\"2017-07-19T13:00:01+03:00\"/endTime=\"${FILE_endTime}\"/g" -e "s/jobId=\"PRIMARY15MIN\"/jobId=\"PRIMARY1MIN\"/g" -e "s/duration=\"PT900S\"/duration=\"PT60S\"/g" $source > $target
    else
        sed -e "s/beginTime=\"2017-07-19T12:45:01+03:00\"/beginTime=\"${FILE_beginTime}\"/g" -e "s/endTime=\"2017-07-19T12:45:59+03:00\"/endTime=\"${FILE_endTime}\"/g" -e "s/endTime=\"2017-07-19T13:00:01+03:00\"/endTime=\"${FILE_endTime}\"/g" -e "s/jobId=\"PRIMARY15MIN\"/jobId=\"PRIMARY1440MIN\"/g" -e "s/duration=\"PT900S\"/duration=\"PT86400S\"/g" $source > $target
    fi
else
    ln -s $source $target &
    rc=$?
    if [ $rc -ne 0 ] ; then
        if [ $rc -eq 2 ] ; then
            log_it "INFO: File exists: $target"
        else
            log_it "ERROR: Failed to link $target"
        fi
    fi
fi
