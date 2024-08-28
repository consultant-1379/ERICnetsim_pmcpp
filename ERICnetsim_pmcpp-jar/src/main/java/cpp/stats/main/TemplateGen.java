package cpp.stats.main;

/*
 * This file generates the template xml files
 * The configuration file which contains the MOClasses, Instance values
 * should exist, and this class will get the counternames and
 * loop through all the instances to generate the template XML file
 * This template XML file then will be used by the regualr tool
 * to send the notifications
 */
import cpp.stats.data.CounterInfo;
import cpp.stats.parser.CounterReader;
import cpp.stats.data.Hierarchy;

import java.io.*;
import java.util.*;
import java.util.logging.*;

import org.apache.commons.cli.*;

import common.MyLogFormatter;

public class TemplateGen {
    private static Logger m_Log = Logger
            .getLogger("xmlgen.cpp.stats.main.TemplateGen");

    private String momXml_; // This represents the XML MoM File
    private String configFile_; // This represents the config file used for the
                                // template generation
    private String outputFile_;
    private String cntrInfoFile_;
    private String cntrOptsFile_;

    Map momCounterMap;
    List cfgList;
    Map cfgMap = new HashMap();
    Map cntrOptsMap = new HashMap();

    java.util.Formatter formatter = new java.util.Formatter();

    CounterReader counterReader_;
    Hierarchy hierarchy_;

    private LinkedList classLinkedList_;
    private LinkedList instanceLinkedList_;
    private HashMap selectedCntr_;

    private boolean generateCounterTextFile_;
    private FileOutputStream counterStream;
    // Output stream Writer for counterText
    private OutputStreamWriter counterTextOut_;

    // Output stream Writer
    private OutputStreamWriter out_;
    private PrintWriter propWriter;

    private int numMoInst;
    private int numSingleValueCounters;
    private int numPdfCounters;
    private int numPdfValues;

    public TemplateGen(String momXml, String configFile, String outputFile,
            String cntrInfoFile, String optsFile) throws Exception {
        momXml_ = momXml;
        configFile_ = configFile;
        outputFile_ = outputFile;
        cntrInfoFile_ = cntrInfoFile;
        cntrOptsFile_ = optsFile;

        // TODO: Take this value in from the contructor
        // generateCounterTextFile_ = true;
        initTemplate();

    }

    // The method to initilize classes and call differnet methods
    // to generate the template file
    void initTemplate() throws Exception {
        //System.out.println("Reading Counters from MOM");
        CounterReader counterReader = new CounterReader(momXml_);
        momCounterMap = counterReader.getCounterMap();

        //System.out.println("Reading MO hierarchy");
        hierarchy_ = new Hierarchy(momXml_);

        //System.out.println("Init Template");
        cfgList = readConfiguration();
        for (Iterator itr = cfgList.iterator(); itr.hasNext();) {
            MoCfg moCfg = (MoCfg) itr.next();
            cfgMap.put(moCfg.type, moCfg);
        }

        if (cntrInfoFile_ != null)
            propWriter = new PrintWriter(new FileWriter(cntrInfoFile_));

        if (cntrOptsFile_ != null)
            readCntrOptsFile(cntrOptsFile_, cntrOptsMap);

        generateTemplate();

        if (propWriter != null)
            propWriter.close();
    }

    /**
     * This method reads the configuration file and Populates the classnames and
     * instance vectors
     *
     * See parseLine method for format of the file
     *
     */
    List readConfiguration() throws Exception {
        List theCfg = new LinkedList();

        String currentLine = null;
        LineNumberReader lin = new LineNumberReader(new FileReader(configFile_));
        currentLine = lin.readLine();
        while (currentLine != null) {
            // If the line does not start with # then populate
            if ((!currentLine.startsWith("#")) && (currentLine.length() > 0)) {
                MoCfg moCfg = parseLine(currentLine);
                if (moCfg != null)
                    theCfg.add(moCfg);
            }

            currentLine = lin.readLine();
        }
        lin.close();

        return theCfg;
    }

