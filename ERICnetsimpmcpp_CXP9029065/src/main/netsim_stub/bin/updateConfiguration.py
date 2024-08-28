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
# Version no    :  NSS 18.1
# Purpose       :  The script is responsible for responsible for configuring FDN of PM Files
# Jira No       :  EQEV-45853
# Description   :  Handling for filename for OSS Simulator.
# Date          :  14/11/2017
# Last Modified :  mahesh.lambud@tcs.com
####################################################

'''
Usage:
1)python updateConfiguration.py update_FDN
    To update the FDN in PM Files
2)python updateConfiguration.py cell_realtion
    To upate the cell realtions in PM Files
'''

import os
import sys
import getopt
import socket

hostname = socket.gethostname()

def main(argv):
    if not argv:
        print " Usage:    /netsim/bin/updateConfiguration.py <--config update_FDN|cell_relation|ALL>"
        sys.exit(1)
    try:
        options, remainder = getopt.getopt(argv, "c:", ['config='])
    except getopt.GetoptError as err:
        print('ERROR:', err)
        sys.exit(1)
    config =''
    for opt, arg in options:
        if opt == '--config':
            config = arg
    os.system("rm -rf /netsim/netsimdir/*/SimNetRevision/TopologyData.txt")
    os.system("rm -rf /netsim/netsimdir/*/SimNetRevision/EUtranCellData.txt")
    if config == "update_FDN":
        os.system("cp -f /netsim_users/pms/bin/eniq_stats_cfg /netsim/bin/eniq_stats_cfg.py")
    elif config == "cell_relation":
        os.system("rm -rf /pms_tmpfs/xml_step/*")
    elif config == "update_ROP":
        os.system("cp -f /netsim/netsim_cfg /tmp/" + hostname)
        os.system("rm -rf /pms_tmpfs/xml_step/*")
        os.system("/netsim_users/pms/bin/pm_statistcs.sh -c /netsim/netsim_cfg -b \"False\"")
        sys.exit(0)
    elif config == "ALL":
        os.system("cp -f /netsim_users/pms/bin/eniq_stats_cfg /netsim/bin/eniq_stats_cfg.py")
        os.system("rm -rf /pms_tmpfs/xml_step/*") 
    else:
        print " Usage:    /netsim/bin/updateConfiguration.py <--config update_FDN or cell_relation>"
        sys.exit(1)
    os.system("python /netsim/bin/generateEutranDataFile.py")
    os.system("python /netsim_users/pms/bin/GetEutranData.py")
    os.system("python /netsim_users/auto_deploy/bin/TemplateGenerator.py")


if __name__ == "__main__":
    main(sys.argv[1:])

