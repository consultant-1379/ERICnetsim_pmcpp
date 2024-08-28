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
# Purpose       :  The purpose of this script to replicate the netsim command ".open"
# Jira No       :  EQEV-44613
# Gerrit Link   :
# Description   :  Created the script as a part of the netsim stub
# Date          :  13/11/2017
# Last Modified :
####################################################

import sys
import os
import ConfigParser
from string_constants import *

config = ConfigParser.ConfigParser()

SimulationName = sys.argv[1]
netsimdir_sims = os.listdir(NETSIM_DIR)

def ValidateSimulation():
    if SimulationName in netsimdir_sims:
        return True
    else:
        return False


def ImportSimulationName():
    config.read(ENVIRONMENT)
    config.set('Open', 'SIM_NAME', SimulationName)
    with open(ENVIRONMENT, 'wb') as env:
        config.write(env)

def main():
    if ValidateSimulation():
        print(">> .open " + SimulationName)
        ImportSimulationName()
        print("OK")
    else:
        print("Not a valid simulation")

if __name__ == '__main__': main()
