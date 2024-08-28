/**
 * This class is responsible for 
 * 1) Generating MOC CFG file for ECIM Nodes
 * 2) Generating Template file for ECIM Nodes 
 * 3) Generating Counter property file for ECIM Nodes
 *  
 */

package ecim.stats.main;

import java.io.File;
import java.io.FilenameFilter;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

import common.MyLogFormatter;
import ecim.stats.data.EcimStatsConstant;
import ecim.stats.data.MeasurementType;
import ecim.stats.data.MocCfgDataHolder;
import ecim.stats.fileoperations.StatSimFileWriter;
import ecim.stats.fileoperations.StatsSimFileReader;
import ecim.stats.parser.MibFileReader;
import ecim.stats.parser.MocRelationMibFileReader;

public class EcimStatsMain {

	final public static int GEN_MOC_INS_CFG_FILE = 1;

	final public static int GEN_TEMP_AND_CNR_PROP_FILE = 2;

	/**
	 * Default constructor
	 */
	public EcimStatsMain() {
		// TODO Auto-generated constructor stub
	}

/*	
    This method is the start point for the application expects the following
	(-neType and -neVer) or -mom argurments are mandatory for CFG file generation
	usage: ecimXmlgen
	 -inCfg        [Input counter config file : mandatory with mode t]
	 -inRelFile    [Relationship MOM file]
	 -mode         c (CFG generation) : t (Tempalte generatoin) :
	 -mom          Node MIB/MOB file
	 -neType       Node Type : Not needed if mom option is used
	 -neVer        NE Version : Not needed if mom option is used
	 -outCfg       [Output CFG file : mandatory with mode c]
	 -outFile      [Output template file : mandatory with mode t]
	 -prop         [Output counter properties file]
	 -trace        [Trace level]

 */  
	public static void main(String... args) {

		
		try {
			Options options = new Options();
			options.addOption("mode", true,
					"c (CFG generation) : t (Tempalte generatoin) :");
			options.addOption("mom", true, "Node MIB/MOB file");
			options.addOption("neType", true, "Node Type : Not needed if mom option is used");
			options.addOption("neVer", true, "NE Version : Not needed if mom option is used");
			options.addOption("outCfg", true,
					"[Output CFG file : mandatory with mode c]");
			options.addOption("inCfg", true,
					"[Input counter config file : mandatory with mode t]");
			options.addOption("outFile", true,
					"[Output template file : mandatory with mode t]");
			options.addOption("inRelFile", true, "[Relationship MOM file]");
			options.addOption("prop", true, "[Output counter properties file]");
			options.addOption("trace", true, "[Trace level]");
                        options.addOption("node_type", true, "Mandatory to provide functionality in stats file based on ne");

			CommandLineParser parser = new GnuParser();
			try {
				CommandLine line = parser.parse(options, args);

				String traceLevel = line.getOptionValue("trace", "WARNING");
				String mode = line.getOptionValue("mode");
				String momXML = line.getOptionValue("mom");
				String neType = line.getOptionValue("neType");
				String neVer = line.getOptionValue("neVer");
				String inCfg = line.getOptionValue("inCfg");
				String outCfg = line.getOptionValue("outCfg");
				String outFile = line.getOptionValue("outFile");
				String inRelationFile = line.getOptionValue("inRelFile");
				String cntrInfo = line.getOptionValue("prop");
                                String node_type = line.getOptionValue("node_type");

				Level logLevel = Level.parse(traceLevel);
				Logger xmlgenRoot = Logger.getLogger("ecimXmlgen");
				xmlgenRoot.setLevel(logLevel);
				ConsoleHandler myHandler = new ConsoleHandler();
				myHandler.setLevel(logLevel);
				myHandler.setFormatter(new MyLogFormatter());
				xmlgenRoot.addHandler(myHandler);

				HelpFormatter formatter = new HelpFormatter();
				if (mode == null) {
					formatter.printHelp("ecimXmlgen", options);
					System.exit(1);

				} else {
					char choice = mode.trim().charAt(0);
					switch (choice) {

					case 'c':
						/*
						 * If mode c then outcfg value is must. Read the PMS MIB
						 * config file to get MIB file list and parse them to
						 * generate MOC CFG file
						 */
						try {

							if (outCfg == null) {

								System.out
										.println("-outCfg argurment is mandatory for CFG file generation");
								formatter.printHelp("ecimXmlgen", options);
								System.exit(1);
							} else {

								if (neType != null && neVer != null) {

									/*
									 * List<String> mibList = new
									 * PmsMibConfigReader() .getMibList(
									 * EcimStatsConstant.PMS_MIB_CFG_FILE,
									 * neType, neVer);
									 */

									List<String> mibList = getMibsForNodeTypeVersion(
											neType, neVer);
									if (mibList == null) {
										System.out
												.println("PMS is not supportting the Node Type: "
														+ neType
														+ " with NE version: "
														+ neVer
														+ " as per the PMS MIB configuration file "
														+ EcimStatsConstant.PMS_MIB_CFG_FILE);
									} else {
										final Map<String, List<MeasurementType>> pmGrpIdToMeasTypes = new MibFileReader()
												.getMoClassDetails(mibList);
										new StatSimFileWriter().writeCFGFile(
												pmGrpIdToMeasTypes.keySet(),
												outCfg, 1);
									}

								} else if (momXML != null) {
									List<String> mibList = new ArrayList<String>(1);
									mibList.add(momXML);

									final Map<String, List<MeasurementType>> pmGrpIdToMeasTypes = new MibFileReader()
											.getMoClassDetails(mibList);
									new StatSimFileWriter().writeCFGFile(
											pmGrpIdToMeasTypes.keySet(),
											outCfg, 1);

								} else {
									System.out
											.println("(-neType and -neVer) or -mom argurments are mandatory for CFG file generation");
									formatter.printHelp("ecimXmlgen", options);
								}

							}
						} catch (Exception e) {
							System.out
									.println("Exception occured while generating CFG file for the Node Type: "
											+ neType
											+ " with NE version: "
											+ neVer);
							e.printStackTrace();
						}

						break;

					case 'm':
						/*
						 * If mode m then outcfg value is must. Read the PMS MIB
						 * config file to get MIB file list and parse them to
						 * generate MOC with MIM NAME CFG file
						 */
						try {

							if (outCfg == null) {

								System.out
										.println("-outCfg argurment is mandatory for CFG file generation");
								formatter.printHelp("ecimXmlgen", options);
								System.exit(1);
							} else {

								if (neType != null && neVer != null) {

									/*
									 * List<String> mibList = new
									 * PmsMibConfigReader() .getMibList(
									 * EcimStatsConstant.PMS_MIB_CFG_FILE,
									 * neType, neVer);
									 */

									List<String> mibList = getMibsForNodeTypeVersion(
											neType, neVer);
									if (mibList == null) {
										System.out
												.println("PMS is not supportting the Node Type: "
														+ neType
														+ " with NE version: "
														+ neVer
														+ " as per the PMS MIB configuration file "
														+ EcimStatsConstant.PMS_MIB_CFG_FILE);
									} else {

										final Map<String, String> pmGroupToMIMNameMap = new MibFileReader()
												.getPmGroupToMimName(mibList);
										new StatSimFileWriter()
												.writeMimCFGFile(
														pmGroupToMIMNameMap,
														outCfg,1);

									}

								} else if (momXML != null) {
									List<String> mibList = new ArrayList<String>(1);
									mibList.add(momXML);

									final Map<String, String> pmGroupToMIMNameMap = new MibFileReader()
											.getPmGroupToMimName(mibList);
									new StatSimFileWriter().writeMimCFGFile(
											pmGroupToMIMNameMap,
											outCfg,1);

								} else {
									System.out
											.println("(-neType and -neVer) or -mom argurments are mandatory for CFG file generation");
									formatter.printHelp("ecimXmlgen", options);
								}

							}
						} catch (Exception e) {
							System.out
									.println("Exception occured while generating CFG file for the Node Type: "
											+ neType
											+ " with NE version: "
											+ neVer);
							e.printStackTrace();
						}

						break;

						
					case 't':

						/***
						 * If mode f then incfg value and outFile values are
						 * must. Read the PMS MIB config file to get MIB file
						 * list and parse them and inCfg and inRelationFile file
						 * is supplied to generate Tempalte file
						 */
						try {
							if (inCfg == null || outFile == null) {
								System.out
										.println("-inCfg and -outFile argurments are mandatory for TEMPLATE file generation");
								formatter.printHelp("ecimXmlgen", options);
								System.exit(1);
							} else {

								if (neType != null && neVer != null) {

									/*
									 * List<String> mibList = new
									 * PmsMibConfigReader() .getMibList(
									 * EcimStatsConstant.PMS_MIB_CFG_FILE,
									 * NeTypeMapper.getMibConfigNeType(neType),
									 * neVer);
									 */

									List<String> mibList = getMibsForNodeTypeVersion(
											neType, neVer);
									if (mibList == null) {

										System.out
												.println("PMS is not supportting the Node Type: "
														+ neType
														+ " with NE version: "
														+ neVer
														+ " as per the PMS MIB configuration file "
														+ EcimStatsConstant.PMS_MIB_CFG_FILE);
									} else {
										MibFileReader reader = new MibFileReader();
										final Map<String, List<MeasurementType>> pmGrpIdToMeasTypes = reader
												.getMoClassDetails(mibList);

										final Map<String,String> mocNameToPmGroupIdMap = reader.getMocNameToPmGroupIdMap();

										Map<String, MocCfgDataHolder> mocData = StatsSimFileReader
												.readCFGFile(inCfg);

										List<String> momRelFiles = new LinkedList<String>();
										if (inRelationFile != null) {
											momRelFiles.add(inRelationFile);
										}

										Map<String, String> relationData = new MocRelationMibFileReader()
												.getChildToParentRel(momRelFiles,pmGrpIdToMeasTypes.keySet());
										StatSimFileWriter.writeTemplateFile(
												pmGrpIdToMeasTypes, outFile,
												mocData, relationData, neType, mocNameToPmGroupIdMap, node_type);
										if (cntrInfo != null) {
											StatSimFileWriter
													.writeMeasPropFile(
															pmGrpIdToMeasTypes,
															cntrInfo);
										}
									}

								} else if (momXML != null) {
									List<String> mibList = new ArrayList<String>(1);
									mibList.add(momXML);
									MibFileReader reader = new MibFileReader();
									final Map<String, List<MeasurementType>> pmGrpIdToMeasTypes = reader
											.getMoClassDetails(mibList);

									final Map<String,String> mocNameToPmGroupIdMap = reader.getMocNameToPmGroupIdMap();

									Map<String, MocCfgDataHolder> mocData = StatsSimFileReader
											.readCFGFile(inCfg);

									List<String> momRelFiles = new LinkedList<String>();
									if (inRelationFile != null) {
										momRelFiles.add(inRelationFile);
									}

									Map<String, String> relationData = new MocRelationMibFileReader()
											.getChildToParentRel(momRelFiles,pmGrpIdToMeasTypes.keySet());
									StatSimFileWriter.writeTemplateFile(
											pmGrpIdToMeasTypes, outFile,
											mocData, relationData, neType,mocNameToPmGroupIdMap, node_type);
									if (cntrInfo != null) {
										StatSimFileWriter.writeMeasPropFile(
												pmGrpIdToMeasTypes, cntrInfo);
									}

								} else {
									System.out
											.println("(-neType and -neVer) or -mom argurments are mandatory for CFG file generation");
									formatter.printHelp("ecimXmlgen", options);
								}
							}

						} catch (Exception e) {
							System.out
									.println("Exception occured while generating Template file for the Node Type: "
											+ neType
											+ " with NE version: "
											+ neVer);
							e.printStackTrace();
						}
						break;

					default:

						formatter.printHelp("ecimXmlgen", options);
						System.exit(1);
					}

				}

			} catch (ParseException exp) {
				System.err.println("Parsing failed.  Reason: "
						+ exp.getMessage());
				System.exit(1);
			}

			System.exit(0);
		} catch (Throwable t) {
			System.out.println();
			t.printStackTrace();
			System.exit(1);
		}

	}

