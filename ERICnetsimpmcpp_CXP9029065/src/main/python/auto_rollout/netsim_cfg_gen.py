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
# Version no    :  NSS 17.14
# Purpose       :  Script to create netsim_cfg
# Jira No       :  NSS-12969 
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2565085/
# Description   :  Adding chnages for end to end roll out support of EDE-Stats.
# Date          :  08/11/2017
# Last Modified :  soumya.gupta2@tcs.com
####################################################

'''
netsim_cfg_gen is a script to generate Genstats configuration file.

@author:     eaefhiq

@copyright:  2016 Ericsson. All rights reserved.

@license:    Ericsson

@contact:    liang.e.zhang@ericsson.com
'''
from mako.template import Template


def create_netsim_cfg(server_name, nssRelease, simulations, mmes, pm_file_paths, playback_sim_list, mytemplate, edeStatsCheck, counterVolume, oss_enabled):

    mytemplate = Template(filename=mytemplate)
    with open(server_name, 'w+') as f:
        f.write(mytemplate.render(release=nssRelease, servers=server_name, server=server_name.replace(
            "-", "_"), simulation_list=simulations, mme_list=mmes, pm_file_locations=pm_file_paths, playback_sim_list=playback_sim_list, edeStatsCheck=edeStatsCheck, counterVolume=counterVolume, oss_enabled=oss_enabled))