    /**
     * Parses a line in the cfg file. The format of the line is as follows
     *
     * MoType,#instances,MoParentType[,cntr,cntr,..] where #instances: is the
     * number of instances of this time to generate PER parent instance For
     * example UtranRelation,30,UtranCell will generate 30 UtranRelations PER
     * UtranCell cntr: The name of the counter. If no counter are specfied, then
     * all counters defined in the MOM are used. Note: counters can be
     * customised by counterName@custom, e.g. pmRes9@FIXED[0]=5635. The custom
     * text will be included in the cntrprops file If the counter is "newblock",
     * when this is used to create new block This is to handle the case where
     * some OSS-RC apps required their counters to be in their own md block
     *
     */
    MoCfg parseLine(String tmpString) {
        // First get the moclass and then the instance value

        StringTokenizer stn = new StringTokenizer(tmpString);
        // First token is the MO Class
        String moClass = stn.nextToken(",");
        // Next token is the instance value
        String instance = stn.nextToken(",");

        if (!instance.equals("0")) {
            // Next token is the parent MO class (not used here)
            String parent = stn.nextToken(",");

            // Optionally, the set of counters to be used be specified
            // If they are not specified, then all counters for that MO type
            // are used
            List specifiedCntrList = new LinkedList();
            Map cntrOpts = new HashMap();
            if (stn.hasMoreTokens()) {
                // Contains the list of counter blocks (groups of counters)
                List block = new LinkedList();
                specifiedCntrList.add(block);
                while (stn.hasMoreTokens()) {
                    String cntrName = stn.nextToken(",");
                    if (cntrName.equals("newblock")) {
                        block = new LinkedList();
                        specifiedCntrList.add(block);
                    } else {
                        int optSeperatorIndex = cntrName.indexOf("@");
                        if (optSeperatorIndex == -1)
                            block.add(cntrName);
                        else {
                            String realCntrName = cntrName.substring(0,
                                    optSeperatorIndex);
                            String cntrOpt = cntrName
                                    .substring(optSeperatorIndex + 1);
                            block.add(realCntrName);
                            cntrOpts.put(realCntrName, cntrOpt);
                        }
                    }
                }
            }

            return new MoCfg(moClass, Integer.parseInt(instance),
                    specifiedCntrList, cntrOpts);
        } else
            return null;
    }

    /**
     * Format is MoType counterName counterOpts
     *
     */
    void readCntrOptsFile(String fileName, Map cntrOptsMap) throws Exception {
        LineNumberReader lin = new LineNumberReader(new FileReader(fileName));
        String currentLine;
        while ((currentLine = lin.readLine()) != null) {
            // If the line does not start with # then populate
            if ((!currentLine.startsWith("#")) && (currentLine.length() > 0)) {
                String parts[] = currentLine.split(" ");
                if (parts.length != 3)
                    throw new Exception("Invalid line: " + lin.getLineNumber()
                            + " " + currentLine);
                cntrOptsMap.put(parts[0] + "." + parts[1], parts[2]);
            }
        }
        lin.close();
    }

    // This method returns the XML Header
    String returnHeader() {
        StringBuffer xmlHeader = new StringBuffer();
        xmlHeader.append("<?xml version=\"1.0\"?>\n");
        xmlHeader
                .append("<?xml-stylesheet type=\"text/xsl\" href=\"MeasDataCollection.xsl\"?>\n");
        xmlHeader.append("<!DOCTYPE mdc SYSTEM \"MeasDataCollection.dtd\">\n");
        xmlHeader.append("<mdc xmlns:HTML=\"http://www.w3.org/TR/REC-xml\">\n");
        xmlHeader.append("<!-- " + momXml_ + " " + configFile_ + " "
                + new java.util.Date() + " -->\n");

        xmlHeader.append("<mfh>\n");
        xmlHeader.append("<ffv>1</ffv>\n");
        xmlHeader.append("<sn></sn>\n");
        xmlHeader.append("<st></st>\n");
        xmlHeader.append("<vn></vn>\n");
        xmlHeader.append("<cbt>startdate</cbt>\n");
        xmlHeader.append("</mfh>\n");
        return xmlHeader.toString();
    }

    /**********
     * This method returns the body of XML file with the looping for all the
     * classes. One Loop will have <md> <neid> <neun></neun> <nedn></nedn>
     * </neid> <mi> <mts>stopdate</mts> <gp>900</gp> <mt>counterName</mt> <mv>
     * As many MV Blocks as number of instances <moid>MOID</moid> <r>1000</r>
     * </mv> </mi> </md>
     ****************/

