#!/usr/bin/python

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
# Version no    :  OSS
# Purpose       :  The purpose of this script to generate PM Files for required time at a same time
# Jira No       :  EQEV-45853
# Description   :  Created the script as a part of the netsim stub
# Date          :  15/12/2017
# Last Modified :  mahesh.lambud@tcs.com
####################################################

import os
import sys
import datetime
import getopt

sys.path.append('/netsim/bin/')
from string_constants import *

def main(argv):
    try:
        options, remainder = getopt.getopt(argv, "s:t:", ['start_time=', 'end_time='])
    except getopt.GetoptError as err:
        print('ERROR:', err)
        sys.exit(1)
    rop_period = ''
    start_time = ''
    end_time = ''
    stats_workload_list = ''
    for opt, arg in options:
        if opt == '--start_time':
            start_time = arg
        elif opt == '--end_time':
            end_time = arg

    for ch in ['/',':',' ']:
        start_time = start_time.replace(ch, "")
        end_time = end_time.replace(ch, "")

    if len(start_time) == 8:
        start_time = start_time + "0000"
    elif len(start_time) != 12:
        print "Enter Start Time in format YYYY/MM/DD hh:mm "
        sys.exit(1)

    if len(end_time) == 8:
        end_time = end_time + "2359"
    elif len(end_time) != 12:
        print "Enter End Time in format YYYY/MM/DD hh:mm "
        sys.exit(1)

    start_time = datetime.datetime(int(start_time[:4]),int(start_time[4:6]),int(start_time[6:8]),int(start_time[8:10]),int(start_time[10:12]))
    end_time = datetime.datetime(int(end_time[:4]),int(end_time[4:6]),int(end_time[6:8]),int(end_time[8:10]),int(end_time[10:12]))
    with open('/netsim/netsim_cfg', 'r') as cfg:
        for line in cfg:
            if "STATS_WORKLOAD_LIST" in line:
                stats_workload_list = line.split('\"')[1]
                break
    stats_workload_list = stats_workload_list.split(" ")
    for stats_workload in stats_workload_list:
        rop_period = stats_workload.split(":")[0]
        ne_types = stats_workload.split(":")[1]
        rop_start_time = start_time
        rop_end_time = rop_start_time + datetime.timedelta(minutes = int(rop_period))
        while(rop_end_time <= end_time):
            st = rop_start_time.strftime("%Y%m%d%H%M")
            et = rop_end_time.strftime("%Y%m%d%H%M")
            if ne_types == 'ALL':
                os.system(GENSTATS_SCRIPT + " -r " + rop_period + " -t " + st + " -e " + et +" -b True")
            else:
                ne_types = ne_types.replace(',', ' ')
                os.system(GENSTATS_SCRIPT + " -r " + rop_period + " -l " + ne_types + " -t " + st + " -e " + et +" -b True")
            rop_start_time += datetime.timedelta(minutes = int(rop_period))
            rop_end_time += datetime.timedelta(minutes = int(rop_period))

if __name__ == "__main__":
    main(sys.argv[1:])

