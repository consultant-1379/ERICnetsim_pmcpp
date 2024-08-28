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
# Purpose       :  The purpose of this script to maintain common string constants
#                  for netsim stub 
# Jira No       :  EQEV-44613
# Gerrit Link   :
# Description   :  added GENSTATS_SCRIPT variable
# Date          :  29/11/2017
# Last Modified :  mahesh.lambud@tcs.com
####################################################

WORKING_DIR = "/netsim_users/netsim_stub"
BASE_DIR = "/netsim/"
BIN_DIR = BASE_DIR + "bin/"
ETC_DIR = BASE_DIR + "etc/"
LIB_DIR = BASE_DIR + "lib/"
INST_DIR = BASE_DIR + "inst/"
NETSIM_DIR = BASE_DIR + "netsimdir/"
DB_DIR = BASE_DIR + "netsim_dbdir/simdir/netsim/netsimdir/"
ENVIRONMENT = ETC_DIR + "environment"
USER_INPUT_XML = ETC_DIR + "user_input.xml"
NETYPES = ETC_DIR + "netypes.txt"
LINK_DIR = "/ossrc/data/pmMediation/pmData"
MOUNT_PATH = "/eniq/data/importdata/"

ENIQ_STATS_CFG = "/netsim_users/pms/bin/eniq_stats_cfg"
EUTRANCELLDATAFILE = "EUtranCellData.txt"
TOPOLOGYFILE = "TopologyData.txt"
MO_CSV_FILE = "/netsim_users/reference_files/OSS/mo_cfg_oss.csv"

GENERATE_EUTRANDATA = BIN_DIR + "generateEutranDataFile.py"
TMPFS_DIR = "/pms_tmpfs/"
JAVA_LINK = "/netsim/inst/platf_indep_java/linux64/jre/bin/java"
USER_NAME = "netsim"
UPDATE_STATS_CFG = BIN_DIR + "update_stats_cfg.py"
GENSTATS_SCRIPT = "/netsim_users/pms/bin/genStats"
