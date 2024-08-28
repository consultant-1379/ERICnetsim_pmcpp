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
# Version no    :  NSS 17.12
# Purpose       :  Script to create /netsim_users/pms/etc/sgsn_mme_ebs_ref_fileset.cfg
# Jira No       :  NSS-13277
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2514941/
# Description   :  Script to create /netsim_users/pms/etc/sgsn_mme_ebs_ref_fileset.cfg
# Date          :  11/07/2017
# Last Modified :  arwa.nawab@tcs.com
####################################################


import os
import re
import socket
server_name = socket.gethostname()
import TemplateGenerator as genTemplates
import DataAndStringConstants as Constants

MME_REF_CFG="/netsim_users/pms/etc/sgsn_mme_ebs_ref_fileset.cfg"

def get_node_names(sim_dir):
    return [node for node in os.listdir(sim_dir)
            if os.path.isdir(os.path.join(sim_dir, node))]

def main():

    sim_data_list = genTemplates.get_sim_data()
    file = open(MME_REF_CFG,'w')
    for sim in sim_data_list:
        sim_data = sim.split();
        sim_name = sim_data[1]
        if "SGSN" in sim_name:
            print "INFO : Creating " + MME_REF_CFG + " for sim : " + sim_name
            for node_name in get_node_names(Constants.NETSIM_DBDIR + sim_name):
                file.write(sim_name+":"+node_name+":/real_data/HSTNTX01LT9\n")
    file.close()

if __name__ == "__main__": main()
