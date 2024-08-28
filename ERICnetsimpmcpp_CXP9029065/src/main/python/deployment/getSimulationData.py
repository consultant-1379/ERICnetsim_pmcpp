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
# Version no    :  NSS 17.17
# Purpose       :  Script fetches details of each simulation configured on Netsim
# Jira No       :  NSS-15553
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2836692/
# Description   :  Mismatch in file collection path for vEME node
# Date          :  25/10/2017
# Last Modified :  tejas.lutade@tcs.com
####################################################


"""
Generates  a file /netsim/genstats/tmp/sim_data.txt containing the following data below on each simulation
under /netsim/netsim_dbdir/simdir/netsim/netsimdir/ supported by GenStats

sim_name: <sim_name>  node_name: <node_name> node_type: <node_type> sim_mim_ver: <MIM_version> stats_dir: <stats_filepath> trace: <trace_filepath> mim: <mim file name> mib: <>mib file name

"""
import os
import re
import socket
import subprocess
from subprocess import PIPE, Popen
server_name = socket.gethostname()

NETSIM_DBDIR = "/netsim/netsim_dbdir/simdir/netsim/netsimdir/"
NETSIM_DIR = "/netsim/netsimdir/"
CPP_NE_TYPES = ["M-MGW", "ERBS", "RBS", "RNC"]
EPG_NE_TYPE = "EPG"
WMG_NE_TYPE = "WMG"
SGSN_NE_TYPE = "SGSN"
COMMON_ECIM_NE_TYPES = ["CSCF", "ESAPC", "MTAS", "MRSV", "IPWORKS", "MRFV", "UPG", "WCG", "DSC", "SBG", "EME"]
SPITFIRE_NE_TYPES = ["SPITFIRE", "R6274", "R6672", "R6675", "R6371", "R6471-1", "R6471-2"]
HSS_NE_TYPE = "HSS-FE"
MSRBS_V2_NE_TYPES = ["TCU03", "TCU04", "MSRBS-V2"]
MSRBS_V1_NE_TYPES = ["PRBS", "MSRBS-V1"]
FIVEG_NE_TYPES = ["VPP", "VRC", "RNNODE", "VTFRADIONODE", "5GRADIONODE", "VRM"]
FIVEG_EVENT_FILE_NE_TYPES = ["VTFRADIONODE"]
SUPPORTED_NE_TYPES = [ "CSCF", "EPG-EVR", "EPG-SSR", "MGW", "MTAS", "LTE", "MSRBS-V1", "MSRBS-V2", "PRBS", "ESAPC", "SBG", "SGSN", "SPITFIRE", "TCU", "RBS", "RNC", "RXI", "VBGF", "HSS-FE", "IPWORKS", "C608", "MRF", "UPG", "WCG", "VPP", "VRC", "RNNODE", "DSC", "WMG", "SIU", "EME", "VTFRADIONODE", "5GRADIONODE", "R6274", "R6672", "R6675", "R6371", "R6471-1", "R6471-2", "VRM"]
ECIM_NE_TYPES = MSRBS_V1_NE_TYPES + MSRBS_V2_NE_TYPES + COMMON_ECIM_NE_TYPES + FIVEG_NE_TYPES + SPITFIRE_NE_TYPES
ECIM_NE_TYPES.extend((SGSN_NE_TYPE, EPG_NE_TYPE, HSS_NE_TYPE, WMG_NE_TYPE))
EXCEPTIONAL_NODE_TYPES = ["MTAS", "EME"]
# MIB file names not following the expected naming standard for a given NE must be added here
NONSTANDARD_MIB_FILENAME_MAP = { "SBG_16A": "SBG_16A_CORE_V1Mib.xml", "PRBS_15B": "Fmpmpmeventmib.xml",
"SGSN_16A": "SgsnMmeFmInstances_mp.xml", "SGSN_15B": "SGSN_MME_MIB.xml", "WMG_16B": "WMG_MIB.xml", "PRBS_16A": "fmmib.xml", "EME_16A": "EME_MIB.xml"}
TRANSPORT_NE_TYPES = [ "FRONTHAUL" ]
mim_files = os.listdir("/netsim/inst/zzzuserinstallation/mim_files/")
mib_files = []
if os.path.exists("/netsim/inst/zzzuserinstallation/ecim_pm_mibs/"):
    mib_files = os.listdir("/netsim/inst/zzzuserinstallation/ecim_pm_mibs/")
