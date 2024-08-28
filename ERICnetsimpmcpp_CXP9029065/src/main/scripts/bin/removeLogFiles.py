#!/usr/bin/python
###############################################################################
# COPYRIGHT Ericsson 2017
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###############################################################################

###############################################################################
# Version no    :  NSS 17.15
# Purpose       :  This Script removes and archive all logs from /netsim_users/pms/logs/.
# Jira No       :  NSS-14661
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2698032
# Description   :  Genstats- PM for Fronthaul 6080 R17
# Date          :  10/03/2017
# Last Modified :  r.t2@tcs.com
###############################################################################
'''
This script removes all logs except scanners.log, limitbw.log and rmFiles.log
from /netsim_users/pms/logs. The script is invoked from system crontab.
'''
import os
import re
import sys
import subprocess

class value:
    def __init__(self):
        self.LOG_DIRECTORY = "/netsim_users/pms/logs/"
        self.NOT_TO_BE_MANAGED = ["scanners.log","limitbw.log","rmFiles.log"]
        self.LOGROTATE_CONF = "/etc/logrotate.d/genstats"
        self.log_list = os.listdir(self.LOG_DIRECTORY)
        self.manage_logs = [x for x in self.log_list if x not in self.NOT_TO_BE_MANAGED]
        self.bashCommand = "logrotate -d /etc/logrotate.d/genstats"
        self.data = """ {
        olddir /netsim_users/pms/logs/archived
        compress
        rotate 20
        daily
        create 644 netsim netsim
        missingok
        notifempty
        }\n"""
        

def create_conf_file():
    if os.path.isdir("/netsim_users/pms/logs/archived"):
        pass
    else:
        os.mkdir("/netsim_users/pms/logs/archived")
    x = value()
    logrotate_conf = open(x.LOGROTATE_CONF, "w+")
    logrotate_conf.write("# logrotate configuration file for genstats pms logs\n")
    log_paths = create_log_files_path(x.LOG_DIRECTORY, x.manage_logs)
    for logs in log_paths:
        logrotate_conf.write("%s " % logs)
    logrotate_conf.write(x.data)
    logrotate_conf.close
    
def create_log_files_path(LOG_DIRECTORY, manage_logs):
    log_paths = []
    for logfile in manage_logs:
        log_file_path = LOG_DIRECTORY + logfile
        if '.logs' in log_file_path:
            os.system("rm -rf %s" %(log_file_path))
        if os.path.isfile(log_file_path):
            log_paths.append(log_file_path)
    return log_paths




def log_file_entry(log_file_path):
    z = value()
    logrotate_conf = open(z.LOGROTATE_CONF, "r")
    for line in logrotate_conf:
        if re.search(log_file_path, line):
                return True
                break
        else:
                    continue
        return False

def verify_file_content():
    y = value()
    log_paths = create_log_files_path(y.LOG_DIRECTORY, y.manage_logs)
    for logs in log_paths:
        if os.path.isfile(logs) and log_file_entry(logs):
            continue
        else:
            print "WARN: The log file name is incorrect or its entry is not in conf file"
            sys.exit(1)
    try:
        process = subprocess.Popen(y.bashCommand.split(), stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=False)
        out, err = process.communicate()
        if ("error" or "ERROR") in (err or out):
            sys.exit(1)
    except (ValueError, OSError):
        print "conf file is incorrect"
        sys.exit(1)
    sys.exit(0)

if not os.system("ls /netsim_users/pms/logs/ | grep '.log' > /dev/null"):
    if os.path.isfile('/etc/logrotate.d/genstats'):
        print "INFO: Deleting Logrotate conf file"
        os.system("rm -rf /etc/logrotate.d/genstats")
    create_conf_file()
    os.system("/usr/sbin/logrotate --force /etc/logrotate.d/genstats")
else:
    print "WARN: No log files in log dir."

