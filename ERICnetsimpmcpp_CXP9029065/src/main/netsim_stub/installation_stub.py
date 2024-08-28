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
# Purpose       :  The purpose of this script to install netsim_sub
# Jira No       :  EQEV-45853
# Gerrit Link   :
# Description   :  Created the script as a part of the netsim stub
# Date          :  15/12/2017
# Last Modified :  sudheep.mandava@tcs.com
####################################################

import sys
import os
import crypt
import subprocess
import xml.etree.ElementTree as ET
from distutils.dir_util import copy_tree
from datetime import datetime
import shutil
import logging
import pwd
import zipfile
sys.path.append('/netsim_users/netsim_stub/commands/');
from string_constants import *

BASE_DIRECTORIES = [ "/netsim/genstats/logs/rollout_console/" , "/netsim/netsimdir/" , "/netsim/netsim_dbdir/simdir/netsim/netsimdir/" , "/netsim/genstats/tmp/" , "/netsim/inst/zzzuserinstallation/mim_files/" , "/netsim/inst/zzzuserinstallation/ecim_pm_mibs/" , "/netsim/bin/" , "/netsim/etc/" , "/netsim/inst/platf_indep_java/linux64/jre/bin/", "/eniq/", "/ossrc/data/pms/segment1/", "/netsim/etc/csv/"]

logging.basicConfig(filename="/var/tmp/installation.log", level=logging.INFO)

#condition for file override from job
USER_INPUT_XML = ""


def create_directories(directories, root):
    getCurrentLog("Creating directories for OSS_Simulator" ,'INFO')
    for create_dir in directories:
        os.system("mkdir -p " + create_dir)
    for Simulation in root.findall('Simulation'):
        os.system("mkdir -p " + NETSIM_DIR + Simulation.get('name'))
        os.system("touch " + NETSIM_DIR + Simulation.get('name') + "/simulation.netsimdb")
        nodes_ON = Simulation.find('nodes_ON').text
        node_list = nodes_ON.split(":")
        stats_dir = Simulation.find('stats_dir').text
        for node in node_list:
            os.system("mkdir -p " + DB_DIR + Simulation.get('name') + "/" + node + "/fs/" + stats_dir)


def add_user():
    getCurrentLog("Adding" + USER_NAME + "as a user" ,'INFO')
    password = "netsim"
    encPass = crypt.crypt(password,"22")
    os.system("groupadd -f netsim")
    os.system("useradd -d /netsim -p " + encPass + " netsim")

def pre_execution():
    if os.path.exists(BASE_DIR):
        getCurrentLog("Deleting the older directories" ,'INFO')
        os.system("rm -rf " + BASE_DIR + " /ossrc/")
    if os.path.exists(TMPFS_DIR):
        getCurrentLog("Deleting the existing output directories" ,'INFO')
        os.system("rm -rf " + TMPFS_DIR)

def extract_mom():
    getCurrentLog("Extracting MOM Files" ,'INFO')
    os.chdir(INST_DIR + "zzzuserinstallation/")
    zip = zipfile.ZipFile('/tmp/NodeMOMs/mim_files.zip')
    zip.extractall()
    os.chdir(INST_DIR + "zzzuserinstallation/")
    zip = zipfile.ZipFile('/tmp/NodeMOMs/ecim_pm_mibs.zip')
    zip.extractall()

def output_directory(root):
    for Simulation in root.findall('Simulation'):
        nodes_ON = Simulation.find('nodes_ON').text
        node_list = nodes_ON.split(":")
        stats_dir = Simulation.find('stats_dir').text
        sim_name = Simulation.get('name')
        for node in node_list:
            if 'SGSN' not in sim_name:
                if 'LTE' in sim_name or 'RNC' in sim_name:
                    cmd = "mkdir -p " + TMPFS_DIR + sim_name.split("-")[-1] + "/" + node + stats_dir
                    p = subprocess.Popen(cmd.split())
                else:
                    cmd = "mkdir -p " + TMPFS_DIR + sim_name + "/" + node + stats_dir
                    p = subprocess.Popen(cmd.split())