	/**
	 * This method returns the set of absolute-path to the mibs mapped using
	 * MibConfig.xml file
	 * 
	 * @param nodeType
	 *            for which mib is to be looked up
	 * @param nodeVersion
	 *            for which mib is to be looked up
	 * @return set of mibs absolute path
	 */
	public static List<String> getMibsForNodeTypeVersion(final String nodeType,
			final String nodeVersion) {

		System.out.println("Requested node-type and node-version are "
				+ nodeType + " and " + nodeVersion);
		final List<String> mibsSet = new LinkedList<String>();
		final String lookupDirPath = getLookupDirForNode(nodeType, nodeVersion);
		final File lookupDir = new File(lookupDirPath);
		// check if the directory exists and it is a directory
		if (lookupDir.isDirectory()) {
			final File[] mibFiles = lookupDir.listFiles(new FilenameFilter() {
				@Override
				public boolean accept(final File dir, final String name) {
					return name.endsWith(".xml");
				}
			});
			for (File mibFile : mibFiles) {
				mibsSet.add(mibFile.getAbsolutePath());
			}
		}

		return mibsSet;
	}

	/**
	 * @param nodeType
	 * @param nodeVersion
	 * @return
	 */
	protected static String getLookupDirForNode(final String nodeType,
			final String nodeVersion) {
		final String lookupDirPath = EcimStatsConstant.MIB_FILES_COMMON_PATH
				+ nodeType.toLowerCase() + '/' + nodeVersion.toLowerCase()
				+ "/pm/";
		return lookupDirPath;
	}

