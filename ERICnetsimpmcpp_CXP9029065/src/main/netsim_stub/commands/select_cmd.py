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
# Purpose       :  The purpose of this script to replicate the netsim command ".select"
# Jira No       :  EQEV-44613
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2912255
# Description   :  Created the script as a part of the netsim stub
# Date          :  14/11/2017
# Last Modified :  sardana.bhav@tcs.com
####################################################

import sys
import os
import ConfigParser
from string_constants import *

config = ConfigParser.RawConfigParser()

Selection = sys.argv[1]
netsimdir_sims = os.listdir(NETSIM_DIR)

def ImportSelection(Selection):
    config.read(ENVIRONMENT)
    config.set('Select', 'SELECT_ARG', Selection)
    with open(ENVIRONMENT, 'wb') as env:
        config.write(env)

def main():
    print(">> .select " + Selection)
    ImportSelection(Selection)
    print("OK")

if __name__ == '__main__': main()