GENSTATS_TMP_DIR = "/netsim/genstats/tmp/"
SIM_DATA_FILE = GENSTATS_TMP_DIR + "sim_data.txt"
PLAYBACK_CFG = "/netsim_users/pms/bin/playback_cfg"


def run_netsim_cmd(netsim_cmd, pipe_flag=False):
    """ run NETSim commands in the netsim_shell

        Args:
            param1 (string): given NETSim command
            param2 (boolean):

        Returns:
            string: NETSim output command
    """
    p = subprocess.Popen(["echo", "-n", netsim_cmd], stdout=subprocess.PIPE)
    netsim_cmd_out = subprocess.Popen(["/netsim/inst/netsim_shell"], stdin=p.stdout, stdout=subprocess.PIPE)
    p.stdout.close()
    if pipe_flag:
        return netsim_cmd_out
    else:
        return netsim_cmd_out.communicate()[0]


def get_mim_file(node_type, mim_ver):
    """ gets the associated MIM file for a given NE type and MIM version

        Args:
            param1 (string): node type
            param2 (string): node MIM version

        Returns:
            string : mim_file
    """
    mim_file = ""
    if mim_ver[0].isalpha() and node_type in CPP_NE_TYPES:
        mim_ver = get_CPP_mim_ver(mim_ver)

    for mim in mim_files:
        temp_mim = mim.replace("_", "").upper()
        temp_mim_ver = mim_ver.replace("_", "").upper()
        if node_type in mim.upper() and temp_mim_ver in temp_mim.upper():
            return mim
    return mim_file


def get_CPP_mim_ver(mim_ver):
    """ returns the CPP MIM version in the expected format necessary to map to the associated MIM file

        Args:
            param1 (string): node MIM version

        Returns:
            string : NE MIM version
    """
    try:
        cpp_mim_pattern = re.compile("(\S?)(\d+)")
        mim_ver = cpp_mim_pattern.search(mim_ver).group()
        mim_ver = mim_ver[:1] + "_" + mim_ver[1:]
        cpp_mim_ver = mim_ver[:3] + "_" + mim_ver[3:]
        return cpp_mim_ver
    except:
        return mim_ver


def get_nonstandard_mim_ver(mim_ver, mim_ver_pattern):
    """ returns NE release & MIM version for NE types that do not conform to a commom standard

        Args:
            param1 (string): node MIM version
            param2 (string): MIM ver regex pattern

        Returns:
            string : NE MIM version
    """
    formatted_mim_ver = mim_ver.replace("-", "_").upper()
    ne_release_pattern = re.compile(mim_ver_pattern)
    try:
        ne_release = ne_release_pattern.search(formatted_mim_ver).group()
        mim_ver_pattern = re.compile("_([V])(\d+)")
        mim_ver = mim_ver_pattern.search(formatted_mim_ver).group()
        nonstandard_mim_ver = ne_release + mim_ver
    except:
        if "CORE_" in formatted_mim_ver:
            nonstandard_mim_ver = formatted_mim_ver.replace("CORE_","")
        else:
            nonstandard_mim_ver = formatted_mim_ver
    return nonstandard_mim_ver


