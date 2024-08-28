#!/usr/bin/python
###############################################################################
# COPYRIGHT Ericsson 2016
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###############################################################################
"""
removes obsolete simulations from /netsim/netsim_dbdir/simdir/netsim/ which are
the result of incorrect simulation deletion
"""
import os

db_simulations=[]
db_simulations=os.listdir("/netsim/netsim_dbdir/simdir/netsim/netsimdir/")

for simulation in db_simulations:
    if not os.path.isdir("/netsim/netsimdir/" + simulation):
        os.system("/netsim_users/pms/bin/unmountSimulation.exp " + simulation)
        os.system("rm -rf /netsim/netsim_dbdir/simdir/netsim/netsimdir/" + simulation)