def copy_scripts(deployment, USER_INPUT_XML):
    getCurrentLog ("Copying files into required directories" ,'INFO')
    copy_tree(WORKING_DIR + "/bin/", BIN_DIR)
    copy_tree(WORKING_DIR + "/commands/" , BIN_DIR)
    copy_tree(WORKING_DIR + "/etc/" , ETC_DIR)
    copy_tree(WORKING_DIR + "/shell/" , INST_DIR)
    shutil.copy2(USER_INPUT_XML , ETC_DIR)
    os.system("cp /netsim_users/pms/bin/eniq_stats_cfg " + BIN_DIR + "eniq_stats_cfg.py")
    if deployment == "NRM":
        os.rename(USER_INPUT_XML , ETC_DIR + "user_input.xml")

def changing_permissions():
    getCurrentLog ("Changing permissions of from root to netsim" ,'INFO')
    os.system("chown -R netsim:netsim " + BASE_DIR + " " + TMPFS_DIR + " /ossrc/" + " /eniq/")
    os.system("chmod -R 755 " + BASE_DIR + " " + TMPFS_DIR )
    os.system("chmod -R 777 /ossrc/")

def cleanup():
    getCurrentLog("Cleaning up the Directories" , "INFO")
    os.remove('/tmp/NodeMOMs.zip')
    shutil.rmtree('/tmp/NodeMOMs')

def getCurrentLog(message,type):
    curDateTime = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    if type == 'INFO':
        logging.info(curDateTime + message)
        print 'INFO: ' + curDateTime + " " + message
    elif type == 'WARN':
        logging.warning(curDateTime + message)
        print 'WARNING: ' + curDateTime + " " + message
    elif type == 'ERROR':
        logging.warning(curDateTime + message)
        print 'ERROR: ' + curDateTime + " " + message


def main(argv):
    deployment = argv[0]
    network_xml_location = argv[1]
    if deployment == "NSS":
        if not network_xml_location:
            getCurrentLog("User defined network configuration not present. Exiting installation",'ERROR')
            sys.exit(1)
        else:
            USER_INPUT_XML = network_xml_location + "user_input.xml"
    elif deployment == "NRM":
        USER_INPUT_XML = "/tmp/NodeMOMs/user_input1.8K.xml"
    else:
        getCurrentLog("Deployment not defined yet. taking default configuration user_input_1.8K.xml",'INFO')
        USER_INPUT_XML = "/tmp/NodeMOMs/user_input1.8K.xml"
    if USER_NAME in [entry.pw_name for entry in pwd.getpwall()]:
        getCurrentLog(" User " + USER_NAME + " already exists",'INFO')
    else:
        add_user()
    os.chdir('/tmp')
    zip = zipfile.ZipFile('/tmp/NodeMOMs.zip')
    zip.extractall()
    os.system("bash " + WORKING_DIR + "/bin/pre_rollout.sh")
    pre_execution()
    user_input = ET.parse(USER_INPUT_XML)
    root = user_input.getroot()
    create_directories(BASE_DIRECTORIES, root)
    os.system("/etc/init.d/nfs restart > /dev/null")
    copy_scripts(deployment, USER_INPUT_XML)
    output_directory(root)
    extract_mom()
    changing_permissions()
    subprocess.call(["ln" , "-s" , "/usr/bin/java" , JAVA_LINK])
    getCurrentLog("Generating EutranData for LTE Nodes" , 'INFO')
    os.system("su - netsim -c \"python " + GENERATE_EUTRANDATA + "\"")
    os.system("su - netsim -c \"python " + UPDATE_STATS_CFG + "\"")
    os.system("echo '.show started' | /netsim/inst/netsim_pipe > /tmp/.showstartednodes.txt")
    os.system("echo '.show started' | /netsim/inst/netsim_pipe > /tmp/showstartednodes.txt")
    cleanup()

if __name__ == "__main__":
    main(sys.argv[1:])