def get_mib_file(node_type, mim_ver):
    """ gets the associated MIB file for a given ECIM node type and MIM version

        Args:
            param1 (string): node type
            param2 (string): node MIM verison

        Returns:
            string : MIB file name
    """
    mib_file = ""

    shell_command = "echo '.show netype full " + node_type + " " + mim_ver + "' | /netsim/inst/netsim_shell | grep pm_mib | grep .xml | cut -d\":\" -f2"
    mib_file = run_shell_command(shell_command).strip()[1:][:-1]

    if mib_file:
        return mib_file

    node_type = node_type.replace("-", "_").upper()

    if "SGSN" in node_type:
        ssgn_mim_ver_pattern = "(\d+)([A-B])_CP(\d+)"
        mim_ver_sgsn_bck = mim_ver.replace("-", "_").upper()

    if  node_type in COMMON_ECIM_NE_TYPES:
         ecim_mim_ver_pattern = "(\d+)([A-B])"
         mim_ver = get_nonstandard_mim_ver(mim_ver, ecim_mim_ver_pattern)

    formatted_mim_ver = mim_ver.replace("-", "_").upper()

    for mib in mib_files:
        formatted_mib = mib.replace("-", "_").upper()
        if node_type in formatted_mib and formatted_mim_ver in formatted_mib:
            return mib
        #Handling for mim_version name containing String "RUI" in case of SGSN.
        #eg. MIM VER : 16A_CP02_RUI_V4 for MIB NAME : SGSN_16A_CP02_RUI_V4.XML
        elif "SGSN" in node_type:
            if node_type in formatted_mib and mim_ver_sgsn_bck in formatted_mib:
                return mib

        elif "PRBS" in node_type and node_type in formatted_mib:
            prbs_mim_ver = formatted_mim_ver.replace("LTE_","")
            if prbs_mim_ver in formatted_mib:
                return mib

    if mib_file == "":
        node_ver = node_type + "_" + formatted_mim_ver[0:3]
        for node in NONSTANDARD_MIB_FILENAME_MAP:
             if node_ver in node:
                 mib_file = NONSTANDARD_MIB_FILENAME_MAP[node]
                 return mib_file
    return mib_file


def generate_sim_data(sim_list):
    """ get simulation information (nodename, node type/types, mim version/versions) from NETSim
        adds this information to dictionary

        Args:
            param1 (list): simulation list

        Returns:
            dictionary : { <sim_name> : [<simulation/node_info>]}
    """
    sim_info_map = {}

    for sim in sim_list:
        sim_info_map[sim] = []
        netsim_cmd = ".open " + sim + " \n .select network \n .show simnes \n"
        netsim_output = run_netsim_cmd(netsim_cmd, False)
        sim_nodes = netsim_output.split("\n")
        mim_version = ""
        current_mim_version = ""
        is_first_node_in_sim = True

        for node_info in sim_nodes:

           if server_name in node_info:
               node_info_list = node_info.split()
               if 'RNC' in sim.upper() and 'BSC' in node_info_list[0].upper():
                   continue
               mim_version = node_info_list[3]
               if is_first_node_in_sim:
                  sim_info_map[sim].append(node_info)
                  current_mim_version = mim_version
                  is_first_node_in_sim = False

           if  mim_version != "" and mim_version != current_mim_version:
                sim_info_map[sim].append(node_info)
                current_mim_version = mim_version
    return sim_info_map


def run_shell_command(command):
    command_output = Popen(command, stdout=PIPE, shell=True).communicate()[0]
    return command_output


