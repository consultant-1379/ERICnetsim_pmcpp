#!/usr/local/bin/python2.7
# encoding: utf-8

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
# Version no    :  NSS 17.15
# Purpose       :  Script verifies if Genstats is configured correctly as per the netsim_cfg. Also, checks if there are no ACTIVE Scanners present on Netsim end for any node.
# Jira No       :  NSS-15546
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2906126/
# Description   :  Handling for MSC nodes support.
# Date          :  14/11/2017
# Last Modified :  r.t2@tcs.com
####################################################

'''
genstats_checking -- shortdesc

genstats_checking is a description

It defines classes_and_methods

@author:     eaefhiq

@copyright:  2016 ericsson. All rights reserved.

@license:    ericsson

@contact:    liang.e.zhang@ericsson.com
@deffield    updated: Updated
'''

import sys
import os

from argparse import ArgumentParser
from argparse import RawDescriptionHelpFormatter
from GenstatsSimPmVerifier import GenstatsSimPmVerifier, logging, subprocess
from GenstatsLteSimPmVerifier import GenstatsLteSimPmVerifier
from GenstatsSgsnSimPmVerifier import GenstatsSgsnSimPmVerifier
from GenstatsWranSimPmVerifier import GenstatsWranSimPmVerifier
from GenstatsSimPmStatsVerifier import GenstatsSimPmStatsVerifier
import subprocess
from subprocess import PIPE, Popen

__all__ = []
__version__ = 0.1
__date__ = '2016-04-12'
__updated__ = '2016-04-12'

DEBUG = 0
TESTRUN = 0
PROFILE = 0

LOG_FILE = '/netsim/genstats/logs/genstatsQA.log'
NETSIM_DBDIR = '/netsim/netsim_dbdir/simdir/netsim/netsimdir/'
TMPFS = '/pms_tmpfs/'
GENSTATS_LOG_DIR = '/netsim_users/pms/logs/'
GENSTATS_CONSOLELOGS_DIR='/netsim/genstats/logs/rollout_console/'
GENSTATS_CONSOLELOGS_FABTASK='/tmp/genstats.log'
NETSIM_CFG = '/netsim/netsim_cfg'
SIM_DATA_FILE = '/netsim/genstats/tmp/sim_data.txt'
STATS_ONLY_NE_TYPES = [ "CSCF", "EPG-SSR", "EPG-EVR", "M-MGW", "MTAS", "SBG", "SPITFIRE", "TCU03", "TCU04", "MRSV", "HSS-FE", "IPWORKS", "MRFV", "UPG", "WCG", "DSC", "VPP", "VRC", "RNNODE", "WMG", "RBS", "STN", "EME", "VTFRADIONODE", "5GRADIONODE", "R6274", "R6672", "R6675", "R6371", "R6471-1", "R6471-2", "VRM" ]
startedNodesFile = "/tmp/showstartednodes.txt"
PLAYBACK_ONLY_NE_TYPES = ["FrontHaul"]
NON_EVENT_FIVEG_NODES = [ "VPP", "VRC", "RNNODE", "5GRADIONODE", "VRM" ]
TSP_ONLY_NE_TYPES = [ "SAPC-TSP", "MTAS-TSP", "HSS-FE-TSP", "CSCF-TSP" ]
EDE_STATS_SIM = ["LTE", "RNC"]
EDE_STATS_RADIO= [ "VPP", "VRC", "RNNODE", "5GRADIONODE", "VTFRADIONODE", "VRM" ]
class CLIError(Exception):
    '''Generic exception to raise and log different fatal errors.'''

    def __init__(self, msg):
        super(CLIError).__init__(type(self))
        self.msg = "E: %s" % msg

    def __str__(self):
        return self.msg

    def __unicode__(self):
        return self.msg


def run_shell_command(command):
    command_output = Popen(command, stdout=PIPE, shell=True).communicate()[0]
    return command_output

def check_stats_files(sims, lte_uetrace='', playbacksimlist='', edeStatsCheck=False):
    from multiprocessing import Process
    process_pool = []
    if os.path.isfile(startedNodesFile):
        for sim in sims:
                if sim in open(startedNodesFile).read():
                    ''''check nodes in the simulation'''
                    p = Process(target=check_stats_each_node, args=(sim, lte_uetrace, playbacksimlist,edeStatsCheck,))
                    process_pool.append(p)
                    p.start()
    [p.join() for p in process_pool]