	/*
	 * public static void main(String[] args) { List<String> mibList = new
	 * LinkedList<String>();
	 * mibList.add("D:\\Project\\PMNM\\tcu\\Pm_CXP9024262_1_v1_0.xml");
	 * 
	 * Map<String, List<MeasurementType>> pmGrpIdToMeasTypes; try {
	 * pmGrpIdToMeasTypes = new MibFileReader().getMoClassDetails(mibList); //
	 * new StatSimFileWriter().writeCFGFile(pmGrpIdToMeasTypes.keySet(), //
	 * "D:\\Project\\PMNM\\tcu\\tcu03.txt", 5);
	 * 
	 * Map<String, MocCfgDataHolder> mocData = StatsSimFileReader
	 * .readCFGFile("D:\\Project\\PMNM\\tcu\\tcu03.txt");
	 * 
	 * List<String> momRelFiles = new LinkedList<String>();
	 * 
	 * Map<String, String> relationData = new MocRelationMibFileReader()
	 * .getChildToParentRel(momRelFiles);
	 * StatSimFileWriter.writeTemplateFile(pmGrpIdToMeasTypes,
	 * "D:\\Project\\PMNM\\tcu\\tcu03_template.xml", mocData, relationData,
	 * "TCU_03");
	 * 
	 * } catch (Exception e) { // TODO Auto-generated catch block
	 * e.printStackTrace(); }
	 * 
	 * }
	 */