def write_sim_data_to_file(sim_list, sim_info_map):
    """ writes the simulation data to /netsim/genstats/tmp/sim_data.txt file

        Args:
            param1 (list): simulations list
            param2 (dictionary): { <sim_name> : [<simulation/node_info>]}

    """
    os.system("rm -rf " + GENSTATS_TMP_DIR)
    os.system("mkdir -p " + GENSTATS_TMP_DIR)
    # default values
    stats_dir = "/c/pm_data/"
    trace_dir = "/c/pm_data/"
    mib_file = ""
    mim_file = ""
    file_writer = open(SIM_DATA_FILE, "w+")
    for sim in sim_info_map:
        node_info = sim_info_map[sim]
        for node in node_info:
            node_info_list = node.split()
            node_name = node_info_list[0]
            node_type = node_info_list[2].upper()
            sim_mim_ver = node_info_list[3].upper()
            mim_ver = sim_mim_ver

            mim_file = get_mim_file(node_type, mim_ver)
            if not mim_file:
                print "WARN : "+ sim +" do not have required MIM File. Please check"
                continue
            if node_type in ECIM_NE_TYPES:
                mib_file = get_mib_file(node_type, mim_ver)
                if not mib_file:
                    print "WARN : "+ sim +" do not have required MIB File. Please check"
                    continue
            if node_type in CPP_NE_TYPES:
                data_dir = "performanceDataPath"
            else:
                data_dir = "fileLocation"

            stats_dir = get_pmdata_mo_attribute_value(data_dir, sim, node_name, node_type, mim_ver)
            if not stats_dir:
                print "WARN : "+ sim +" do not have stats_dir set. Please check"
                continue

            if node_type in MSRBS_V1_NE_TYPES or node_type in MSRBS_V2_NE_TYPES or node_type in FIVEG_EVENT_FILE_NE_TYPES:
                trace_dir = get_pmdata_mo_attribute_value("outputDirectory", sim, node_name, node_type, mim_ver)
            else:
                trace_dir = "/c/pm_data/"

            if not trace_dir:
                print "WARN : "+ sim +" do not have trace_dir set. Please check"
                continue

            if not stats_dir.endswith("/"):
                stats_dir = stats_dir + "/"
            if not trace_dir.endswith("/"):
                trace_dir = trace_dir + "/"

            sim_information = "sim_name: " + sim + "\tnode_name: " + node_name + " \tnode_type: " + node_type + "\tsim_mim_ver: " + mim_ver + "\tstats_dir: " + stats_dir + "\ttrace: " + trace_dir + "\tmim: " + mim_file

            if node_type in ECIM_NE_TYPES:
                file_writer.write(sim_information + "\t mib: " + mib_file + "\n")
            else:
                file_writer.write(sim_information + "\n")

    file_writer.close

def get_playback_list():
    if os.path.isfile(PLAYBACK_CFG):
       PLAYBACK_SIM_LIST = []
       cfg = open(PLAYBACK_CFG)
       for line in cfg:
           if 'NE_TYPE_LIST' in line:
              PLAYBACK_SIM_LIST = line.split("=")[-1].replace("\"","").split()
              cfg.close()
              return PLAYBACK_SIM_LIST
    else:
        return None

