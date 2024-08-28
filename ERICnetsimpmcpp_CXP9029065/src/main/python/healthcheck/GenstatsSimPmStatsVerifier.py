'''
Created on 2 Nov 2016

Generic PM stats verification class for
NE types that only generate PM stats files

@author: ejamfur
'''
from GenstatsSimPmVerifier import GenstatsSimPmVerifier, logging
import os


class GenstatsSimPmStatsVerifier(GenstatsSimPmVerifier):
    '''
    classdocs
    '''

    def __init__(self, tmpfs_dir, simname, pm_data_dir):
        '''
        Constructor
        '''
        super(GenstatsSimPmStatsVerifier, self).__init__(
            tmpfs_dir, simname, pm_data_dir)
        self.nodename_list = os.listdir(self.tmpfs_dir + self.simname)
    

    def verify(self):
        self.report_error(self.simname + " misses stats files.",
                          super(
                              GenstatsSimPmStatsVerifier, self).get_nodes_file_not_generated,
                          self.nodename_list, self.pm_data_dir)
