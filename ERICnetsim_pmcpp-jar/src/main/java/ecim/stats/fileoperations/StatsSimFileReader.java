/*
 * This Class responsible for parsing and caching data from required files such as
 * 1) Moc instances config,
 * 2) Coutner property, 
 * 3) Templete/stats xml file.
 */

package ecim.stats.fileoperations;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import ecim.stats.data.EcimStatsConstant;
import ecim.stats.data.MocCfgDataHolder;

public class StatsSimFileReader {

	
	/**
	 * This responsible for reading the moc instance configuration file and
	 * returns a map containing MOC name as key and other info as value
	 * 
	 * @param MOC
	 *            cfg fileName
	 * @return
	 * 
	 */
		public static Map<String,MocCfgDataHolder> readCFGFile(	final String fileName) {
			Map<String,MocCfgDataHolder> mocDataMap = new HashMap<String,MocCfgDataHolder>();
			
			try {
								
				/**
				 * NodeBLocalCell,1
				 * EthernetPort,1
				 * Ikev2Session,1
				 */
				
				BufferedReader br = new BufferedReader(new FileReader(fileName));
				String line = null;
		
				while((line =br.readLine()) != null  )
				{
					/**
					 * Ignore comments and empty lines
					 */
					if(!line.startsWith(EcimStatsConstant.COMMENT_SYMBOL) && !line.trim().isEmpty())
					{
						
						MocCfgDataHolder mocData = parseMocCfgInfo(line);
						mocDataMap.put(mocData.getMocName(), mocData);
												
					}
				}

				br.close();
				
			}catch (FileNotFoundException fne){
			  fne.printStackTrace();			
			} catch (IOException ie) {
				ie.printStackTrace();
			} catch (Exception ex) {
				ex.printStackTrace();
			}
			
			return mocDataMap;

		}
	
		/**
		 * This method parses the passed string and returns MocCfgDataHolder object
		 * @param line
		 * @return MocCfgDataHolder
		 */
		private static  MocCfgDataHolder parseMocCfgInfo(final String line)
		{
			String[] mocInfo = line.split(EcimStatsConstant.CFG_TOKEN_SEP);
			String mocName=null;
			long instanceVal = 0;
			MocCfgDataHolder mocData= null;
			try
			{
			if(mocInfo.length == 2)
			{
				mocName = mocInfo[0];
				instanceVal = Long.parseLong(mocInfo[1].trim());
				if(instanceVal >= 0)
				{
					mocData = new MocCfgDataHolder(mocName.trim(),instanceVal);
				}
			}
			else
			{
				System.out.println("Incorrect data: "+line);
			}
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
			
			return mocData;
		}
	
}