def  get_pmdata_mo_attribute_value(data_dir, sim_name, node_name, node_type, mim_ver):
    """ gets the value of PmService, PmMeasurementCapabilities and PMEventM:FilePullCapabilities MO attribute from NETSim

        Args:
            param1 (string): MO attribute
            param2 (string): simulation name
            param3 (string): node name
            param4 (string): node type
            param5 (string): node mim version

        Returns:
            string : MO attribute value (file path)
    """
    attribute = "/c/pm_data/"
    mo_fdn = ""

    if node_type in CPP_NE_TYPES:
        if "fileLocation" in data_dir:
              mo_attribute = "performanceDataPath="
              mo_fdn = "dumpmotree:moid=\"ManagedElement=1,SystemFunctions=1,PmService=1\",printattrs;"

    if node_type in MSRBS_V1_NE_TYPES:
        mo_id = "1";
        if "15B" in mim_ver:
            mo_id = "2";
        if "fileLocation" in data_dir:
            mo_attribute = data_dir
            mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + node_name + ",ComTop:SystemFunctions=1,MSRBS_V1_PM:Pm=1,MSRBS_V1_PM:PmMeasurementCapabilities=1\",printattrs;"

        if "outputDirectory" in data_dir:
            mo_attribute = data_dir
            mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + node_name + ",ComTop:SystemFunctions=1,MSRBS_V1_PMEventM:PmEventM=1,MSRBS_V1_PMEventM:EventProducer=Lrat,MSRBS_V1_PMEventM:FilePullCapabilities=" + mo_id + "\",printattrs;"

    if node_type in MSRBS_V2_NE_TYPES:
        if "fileLocation" in data_dir:
            mo_attribute = data_dir
            mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + node_name + ",ComTop:SystemFunctions=1,RcsPm:Pm=1,RcsPm:PmMeasurementCapabilities=1\",printattrs;"

        if "outputDirectory" in data_dir:
            mo_attribute = data_dir
            mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + node_name + ",ComTop:SystemFunctions=1,RcsPMEventM:PmEventM=1,RcsPMEventM:EventProducer=Lrat,RcsPMEventM:FilePullCapabilities=2\",printattrs;"


    if SGSN_NE_TYPE in node_type:
        if "fileLocation" in data_dir:
            mo_attribute = data_dir
            mo_fdn = "dumpmotree:moid=\"SgsnMmeTop:ManagedElement=" + node_name + ",SgsnMmeTop:SystemFunctions=1,SgsnMmePM:Pm=1,SgsnMmePM:PmMeasurementCapabilities=1\",printattrs;"


        if "outputDirectory" in data_dir:
            mo_attribute = data_dir
            mo_fdn = "dumpmotree:moid=\"SgsnMmeTop:ManagedElement=" + node_name + ",SgsnMmeTop:SystemFunctions=1,SgsnMmePMEventM:PmEventM=1,SgsnMmePMEventM:EventProducer=1,SgsnMmePMEventM:FilePullCapabilities=1\",printattrs;"


    if node_type in COMMON_ECIM_NE_TYPES:
        managedElementId = node_name
        if "fileLocation" in data_dir:
            mo_attribute = "fileLocation"
            mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + managedElementId + ",ComTop:SystemFunctions=1,CmwPm:Pm=1,CmwPm:PmMeasurementCapabilities=1\",printattrs;"

    if node_type in SPITFIRE_NE_TYPES:
        mo_attribute = "fileLocation"
        mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=1,ComTop:SystemFunctions=1,Ipos_Pm:Pm=1,Ipos_Pm:PmMeasurementCapabilities=1\",printattrs;"

    if node_type.replace('_','-') in HSS_NE_TYPE:
        mo_attribute = "fileLocation"
        mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=1,ComTop:SystemFunctions=1,ECIM_PM:Pm=1,ECIM_PM:PmMeasurementCapabilities=1\",printattrs;"

    if EPG_NE_TYPE in node_type:
        attribute = "/var/log/services/epg/pm/"

    if WMG_NE_TYPE in node_type:
        attribute = "/md/wmg/pm/"

    if node_type in FIVEG_NE_TYPES:
        if "fileLocation" in data_dir:
            mo_attribute = data_dir
            mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + node_name + ",ComTop:SystemFunctions=1,RcsPm:Pm=1,RcsPm:PmMeasurementCapabilities=1\",printattrs;"

        if node_type in FIVEG_EVENT_FILE_NE_TYPES:
           if "outputDirectory" in data_dir:
               mo_attribute = data_dir
               if "RUI" in sim_name:
                   mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + node_name + ",ComTop:SystemFunctions=1,RcsPMEventM:PmEventM=1,RcsPMEventM:EventProducer=Lrat,RcsPMEventM:FilePullCapabilities=2\",printattrs;"
               else:
                   mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + node_name + ",ComTop:SystemFunctions=1,RcsPMEventM:PmEventM=1,RcsPMEventM:EventProducer=VTFrat,RcsPMEventM:FilePullCapabilities=2\",printattrs;"

    if node_type in TRANSPORT_NE_TYPES:
        if "fileLocation" in data_dir:
            mo_attribute = data_dir
            mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=1,ComTop:SystemFunctions=1,OPTOFH_PM:Pm=1,OPTOFH_PM:PmMeasurementCapabilities=1\",printattrs;"

    if not mo_fdn:
        return attribute

    mo_value = get_mo_attribute_value(sim_name,node_name,mo_fdn,mo_attribute)
    if mo_value:
       attribute = mo_value
    else:
        if node_type in COMMON_ECIM_NE_TYPES:
            if any(y in node_type for y in EXCEPTIONAL_NODE_TYPES):
                managedElementId = "1"
                if "fileLocation" in data_dir:
                    mo_attribute = "fileLocation"
                    mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + managedElementId + ",ComTop:SystemFunctions=1,CmwPm:Pm=1,CmwPm:PmMeasurementCapabilities=1\",printattrs;"
                    mo_value = get_mo_attribute_value(sim_name,node_name,mo_fdn,mo_attribute)
                    if mo_value:
                        attribute = mo_value
        elif node_type in FIVEG_NE_TYPES:
            if node_type in FIVEG_EVENT_FILE_NE_TYPES:
                if "outputDirectory" in data_dir:
                    mo_attribute = data_dir
                    if "RUI" in sim_name:
                        mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + node_name + ",ComTop:SystemFunctions=1,RcsPMEventM:PmEventM=1,RcsPMEventM:EventProducer=Lrat,RcsPMEventM:FilePullCapabilities=2\",printattrs;"
                    else:
                        mo_fdn = "dumpmotree:moid=\"ComTop:ManagedElement=" + node_name + ",ComTop:SystemFunctions=1,RcsPMEventM:PmEventM=1,RcsPMEventM:EventProducer=VTFratPA1,RcsPMEventM:FilePullCapabilities=2\",printattrs;"
                    mo_value = get_mo_attribute_value(sim_name,node_name,mo_fdn,mo_attribute)
                    if mo_value:
                        attribute = mo_value
    return attribute