	/*
	 * private static void printData( final Map<String, MocCfgDataHolder>
	 * mocDataMap) {
	 * 
	 * for (String key : mocDataMap.keySet()) {
	 * 
	 * System.out
	 * .println("================================================================="
	 * ); System.out.println(key);
	 * 
	 * System.out
	 * .println("-----------------------------------------------------------------"
	 * ); MocCfgDataHolder moc = mocDataMap.get(key);
	 * 
	 * 
	 * System.out.println("Name "+moc.getMocName());
	 * System.out.println("Count "+moc.getNumOfInstance()); System.out
	 * .println("================================================================="
	 * ); } }
	 */

	/*
	 * private static void printData(final Map<String,List<MeasurementType>>
	 * pmGrpIdToMeasTypes ) {
	 * 
	 * for(String key: pmGrpIdToMeasTypes.keySet()) {
	 * 
	 * System.out.println(
	 * "=================================================================");
	 * System.out.println(key);
	 * 
	 * System.out.println(
	 * "-----------------------------------------------------------------");
	 * List<MeasurementType> measList = pmGrpIdToMeasTypes.get(key);
	 * System.out.println("Length"+measList.size()); for(MeasurementType meas :
	 * measList) { System.out.println(meas.getMeasName()); } System.out.println(
	 * "================================================================="); } }
	 */

}