    void writeBody() throws Exception {
        m_Log.entering("TemplateGen", "returnBody");

        numMoInst = 0;
        numSingleValueCounters = 0;
        numPdfCounters = 0;
        numPdfValues = 0;

        /*System.out.printf("%-20s %8s %8s %8s %8s %8s\n", "Type", "Inst",
                "NonPdf", "Pdf", "PdfVal", "Total");
        System.out
                .println("*****************************************************************");*/
        // Loop through all the classes in the classLinkedList_
        for (Iterator moItr = cfgList.iterator(); moItr.hasNext();) {
            MoCfg moCfg = (MoCfg) moItr.next();
            List cntrList = getCounters(moCfg);

            if (cntrList.size() > 0) {
                writeCounterProps(cntrList, moCfg);

                //System.out.printf("%-20s ", moCfg.type);

                int preMoInst = numMoInst;
                int prenumSingleValueCounters = numSingleValueCounters;
                int prenumPdfCounters = numPdfCounters;
                int preNumPdfVal = this.numPdfValues;

                List instanceList = makeInstanceList(moCfg.type);
                numMoInst += instanceList.size();

                for (Iterator itr = cntrList.iterator(); itr.hasNext();) {
                    List cntrBlk = (List) itr.next();

                    StringBuffer sb = new StringBuffer("");
                    sb.append("<md>\n");
                    // SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,SubNetwork=RNC01
                    sb.append("<!-- Padding to make up for empty neun/nedn fields    -->\n");
                    sb.append("<neid>\n");
                    sb.append("<neun></neun>\n");
                    sb.append("<nedn></nedn>\n");
                    sb.append("</neid>\n");
                    sb.append("<mi>\n");
                    sb.append("<mts>stopdate</mts>\n");
                    sb.append("<gp>900</gp>\n");
                    sb.append(returnMTBlock(cntrBlk));
                    writeToFile(sb.toString());

                    writeRBlock(instanceList, cntrBlk);

                    writeToFile("</mi>\n</md>\n");
                }

                /*System.out
                        .printf("%8d %8d %8d %8d %8d\n",
                                (numMoInst - preMoInst),
                                (numSingleValueCounters - prenumSingleValueCounters),
                                (numPdfCounters - prenumPdfCounters),
                                (numPdfValues - preNumPdfVal),
                                ((numSingleValueCounters - prenumSingleValueCounters) + (numPdfValues - preNumPdfVal)));*/
            }
        }
        // Write the last tag
        writeToFile("<mff><ts>stopdate</ts></mff>\n");
        writeToFile("</mdc>\n");
        // writeToFile("<!--- EOF -->\n");

        System.out.println();

        /*System.out.printf("%-20s %8d %8d %8d %8d %8d", "Totals", numMoInst,
                numSingleValueCounters, numPdfCounters, numPdfValues,
                (numSingleValueCounters + numPdfValues));*/

        m_Log.exiting("TemplateGen", "returnBody");
    }

    // This method returns the string containing
    // all counter names for the specified class
    // in the XML format <mt> counter name </mt>
    String returnMTBlock(List cntrBlk) {
        StringBuffer mtBlock = new StringBuffer();
        for (Iterator itr = cntrBlk.iterator(); itr.hasNext();) {
            CounterInfo ci = (CounterInfo) itr.next();
            mtBlock.append("<mt>" + ci.name + "</mt>\n");
        }
        return mtBlock.toString();
    }

    List makeInstanceList(String moClass) {
        m_Log.entering("TemplateGen", "makeInstanceList", moClass);

        List instanceList = new LinkedList();
        if (!moClass.equals("ManagedElement")) {
            String parentMoClass = hierarchy_.returnParent(moClass);
            List parentInst = makeInstanceList(parentMoClass);

            int instCount = 1;
            MoCfg moCfg = (MoCfg) cfgMap.get(moClass);
            if (moCfg != null)
                instCount = moCfg.instCount;

            m_Log.fine("makeInstanceList instCount = " + instCount + " for "
                    + moClass);
            m_Log.fine("makeInstanceList num MOs to create = "
                    + (parentInst.size() * instCount) + " for " + moClass);

            for (Iterator parentItr = parentInst.iterator(); parentItr
                    .hasNext();) {
                String instBase = ((String) parentItr.next()) + "," + moClass
                        + "=";
                for (int i = 1; i <= instCount; i++)
                    instanceList.add(instBase + String.valueOf(i));
            }
        } else
            instanceList.add("ManagedElement=1");

        m_Log.exiting(
                "TemplateGen",
                "makeInstanceList",
                "instanceList.size() for " + moClass + " = "
                        + instanceList.size());

        return instanceList;
    }

