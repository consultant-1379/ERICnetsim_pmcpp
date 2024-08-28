'''
Created on 13 Apr 2016

@author: eaefhiq
'''
import os
import datetime
import glob
import abc
import logging
import subprocess
logging.basicConfig(format='%(levelname)-8s %(message)s', level=logging.INFO)
LOG_FILE = '/netsim/genstats/logs/genstatsQA.log'


class GenstatsSimPmVerifier(object):
    '''
    classdocs
    '''
    NETSIM_DBDIR = "/netsim/netsim_dbdir/simdir/netsim/netsimdir/"

    def __init__(self, tmpfs_dir, simname, pm_data_dir):
        '''
        Constructor
        '''
        self.tmpfs_dir = tmpfs_dir
        self.simname = simname
        self.pm_data_dir = pm_data_dir

    @abc.abstractmethod
    def verify(self):
        return

    def get_nodes_file_not_generated(self, nodename_list, data_dir, reg='*', time_constrain_sec=90):
        result = []
        input_command = "cat /netsim/netsim_cfg | grep 'TYPE=' | cut -d'=' -f2"
        deploymentType = subprocess.Popen(input_command, stdout=subprocess.PIPE, shell=True).communicate()[0]
        if 'NRM' in deploymentType:
            time_constrain_sec = 1000
        else:
            time_constrain_sec = 180
        for nodename in nodename_list:
            pm_data_path = self.tmpfs_dir + \
                self.simname + '/' + nodename + data_dir
            timestamp_of_the_latest_file = self.get_the_latest_file_timestamp_by_regx(
                pm_data_path, reg)
            # print nodename, pm_data_path, timestamp_of_the_latest_file
            if not self.verify_file_timestamp(timestamp_of_the_latest_file, time_constrain_sec):
                result.append(nodename)
        return result

    def check_tmpfs_setup(self, simulation):
        result = self.__get_tmpfs_setup_result(simulation)
        return self.__get_fs_off_nodes(result)

    '''get trace file range  e.g. 154kb_ue_trace.gz:LTE01:1:4:1:64   the range is between 1 and  4'''

    def get_trace_file_range(self, trace_list):
        result = {}
        for x in trace_list:
            nodename = x.split(':')[1]
            result[nodename] = xrange(
                int(x.split(':')[2]), (int(x.split(':')[3]) + 1))
        return result

    def check_node_in_range(self, nodename, index_range):
        node_index = int(nodename[-5:])
        return node_index in index_range

    '''from the files that their names match the given regular expression in the directory to get the latest created file & get the file timestamp'''

    def get_the_latest_file_timestamp_by_regx(self, directory, reg):
        try:
            if not os.listdir(directory):
                return datetime.datetime.now() - datetime.timedelta(weeks=54)
            '''get the latest created file path'''
            latestfile_path = max(
                glob.iglob(directory + reg), key=lambda x: os.lstat(x).st_ctime)
            logging.debug(latestfile_path)
            return datetime.datetime.fromtimestamp(os.lstat(latestfile_path).st_ctime)
        except (ValueError):
            'if there is no file generated in the directory, then this exception is thrown. It returns a time stamp one year ago'
            return datetime.datetime.now() - datetime.timedelta(weeks=54)

    '''to verify if the file is created in last 1 minute.'''

    def verify_file_timestamp(self, latest_file_datetime, time_constrain_sec):
        return latest_file_datetime > datetime.datetime.now() - datetime.timedelta(seconds=time_constrain_sec)

    def find_started_nodes(self, reg="([0-9]{1,3}[\.]){3}[0-9]{1,3}"):
        started_nodes_proc = self.pipe_to_netsim(
            self.netsim_showstarted(), True)
        started_nodes_proc = subprocess.Popen(
            ["grep", "-E", reg], stdin=started_nodes_proc.stdout, stdout=subprocess.PIPE)
        # started_nodes_proc.stdout.close()
        started_node_txt = started_nodes_proc.communicate()[0]
        result = {}
        for line in started_node_txt.splitlines():
            sim_name = line.split()[-1].split("/")[-1]
            node_name = line.split()[0]
            result.setdefault(sim_name, []).append(node_name)
        # logging.debug(str(result))
        return result

    def report_error(self, error_msg, check_fun, *args):
        try:
            result = check_fun(*args)
            if result:
                logging.error(error_msg + " %s", str(result))
                nodes_with_error = str(result)
                message = "ERROR " + error_msg + nodes_with_error
                os.system('echo \"'+ message + '\" >> ' + LOG_FILE)
        except:
            logging.error(error_msg)

    def __get_tmpfs_setup_result(self, simulation):
        # logging.debug("tmpfs checking start at %s",simulation)
        return self.pipe_to_netsim(self.netsim_show_fs(simulation))[0]

    def __get_fs_off_nodes(self, tmpfs_setup_result):
        result = []
        tmp = ''
        flag = False

        for line in tmpfs_setup_result.splitlines():
            if line.startswith('LTE'):
                flag = True
                tmp = line.split()[0].strip()[:-1]
            elif line.strip() == '':
                flag = False
            elif flag:
                if 'tmpfs' in line and 'off' in line:
                    result.append(tmp)
        return result

    @staticmethod
    def findKey(key, keys):
        for temp in keys:
            if key == temp.split('-')[-1]:
                return temp

    @staticmethod
    def pipe_to_netsim(netsim_cmd, pipe_flag=False):
        p = subprocess.Popen(
            ["echo", "-n", netsim_cmd], stdout=subprocess.PIPE)
        netsim_pipe_p = subprocess.Popen(
            ["/netsim/inst/netsim_pipe"], stdin=p.stdout, stdout=subprocess.PIPE)
        p.stdout.close()
        if pipe_flag:
            return netsim_pipe_p
        else:
            return netsim_pipe_p.communicate()

    @staticmethod
    def get_all_not_started_nes():
        result = []
        output = GenstatsSimPmVerifier.pipe_to_netsim(
            GenstatsSimPmVerifier.netsim_show_allsimnes())[0]
        for line in output.splitlines():
            if 'not started' in line:
                result.append(line.split()[0])
        return result

    @staticmethod
    def netsim_showstarted():
        return '''.show started\n'''

    @staticmethod
    def netsim_show_fs(simulation):
        return '''.open %s\n.select network \n.show fs\n''' % (simulation)

    @staticmethod
    def nesim_show_numstartednes_per_simulation():
        return '''.show numstartednes -per-simulation\n'''

    @staticmethod
    def nesim_show_numstartednes():
        return '''.show numstartednes\n'''

    @staticmethod
    def netsim_show_allsimnes():
        return '''.show allsimnes\n'''

    @staticmethod
    def get_all_started_nes_by_type(node_type):
        p_started_nodes = subprocess.Popen(['perl', '-ne', 'if(/(\S+)(\s+)\d{3}.*$/i){print "$1\n";}'], stdin=GenstatsSimPmVerifier.pipe_to_netsim(
            GenstatsSimPmVerifier.netsim_showstarted(), True).stdout, stdout=subprocess.PIPE)
        output = subprocess.Popen(
            ['grep', '-i', node_type], stdin=p_started_nodes.stdout, stdout=subprocess.PIPE).communicate()[0]
        p_started_nodes.stdout.close()
        return output.splitlines()
