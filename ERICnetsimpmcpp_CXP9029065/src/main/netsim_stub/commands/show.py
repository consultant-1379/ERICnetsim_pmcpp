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
# Purpose       :  The purpose of this script to replicate the netsim command ".show"
# Jira No       :  EQEV-46794
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/3198599/
# Description   :  OSS Emulator : Coding related to Stub
# Date          :  22/01/2018
# Last Modified :  mahesh.lambud@tcs.com
####################################################

import sys
import ConfigParser
import xml.etree.ElementTree as ET
import re
from string_constants import *
import subprocess
from subprocess import Popen, PIPE

def run_shell_command(input):
    """ This is the generic method, Which spawn a new shell process to get the job done
    """
    output = Popen(input, stdout=PIPE, shell=True).communicate()[0]
    return output

def get_hostname():
    command = "hostname"
    hostname =  run_shell_command(command).strip()
    if "atvts" in hostname:
        return "netsim"
    else:
        return hostname


arg1 = sys.argv[1]

PM_MIBS = {"MSRBS-V2":[["17-Q4-RUI-V3", "MSRBS-V2_71-Q4_V3UPGMib.xml"]], "PRBS":[["16A-WCDMA-V1", "PRBS_16A_V1MIB.xml"], ["61A-UPGIND-LTE-ECIM-MSRBS-V1", "PRBS_61A_UPGIND_V1Mib.xml"], ["61AW-UPGIND-V2", "Fmpmmib.xml"]], "MTAS":[["17B-RUI-CORE-V3", "MTAS_71B-RUI_V3Mib.xml"]]}

with open(USER_INPUT_XML, "r") as user_input_file:
    user_input_string = user_input_file.read()
user_input = ET.fromstring(user_input_string)

def ConfigSectionMap(section):
    Config = ConfigParser.ConfigParser()
    Config.read(ENVIRONMENT)
    env_dict = {}
    options = Config.options(section)
    for option in options:
        try:
            env_dict[option] = Config.get(section, option)
            if env_dict[option] == -1:
                DebugPrint("skip: %s" % option)
        except:
            print("exception on %s!" % option)
            env_dict[option] = None
    return env_dict

def get_simulation_data(SimulationName):
    print("NE Name                  Type                 Server         In Address       Default dest.")
    try:
        node_name = user_input.findall(".//*[@name='%s']/node_name" % SimulationName)[0].text
        node_type = user_input.findall(".//*[@name='%s']/node_type" % SimulationName)[0].text
        sim_mim_ver = user_input.findall(".//*[@name='%s']/sim_mim_ver" % SimulationName)[0].text
        sim_mim_ver = re.sub('[_]','',sim_mim_ver)
        network = user_input.findall(".//*[@name='%s']/network" % SimulationName)[0].text
        nodes_ON = user_input.findall(".//*[@name='%s']/nodes_ON" % SimulationName)[0].text
        node_list = nodes_ON.split(":")
        node_num = 0
        for node in node_list:
            if 'RNC' in node:
                if node_num == 0:
                    get_output(node, node_type.split(":")[0], sim_mim_ver.split(":")[0], network)
                else:
                    get_output(node, node_type.split(":")[1], sim_mim_ver.split(":")[1], network)
            else:
                get_output(node, node_type, sim_mim_ver, network)
            node_num = node_num + 1
    except IndexError:
        print("in except")
        pass

def get_output(node_name, node_type, sim_mim_ver, network):
    print(node_name + "\t\t " + network + " " + node_type + " " + sim_mim_ver + " " + get_hostname())

def get_started():
    node_name = user_input.findall(".//*/nodes_ON")
    node_List = [node.text for node in node_name]
    sim_name = user_input.findall(".//*/sim_name")
    sim_List = [sim.text for sim in sim_name]
    dict = {}
    if len(sim_List) == len(node_List):
        for i in range(0, len(sim_List)):
            dict[sim_List[i]] = node_List[i]
    for key, values in dict.iteritems():
        if 'RNC' in values:
            network, rnc_netype, rbs_netype, rnc_mim_version, rbs_mim_version, simulation = key.split(":")[0], key.split(":")[1], key.split(":")[3], re.sub('[_]','',key.split(":")[2]), re.sub('[_]','',key.split(":")[4]), key.split(":")[6]
            get_header(network, rnc_netype, rnc_mim_version)
            print("    " + values.split(":")[0] + "\t\t/netsim/netsimdir/" + simulation)
            get_header(network, rbs_netype, rbs_mim_version)
            node_num = 0
            for node in values.split(":"):
                if node_num == 0:
                    node_num = node_num + 1
                    continue
                else:
                    print("    " + node + "\t\t/netsim/netsimdir/" + simulation)
                    node_num = node_num + 1
        else:
            network, netype, mim_version, simulation = key.split(":")[0], key.split(":")[1], re.sub('[_]','',key.split(":")[2]), key.split(":")[4]
            get_header(network, netype, mim_version)
            for node in values.split(":"):
                print("    " + node + "\t\t/netsim/netsimdir/" + simulation)

def get_header(network, netype, mim_version):
    print("\n'server_" + network + "_" + netype + "_" + mim_version + "@netsim' for " + network + " " + netype + " " + mim_version)
    print("=================================================================")
    print("    NE                          Simulation/Commands")

def netype_full(node_type, mim_ver):
    for netype in PM_MIBS:
        if netype == node_type:
            for mim in PM_MIBS[netype]:
                if mim_ver == mim[0]:
                    print ("pm_mib :  \"" + mim[1] + "\"")

def main():
    if arg1 == "simnes":
        SimulationName = ConfigSectionMap('Open')['sim_name']
        print(">> .show " + arg1)
        get_simulation_data(SimulationName)
        print("OK")
    elif arg1 == "started":
        print(">> .show " + arg1)
        get_started()
        print("OK")
    elif ' '.join(sys.argv[1:]).startswith("netype full"):
        print(">> .show " + ' '.join(sys.argv[1:]))
        netype_full(sys.argv[3], sys.argv[4])
        print("OK")
    elif arg1 == "netypes":
        with open(NETYPES, 'r') as netypes:
            print netypes.read()
    else:
        print(sys.argv[1:])
        print("function not defined yet")

if __name__ == '__main__': main()