    String getMoBranch(String moType) {
        m_Log.entering("TemplateGen", "getMoBranch", moType);

        String parentMoClass = hierarchy_.returnParent(moType);
        String result = null;
        if (parentMoClass.equals("ManagedElement"))
            result = moType;
        else
            result = getMoBranch(parentMoClass);

        m_Log.exiting("TemplateGen", "getMoBranch", result);

        return result;
    }

    void writeCounterProps(List counterList, MoCfg moCfg) throws Exception {
        if (propWriter == null)
            return;

        for (Iterator blkItr = counterList.iterator(); blkItr.hasNext();) {
            for (Iterator ciItr = ((List) blkItr.next()).iterator(); ciItr
                    .hasNext();) {
                CounterInfo ci = (CounterInfo) ciItr.next();
                int behaviour = ci.behaviour;
                String isCompressed ="UNCOMPRESSED";
                if (behaviour == CounterInfo.UNKNOWN) {
                    String moBranch = getMoBranch(moCfg.type);
                    if (moBranch.equals("RncFunction")
                            || moBranch.equals("NodeBFunction"))
                        behaviour = CounterInfo.RESET;
                    else
                        behaviour = CounterInfo.MONOTONIC;

                    m_Log.info("writeCounterProps Unknown behaviour for "
                            + moCfg.type + "." + ci.name + " assuming "
                            + CounterInfo.getBehaviourName(behaviour));
                }
                if(ci.isCompressedCounter()){
                    isCompressed = "COMPRESSED";
                }
                propWriter.print(moCfg.type + "," + ci.name + ","
                        + CounterInfo.getBehaviourName(behaviour) + ","
                        + CounterInfo.getTypeName(ci.type)+ "," +isCompressed);

                // Check if this counter has any optional parameters specified
                // in the cfg file
                String cntrOpt = (String) moCfg.cntrOpts.get(ci.name);
                if (cntrOpt != null)
                    propWriter.print("," + cntrOpt);

                // Check the cntrOpts
                cntrOpt = (String) cntrOptsMap.get(moCfg.type + "." + ci.name);
                if (cntrOpt != null)
                    propWriter.print("," + cntrOpt);

                propWriter.println();
            }
        }
    }

    List getCounters(MoCfg moCfg) throws Exception {
        m_Log.entering("TemplateGen", "getCounters", moCfg.type);

        List momCntrList = (List) momCounterMap.get(moCfg.type);
        List cntrList = new LinkedList();

        if (moCfg.activeCntrs.size() == 0) // No specifed cntrs, use all mom
                                            // Cntrs
        {
            // Sort the counters so that we can compare files generated with the
            // older version of this code

            // Might be no counters defined for this MO type
            if (momCntrList != null) {
                List sortedMomCntrs = new ArrayList(momCntrList);
                Collections.sort(sortedMomCntrs);
                cntrList.add(sortedMomCntrs);
            }
        } else {
            // Check that that counters haven't been disabled for this MO type
            List firstBlock = (List) moCfg.activeCntrs.get(0);
            String firstCntr = (String) firstBlock.get(0);
            if (!firstCntr.equals("none")) {
                Map ciMap = new HashMap();
                for (Iterator momItr = momCntrList.iterator(); momItr.hasNext();) {
                    CounterInfo ci = (CounterInfo) momItr.next();
                    ciMap.put(ci.name, ci);
                }

                for (Iterator blkItr = moCfg.activeCntrs.iterator(); blkItr
                        .hasNext();) {
                    List blk = (List) blkItr.next();

                    List ciList = new LinkedList();
                    for (Iterator cntrItr = blk.iterator(); cntrItr.hasNext();) {
                        String cntrName = (String) cntrItr.next();
                        CounterInfo ci = (CounterInfo) ciMap.get(cntrName);
                        if (ci == null)
                            throw new IllegalStateException(
                                    "No counter info found in MOM for "
                                            + moCfg.type + "." + cntrName);
                        ciList.add(ci);
                    }
                    cntrList.add(ciList);
                }
            }
        }

        m_Log.exiting("TemplateGen", "getCounters",
                " numBlks=" + cntrList.size());

        return cntrList;
    }

    // This method returns the string containing
    // all counter names for the specified class
    // <mv>
    // <moid> MOID </moid>
    // <r> Values </r>
    // </mv>
    void writeRBlock(List instanceList, List counters) throws Exception {
        m_Log.entering("TemplateGen", "writeRBlock");

        for (Iterator instItr = instanceList.iterator(); instItr.hasNext();) {
            String moId = (String) instItr.next();
            writeToFile("<mv>\n<moid>" + moId + "</moid>\n");
            for (Iterator cntrItr = counters.iterator(); cntrItr.hasNext();) {
                CounterInfo ci = (CounterInfo) cntrItr.next();
                if (ci.type == CounterInfo.MULTI_VALUE)
                    writeMultiValues(ci.pdfValues);
                else
                    writeValue();
            }
            writeToFile("</mv>\n");
        }

        m_Log.exiting("TemplateGen", "writeRBlock");
    }