def get_mo_attribute_value(sim_name, node_name, mo_fdn, mo_attribute):
    attribute = ""
    netsim_cmd = ".open " + sim_name + " \n .select " + node_name + " \n " + mo_fdn + " \n"
    mo_attributes = run_netsim_cmd(netsim_cmd, False)
    mo_attributes = mo_attributes.split("\n")
    mo_attribute = mo_attribute + "="
    for atribute in mo_attributes:
        if mo_attribute in atribute:
            attribute = atribute.replace(mo_attribute, '')
    return attribute

def fetchSimListToBeProcessed():
    sim_list = []
    sim_list_delete = []
    sim_list_add = []
    sims = os.listdir(NETSIM_DBDIR)
    netsimdir_sims = os.listdir(NETSIM_DIR)
    UNSUPPORTED_SIMS = ['TSP', 'CORE-MGW-15B-16A-UPGIND-V1', 'CORE-SGSN-42A-UPGIND-V1', 'PRBS-99Z-16APICONODE-UPGIND-MSRBSV1-LTE99', 'RNC-15B-16B-UPGIND-V1', 'VNFM', 'LTEZ9334-G-UPGIND-V1-LTE95', 'LTEZ8334-G-UPGIND-V1-LTE96', 'LTEZ7301-G-UPGIND-V1-LTE97', 'RNCV6894X1-FT-RBSU4110X1-RNC99', 'LTE17A-V2X2-UPGIND-DG2-LTE98', 'LTE16A-V8X2-UPGIND-PICO-FDD-LTE98', 'VSD', 'NFVO', 'RNC-FT-UPGIND-PRBS61AX1-RNC01', 'OPENMANO', 'GSM-FT-BSC_17-Q4_V4X2', 'GSM-ST-BSC-16B-APG43L-X5', 'RNC-FT-UPGIND-PRBS61AX1-RNC31', 'RNCV10305X2-FT-RBSUPGIND']
    if get_playback_list():
        UNSUPPORTED_SIMS.extend(get_playback_list())

    for sim in sims:

        if sim in netsimdir_sims:

            if any(y in sim.upper() for y in UNSUPPORTED_SIMS):
                sim_list_delete.append(sim)

            elif any(x in sim.upper() for x in SUPPORTED_NE_TYPES):
                sim_list_add.append(sim)

    sim_list = [simType for simType in sim_list_add if simType not in sim_list_delete]
    return sim_list

def main():

    sim_list = fetchSimListToBeProcessed()
    sim_info_map = generate_sim_data(sim_list)
    write_sim_data_to_file(sim_list, sim_info_map)

if __name__ == "__main__": main()


