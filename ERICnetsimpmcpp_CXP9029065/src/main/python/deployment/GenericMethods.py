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
# Version no    :  NSS 17.10
# Purpose       :  This script is responsible to maintain all CONSTATS variables used in GenStats.
# Jira No       :  NSS-10375
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2410090/
# Description   :  Addition of variable of PMS_ETC_DIR
# Date          :  06/05/2017
# Last Modified :  abhishek.mandlewala@tcs.com
####################################################

import sys
from confGenerator import getCurrentDateTime

def exit_logs(number):
    print getCurrentDateTime() + ' INFO: Exiting process.'
    sys.exit(number)