    private String genCntrVal() {
        int value = 0;
        if (propWriter == null)
            value = (int) (Math.random() * 100);

        return String.valueOf(value);
    }

    // This method writes the value of each PDF or DDM (sequence) counter
    // This method writes the value 100+Passed value
    // or the random number depending on configuration
    private void writeMultiValues(int maxRange) throws Exception {
        // For the R tags, generate Random values
        StringBuffer values = new StringBuffer("<r>");
        for (int c = 0; c < maxRange; c++) {
            if (c > 0)
                values.append(",");

            values.append(genCntrVal());
        }
        values.append("</r>\n");
        writeToFile(values.toString());

        numPdfCounters++;
        numPdfValues += maxRange;
    }

    // This method returns the value of each counter
    // This method returns the value 100+Passed value
    // or the random number depending on configuration
    void writeValue() throws Exception {
        writeToFile("<r>" + genCntrVal() + "</r>\n");
        numSingleValueCounters++;
    }

    // This method writes to the output file
    // This method takes the input string and
    // writes to the file
    void writeToFile(String input) throws Exception {
        out_.write(input);
    }

    // This method generates the templateFile
    void generateTemplate() throws Exception {
        // Open the outputfile
        out_ = new OutputStreamWriter(new FileOutputStream(outputFile_));
        out_.write(returnHeader());
        writeBody();
        out_.close();

        File outputFile = new File(outputFile_);
        long fileSize = outputFile.length();
        String fileSizeStr = String.valueOf(((fileSize + 512) / 1024)) + " KB";

        System.out.println("\nTemplate File is generated for " + ": \n"
                + outputFile_ + " " + fileSizeStr
                + "\n~~~~~~~~~~~~~~~~~~~~");
    }

    public static void main(String[] args) {
        try {
            Options options = new Options();
            options.addOption("mom", true, "Input MOM XML file");
            options.addOption("cfg", true, "Input counter config file");
            options.addOption("out", true, "Output template file");
            options.addOption("prop", true, "[Output counter properties file]");
            options.addOption("trace", true, "[Trace level]");
            options.addOption("opts", true, "[Counter options file]");

            CommandLineParser parser = new GnuParser();
            try {
                CommandLine line = parser.parse(options, args);

                String traceLevel = line.getOptionValue("trace", "WARNING");
                String momXML = line.getOptionValue("mom");
                String cfgFile = line.getOptionValue("cfg");
                String outFile = line.getOptionValue("out");
                String cntrInfo = line.getOptionValue("prop");
                String optsFile = line.getOptionValue("opts");

                if (momXML == null || cfgFile == null || outFile == null) {
                    HelpFormatter formatter = new HelpFormatter();
                    formatter.printHelp("xmlgen", options);
                    System.exit(1);
                }

                Level logLevel = Level.parse(traceLevel);
                Logger xmlgenRoot = Logger.getLogger("xmlgen");
                xmlgenRoot.setLevel(logLevel);

                ConsoleHandler myHandler = new ConsoleHandler();
                myHandler.setLevel(logLevel);
                myHandler.setFormatter(new MyLogFormatter());
                xmlgenRoot.addHandler(myHandler);

                TemplateGen tGen = new TemplateGen(momXML, cfgFile, outFile,
                        cntrInfo, optsFile);

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

        // ("RNC",System.getProperties().getProperty("user.dir") +
        // "/RNC/rnc_x_all.xml",System.getProperties().getProperty("user.dir") +
        // "/output/RNC_Config.txt");
        // ("RNC","rnc_x_all.xml","RNC_Config_r3FULL.txt","SubNetwork=NRO_RootMo_R,SubNetwork=Rnc01Small,MeContext=Rnc01Small","Rnc01Small");
    }

    class MoCfg {
        public final String type;
        public final int instCount;
        public final List activeCntrs;
        public final Map cntrOpts;

        public MoCfg(String type, int instCount, List activeCntrs, Map cntrOpts) {
            this.type = type;
            this.instCount = instCount;
            this.activeCntrs = activeCntrs;
            this.cntrOpts = cntrOpts;
        }
    }
}