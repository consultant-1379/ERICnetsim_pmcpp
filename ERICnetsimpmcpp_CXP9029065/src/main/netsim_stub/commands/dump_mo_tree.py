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
# Purpose       :  The purpose of this script to replicate the netsim command ".dump_mo_tree.py"
# Jira No       :  EQEV-44613
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2912255
# Description   :  Created the script as a part of the netsim stub
# Date          :  13/11/2017
# Last Modified :  sardana.bhav@tcs.com
####################################################

import sys
import os
import ConfigParser
import xml.etree.ElementTree as ET
from string_constants import *

config = ConfigParser.RawConfigParser()

cmd = sys.argv[1:]
site_cmd = "dumpmotree:moid=\"1\",printattrs, scope=0, includeattrs=\"site\";"

with open(USER_INPUT_XML, "r") as user_input_file:
        user_input_string = user_input_file.read()

CPP_NE_TYPES = ["M-MGW", "ERBS", "RBS", "RNC"]

config.read(ENVIRONMENT)
sim_name = config.get('Open', 'sim_name')

user_input = ET.fromstring(user_input_string)
node_type = user_input.findall(".//*[@name='%s']/node_type" % sim_name)[0].text
stats_dir = user_input.findall(".//*[@name='%s']/stats_dir" % sim_name)[0].text
trace_dir = user_input.findall(".//*[@name='%s']/trace_dir" % sim_name)[0].text
#site_loc = user_input.findall(".//*[@name='%s']/site_loc" % sim_name)[0].text

list1 = ["PmEventM=", "FilePullCapabilities"]
data_dir = "fileLocation"
if ' '.join(cmd) == site_cmd:
    print("site_loc : Athlone" )
else:
    if cmd.__contains__(list1[0]) and cmd.__contains__(list1[1]):
        data_dir = "outputDirectory"
    elif node_type in CPP_NE_TYPES:
        data_dir = "performanceDataPath"
    else:
        data_dir = "fileLocation"

    if  data_dir == "performanceDataPath" or data_dir == "fileLocation":
        print(data_dir + "=" + stats_dir)
    else:
        print(data_dir + "=" + trace_dir)