def check_bandwith_limiting(set_bandwith_limiting="OFF"):
    p = subprocess.Popen(["sudo", "-S", "/netsim_users/pms/bin/limitbw",
                          "-n", "-s"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    result = len(p.communicate("shroot\n")[0].strip().split("\n"))
    if set_bandwith_limiting == 'OFF':
        logging.info("BANDWIDTH LIMITING is OFF")
    else:
        logging.info("BANDWIDTH LIMITING is ON. Bandwidth will be set as per the values mentioned in netsim_cfg")


def check_logfile(logfile):
    with open(logfile) as txtfile:
        for line in reversed(txtfile.readlines()):
            if 'failed' in line.lower() and 'file exists' not in line.lower() and 'failed to create symbolic link' in line.lower() or 'error' in line.lower():
                return False
    return True


def verify_logfile(isVapp=False):
    result = []
    logfiles = os.listdir(GENSTATS_LOG_DIR)
    logfiles = filter(None,logfiles)
    consolelogfiles = os.listdir(GENSTATS_CONSOLELOGS_DIR)
    consolelogfiles = filter(None,consolelogfiles)
    for logfile in logfiles:
        if 'genstats' in logfile.lower() or 'lte_rec' in logfile.lower() or 'gengpeh' in logfile.lower() or 'genrbsgpeh' in logfile.lower() or 'playbacker' in logfile.lower() or 'limitbw' in logfile.lower() or 'scanners' in logfile.lower():
            if not check_logfile(GENSTATS_LOG_DIR + logfile):
                result.append(GENSTATS_LOG_DIR + logfile)
    for logfile in consolelogfiles:
        if 'genstats' in logfile.lower():
            if not check_logfile(GENSTATS_CONSOLELOGS_DIR + logfile):
                result.append(GENSTATS_CONSOLELOGS_DIR + logfile)
    if os.path.isfile(GENSTATS_CONSOLELOGS_FABTASK):
        if not check_logfile(GENSTATS_CONSOLELOGS_FABTASK):
            result.append(GENSTATS_CONSOLELOGS_FABTASK)
    return result


def check_stats_each_node(simname, lte_uetrace='', playbacksimlist='', edeStatsCheck=False):
    pm_data = "/c/pm_data/"
    bsc_ready_path = "/data_transfer/destinations/CDHDEFAULT/Ready"
    msc_ready_path = "/apfs/data_transfer/destinations/CDHDEFAULT/Ready"
    tsp_opt_path = "/opt/telorb/axe/tsp/NM/PMF/reporterLogs"

    for sim_info in open(SIM_DATA_FILE):
        if simname in sim_info:
            sim_info = sim_info.split()
            node_type = sim_info[5]
            stats_dir = sim_info[9]
            trace_dir = sim_info[11]
    if edeStatsCheck:
        for ede_sim in EDE_STATS_SIM:
            if ede_sim in simname.upper() and node_type.upper() not in EDE_STATS_RADIO:
                return
            elif "rbs" in simname.lower() and node_type.lower() == "rbs":
                return
    x = GenstatsSimPmVerifier(TMPFS, simname, pm_data)
    if 'sgsn' in simname.lower():
        x = GenstatsSgsnSimPmVerifier(NETSIM_DBDIR, simname, "/fs" + pm_data)
    elif 'lte' in simname.lower() and node_type.upper() not in NON_EVENT_FIVEG_NODES:
        x = GenstatsLteSimPmVerifier(TMPFS, simname, stats_dir, trace_dir, lte_uetrace, node_type)
    elif 'rnc' in simname.lower():
        x = GenstatsWranSimPmVerifier(TMPFS, simname, pm_data)
    elif playbacksimlist is not None and simname in playbacksimlist:
        for ne_type in PLAYBACK_ONLY_NE_TYPES:
            if ne_type.upper() in simname.upper():
                pm_path = run_shell_command("grep  "+ ne_type + "_PM_FileLocation " + NETSIM_CFG).strip()
                if pm_path:
                    pm_data = pm_path.split("=")[-1].replace("\"", "")
        if any(NE in simname.upper() for NE in TSP_ONLY_NE_TYPES):
            x = GenstatsSimPmStatsVerifier(NETSIM_DBDIR, simname,"/fs" + tsp_opt_path)
        elif 'fs/' in pm_data:
            x = GenstatsSimPmStatsVerifier(NETSIM_DBDIR, simname,"/" + pm_data)
        else:
            x = GenstatsSimPmStatsVerifier(NETSIM_DBDIR, simname, "/fs" + pm_data)
    elif 'bsc' in simname.lower():
        x = GenstatsSimPmStatsVerifier(NETSIM_DBDIR, simname, "/apfs" + bsc_ready_path)
    elif 'msc' in simname.lower():
        x = GenstatsSimPmStatsVerifier(NETSIM_DBDIR, simname, msc_ready_path)
    elif node_type.upper() in STATS_ONLY_NE_TYPES:
        x = GenstatsSimPmStatsVerifier(TMPFS, simname, stats_dir)
    x.verify()


def check_crontab(expected_stats_work_load_list, expected_rec_work_load_list, expected_gpeh_work_load_list=[], expected_rbs_gpeh_work_load_list=[], wran=False, gpeh=False, rbs_gpeh=False, dpltype="NSS"):
    p = subprocess.Popen(["crontab", "-l"], stdout=subprocess.PIPE)
    (output, error) = p.communicate()
    p.stdout.close()
    stats_work_load_list = [line.split()[7] for line in output.splitlines(
    ) if "/netsim_users/pms/bin/genStats" in line and not line.startswith("#")]
    rec_work_load_list = [line.split()[7] for line in output.splitlines(
    ) if "/netsim_users/pms/bin/lte_rec.sh" in line and not line.startswith("#")]
    playback_work_load_list = [line.split()[7] for line in output.splitlines(
    ) if "/netsim_users/pms/bin/startPlaybacker.sh" in line and not line.startswith("#")]
    if dpltype == "NSS":
        if not (set(expected_stats_work_load_list) == set(stats_work_load_list) and set(rec_work_load_list) == set(expected_rec_work_load_list) and set(expected_stats_work_load_list) == set(playback_work_load_list)):
            logging.error(
                "The ROP setup is different between Crontab and /netsim/netsim_cfg.")
            os.system('echo  "ERROR crontab entry misconfiguration " >> ' + LOG_FILE)
    else:
        if not (set(expected_stats_work_load_list) == set(stats_work_load_list) and set(expected_stats_work_load_list) == set(playback_work_load_list)):
            logging.error(
                "The ROP setup is different between Crontab and /netsim/netsim_cfg.")
            os.system('echo  "ERROR crontab entry misconfiguration " >> ' + LOG_FILE)
    if wran:
        wran_rec_work_load_list = [line.split()[9] for line in output.splitlines(
        ) if "/netsim_users/pms/bin/wran_rec.sh" in line and not line.startswith("#")]
        if not (set(wran_rec_work_load_list) == set(expected_rec_work_load_list)):
            logging.error(
                "The ROP setup for wran is different between Crontab and /netsim/netsim_cfg.")
            os.system('echo  "ERROR crontab entry misconfiguration " >> ' + LOG_FILE)
    if gpeh:
        gpeh_work_load_list = [line.split()[9] for line in output.splitlines(
        ) if "/netsim_users/pms/bin/genGPEH" in line and not line.startswith("#")]
        if not (set(gpeh_work_load_list) == set(expected_gpeh_work_load_list)):
            logging.error(
                "The ROP setup for gpeh is different between Crontab and /netsim/netsim_cfg.")
            os.system('echo  "ERROR crontab entry misconfiguration " >> ' + LOG_FILE)
    if rbs_gpeh:
        rbs_gpeh_work_load_list = [line.split()[7] for line in output.splitlines(
        ) if "/netsim_users/pms/bin/genRbsGpeh" in line and not line.startswith("#")]
        if not (set(rbs_gpeh_work_load_list) == set(expected_rbs_gpeh_work_load_list)):
            logging.error(
                "The ROP setup for rbs gpeh is different between Crontab and /netsim/netsim_cfg.")
            os.system('echo  "ERROR crontab entry misconfiguration " >> ' + LOG_FILE)

def is_nodetype_in_simlist(nodeType, simlist):
    if os.path.isfile(startedNodesFile):
        for sim in simlist:
            if sim in open(startedNodesFile).read():
                if nodeType in sim.lower():
                    if not check_for_wcdma_pico_node(sim):
                        if int(sim.replace('RNC','')) < 21:
                            return True
    return False


def check_for_wcdma_pico_node(sim):
    sim_name = ''
    node_type = ''
    for sim_info in open(SIM_DATA_FILE):
        sim_name = sim_info.split()[1]
        if 'RNC' in sim_name:
           sim_name = sim_name.split('-')[-1]
           node_type = sim_info.split()[5]
           if sim == sim_name:
               if node_type == 'PRBS':
                   return True
               elif node_type == 'RNC':
                   continue
               else:
                   return False
    return False
    

def is_gpeh_in_rnc(gpehmpcells, simlist):
    if gpehmpcells is not None:
        gpehmaxcell = [x.split(":")[1] for x in gpehmpcells]
        for sim in simlist:
            if 'rnc' in sim.lower():
                rnc_num = sim.lower().split('rnc')[1]
                if 'rnc' in sim.lower() and int(max(gpehmaxcell)) >= int(rnc_num):
                    return True
    return False


def main(argv=None):  # IGNORE:C0111
    '''Command line options.'''

    if argv is None:
        argv = sys.argv
    else:
        sys.argv.extend(argv)

    program_name = os.path.basename(sys.argv[0])
    program_shortdesc = __import__('__main__').__doc__.split("\n")[1]
    program_license = '''%s

  COPYRIGHT Ericsson 2016

  The copyright to the computer program(s) herein is the property of
  Ericsson Inc. The programs may be used and/or copied only with written
  permission from Ericsson Inc. or in accordance with the terms and
  conditions stipulated in the agreement/contract under which the
  program(s) have been supplied.

USAGE
''' % (program_shortdesc)

    # try:
    # Setup argument parser
    parser = ArgumentParser(
        description=program_license, formatter_class=RawDescriptionHelpFormatter)
    parser.add_argument(
        '-l', '--simlist', dest='simlist', help='simulation list', nargs='+', type=str)
    parser.add_argument('-ul', '--uetracelist', dest='uetracelist',
                        help='uetracelist list', nargs='+', type=str)
    parser.add_argument(
        '-b', '--bandwithlim', dest='bandwithlim', help='bandwith limiting', type=str)
    parser.add_argument('-recwl', '--recworkload', dest='recwl',
                        help='recording work load list', nargs='+', type=str)
    parser.add_argument('-statswl', '--statsworkload', dest='statswl',
                        help='stats work load list', nargs='+', type=str)
    parser.add_argument('-gpehwl', '--gpehworkload', dest='gpehwl',
                        help='gpeh work load list', nargs='+', type=str)
    parser.add_argument('-rbsgpehwl', '--rbsgpehworkload', dest='rbsgpehwl',
                        help='rbs gpeh work load list', nargs='+', type=str)
    parser.add_argument('-gpehmpcells', '--gpehmpcellslist', dest='gpehmpcells',
                        help='gpeh mp cells list', nargs='+', type=str)
    parser.add_argument('-playbacksimlist', '--playbacksimlist', dest='playbacksimlist',
                        help='playback sim list', nargs='+', type=str)
    parser.add_argument('-deployment', '--deployment', dest='deployment',
                        help='deployment type', nargs='+', type=str)
    parser.add_argument('-edeStatsCheck', '--edeStatsCheck', dest='edeStatsCheck',
                        help='edeStatsCheck type', nargs='+', type=str)
    parser.add_argument('-periodicHC', '--periodicHC', dest='periodicHC', help='periodic Health check condition', nargs='+', type=str)
    

    # Process arguments
    args = parser.parse_args()
    simlist = args.simlist
    uetracelist = args.uetracelist
    bandwithlim = args.bandwithlim
    statsworkload = args.statswl
    recworkload = args.recwl
    gpehworkload = args.gpehwl
    rbsgpehworkload = args.rbsgpehwl
    gpehmpcellslist = args.gpehmpcells
    playbacksimlist = args.playbacksimlist
    deploymenttype = args.deployment
    periodicHC = args.periodicHC

    if "False" in str(args.edeStatsCheck):
        edeStatsCheck = False
    else:
        edeStatsCheck = True
    # logging.info("Following nodes are not started: %s",str(GenstatsSimPmVerifier.get_all_not_started_nes()))
    check_stats_files(simlist, uetracelist, playbacksimlist, edeStatsCheck)
    check_bandwith_limiting(bandwithlim)

    isgpehEnabled = False
    isrbsgpehEnabled = False

    if is_nodetype_in_simlist("rnc", simlist):
        if is_gpeh_in_rnc(gpehmpcellslist, simlist):
            if not (gpehworkload is None):
                isgpehEnabled = True
            if not (rbsgpehworkload is None):
                isrbsgpehEnabled = True

        check_crontab([x.split(":")[0] for x in statsworkload],
                      [x.split(":")[0] for x in recworkload], [x.split(":")[0] for x in gpehworkload], [x.strip() for x in rbsgpehworkload], True, isgpehEnabled, isrbsgpehEnabled, dpltype=deploymenttype)

    if not (statsworkload is None and recworkload is None):
        check_crontab([x.split(":")[0] for x in statsworkload], [
                      x.split(":")[0] for x in recworkload], dpltype=deploymenttype)

    import platform
    if str(periodicHC).upper() == 'FALSE':
        try:
            result = verify_logfile(platform.node() == 'netsim')
            if result:
                error_message = str(result)
                logging.error('Log files have error: %s', error_message)
                os.system('echo  "ERROR ' + error_message + '" >> ' + LOG_FILE)
        except:
            logging.error(' Genstats log files are missing!')

if __name__ == "__main__":
    if DEBUG:
        sys.argv.append("-h")
        sys.argv.append("-v")
        sys.argv.append("-r")
    if TESTRUN:
        import doctest
        doctest.testmod()
    if PROFILE:

        sys.exit(0)
    sys.exit(main())

