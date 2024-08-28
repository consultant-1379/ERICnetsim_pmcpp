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
# Purpose       :  The purpose of this script to generate "EUtranCellData.txt" file for LTE nodes
# Jira No       :  EQEV-44613
# Gerrit Link   :  https://gerrit.ericsson.se/#/c/2912255
# Description   :  Created the script as a part of the netsim stub
# Date          :  14/11/2017
# Last Modified :  sardana.bhav@tcs.com
####################################################

import os
import sys
from subprocess import Popen
import xml.etree.ElementTree as ET
sys.path.append('/netsim/bin/')
from eniq_stats_cfg import *
from string_constants import *
sys.path.append('/netsim_users/auto_deploy/bin/')
from confGenerator import getCurrentDateTime, run_shell_command
from collections import defaultdict


mo_csv_map = defaultdict(lambda : defaultdict(list))


def create_csv_file_map():
    ne_type_with_mim_ver = ""
    cmd = "cat " + MO_CSV_FILE + " | sed 's/ //g' | sed -n '1!p'"
    csv_data_list = filter(None, run_shell_command(cmd).strip())
    csv_data_list = csv_data_list.split()
    for data in csv_data_list:
        attrs = data.split(',')
        if attrs[0]:
            ne_type_with_mim_ver = attrs[0] + ':' + attrs[1]
        if len(attrs) > 3:
            for index in range(3, len(attrs)):
                mo_csv_map[ne_type_with_mim_ver][attrs[2]].append(attrs[index])


def writeTopology(topology_file, eutran_file, node_list, node_type, sim_ver, nb_iot_cell):
    cmd = "cat " +  eutran_file + " > " + topology_file
    os.system(cmd)
    cell_list = [1,3,6,12]
    with open(topology_file, 'a') as topology:
        node_list.sort()
        for ne_type_with_mim_ver, relation_dict in mo_csv_map.iteritems():
            if node_type == "PRBS":
                node_type = "MSRBS-V1"
            if node_type in ne_type_with_mim_ver and sim_ver in ne_type_with_mim_ver:
                for relation, instances in relation_dict.iteritems():
                    for node_name in node_list:
                        cmd = "cat " + eutran_file + " | grep " + node_name + " | wc -l"
                        node_cell_count = filter(None, run_shell_command(cmd).strip())
                        for cell_number in range(1, int(node_cell_count)+1):
                            for cell in cell_list:
                                if int(node_cell_count) == cell:
                                    if cell_number == 1 and nb_iot_cell == "Yes":
                                        continue
                                    for mo_value in range(1, int(instances[cell_list.index(cell)])+1):
                                        updated_mo_value = int(node_cell_count)
                                        updated_mo_value += mo_value
                                        data = "ManagedElement=" + node_name + ",ENodeBFunction=1,EUtranCellFDD=" + node_name + "-" + str(cell_number) + ",EUtranFreqRelation=123,"+ relation + "=" + str(updated_mo_value)
                                        topology.write(data + "\n")

def writeEUtranCellData(eutran_file, node_list, no_of_cells, nb_iot_cell, node_type):
    '''This method is used generate Eutrandata file for LTE Nodes by reading parameters simulation 
       name , node_type , nodes_ON etc ... from the user_input.xml and generate the file in /netsim/netsimdir/<LTE Simulation>/SimNetRevision/EUtranCellData.txt'''
    with open(eutran_file, 'w') as f:
        node_list.sort()
        for node_name in node_list:
            for current_cell in range(1,int(no_of_cells)+1):
                if current_cell == 1 and nb_iot_cell == "Yes":
                    if node_type == "MSRBS-V2":
                        eutranCellData =  LTE_MSRBS_V2_FDN_OSS + node_name + ',ManagedElement=' + node_name + ',ENodeBFunction=1,NbIotCell=' + node_name + "-" + str(current_cell)
                    elif node_type == "ERBS":
                        eutranCellData =  ERBS_FDN_OSS + node_name + ',ManagedElement=' + node_name + ',ENodeBFunction=1,NbIotCell=' + node_name + "-" + str(current_cell)
                else:
                    if node_type == "ERBS":
                        eutranCellData =  ERBS_FDN_OSS + node_name + ',ManagedElement=' + node_name + ',ENodeBFunction=1,EUtranCellFDD=' + node_name + "-" + str(current_cell)
                    elif node_type == "PRBS":
                        eutranCellData =  LTE_MSRBS_V1_FDN_OSS + node_name + ',ManagedElement=' + node_name + ',ENodeBFunction=1,EUtranCellFDD=' + node_name + "-" + str(current_cell)
                    elif node_type == "MSRBS-V2":
                        eutranCellData =  LTE_MSRBS_V2_FDN_OSS  + node_name + ',ManagedElement=' + node_name + ',ENodeBFunction=1,EUtranCellFDD=' + node_name + "-" + str(current_cell)        
                f.write(eutranCellData + "\n")

def main():
    create_csv_file_map()

    if not os.path.exists(USER_INPUT_XML):
        sys.exit(1)
    user_input = ET.parse(USER_INPUT_XML)
    root = user_input.getroot()
    for Simulation in root.findall('Simulation'):
        simulationName = Simulation.get('name')
        if "RNC" in simulationName and "LTE" in simulationName:
            continue
        if "LTE" in simulationName:
            eutranCellFilePath = NETSIM_DIR + simulationName + "/SimNetRevision/"
            if not os.path.exists(eutranCellFilePath):
                cmd = "mkdir -p " + eutranCellFilePath
                os.system(cmd)
            eutran_file = eutranCellFilePath + EUTRANCELLDATAFILE
            topology_file = eutranCellFilePath + TOPOLOGYFILE
            node_type = Simulation.find('node_type').text
            sim_ver = Simulation.find('sim_mim_ver').text
            sim_ver = sim_ver.replace("_" , "").upper()
            nodes_ON = Simulation.find('nodes_ON').text
            node_list = nodes_ON.split(":")
            nb_iot_cell = Simulation.find('nb_iot_cell').text
            no_of_cells = Simulation.find('no_of_cells').text
            writeEUtranCellData(eutran_file, node_list, no_of_cells, nb_iot_cell, node_type)
            writeTopology(topology_file, eutran_file, node_list, node_type, sim_ver, nb_iot_cell)

if __name__ == '__main__': main()
