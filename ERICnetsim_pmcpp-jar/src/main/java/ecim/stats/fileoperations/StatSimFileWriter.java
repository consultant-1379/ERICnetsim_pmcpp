/*
 * This Class responsible for writing required files such as
 * 1) Moc instances config,
 * 2) Coutner property, 
 * 3) Templete/stats xml file.
 */

package ecim.stats.fileoperations;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.math.BigInteger;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Random;
import java.util.Set;
import java.util.Stack;
import java.util.TimeZone;
import ecim.stats.data.EcimStatsConstant;
import ecim.stats.data.MeasValueType;
import ecim.stats.data.MeasurementType;
import ecim.stats.data.MocCfgDataHolder;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.datatype.DatatypeFactory;
import javax.xml.datatype.Duration;
import javax.xml.datatype.XMLGregorianCalendar;
import org._3gpp.ftp.specs.archive._32_series._32.*;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.FileFooter;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.FileHeader;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.FileHeader.FileSender;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.MeasData;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.MeasData.ManagedElement;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.MeasData.MeasInfo;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.MeasData.MeasInfo.GranPeriod;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.MeasData.MeasInfo.Job;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.MeasData.MeasInfo.MeasType;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.MeasData.MeasInfo.MeasValue;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.MeasData.MeasInfo.MeasValue.R;
import org._3gpp.ftp.specs.archive._32_series._32.MeasCollecFile.MeasData.MeasInfo.RepPeriod;

/**
 * Class responsible for writing required files moc instances config, coutner property, templete/stats xml file.
 */
public class StatSimFileWriter {


 /**
  * This responsible for writing the moc instance configuration file.
  * @param moClassList
  * @param fileName
  * @param instanceVal
  */
    public  void writeCFGFile(final Set<String> moClassSet,
            final String fileName, final int instanceVal) {
        try {
            /**
             * NodeBLocalCell,1
             * EthernetPort,1
             * Ikev2Session,1
             */
            BufferedWriter bw = new BufferedWriter(new FileWriter(fileName));


            for (String moClassName : getSortedList(moClassSet)) {
                bw.write(moClassName + EcimStatsConstant.CFG_TOKEN_SEP
                     + instanceVal
                        + EcimStatsConstant.LINE_SEPERATOR);
            }

            bw.close();
            System.out.println(fileName + " file successfully created");
        } catch (IOException ie) {
            ie.printStackTrace();
        } catch (Exception ex) {
            ex.printStackTrace();
        }

    }

    /**
      * This responsible for writing the moc instance configuration file.
      * @param moClassList
      * @param fileName
      * @param instanceVal
     * @throws IOException
      */
        public  void writeMimCFGFile(final Map<String,String> pmGroupToMimMap,
            final String fileName, final int instanceVal) {

        List<Map.Entry<String, String>> list = new LinkedList<Map.Entry<String, String>>(
                pmGroupToMimMap.entrySet());
        Collections.sort(list, new Comparator<Map.Entry<String, String>>() {

            @Override
            public int compare(Entry<String, String> o1,
                    Entry<String, String> o2) {
                return o1.getValue().compareTo(o2.getValue());

            }
        });

        try {
            BufferedWriter bw = new BufferedWriter(new

            FileWriter(fileName));
            for (Map.Entry<String, String> entry : list) {
                bw.write(entry.getKey().trim()
                        + EcimStatsConstant.CFG_TOKEN_SEP + instanceVal
                        + EcimStatsConstant.CFG_TOKEN_SEP
                        + entry.getValue().trim()
                        + EcimStatsConstant.LINE_SEPERATOR);
            }
            bw.close();
            System.out.println(fileName + " file successfully created");
        } catch (IOException e1) { // TODO Auto-generated catch block
            e1.printStackTrace();
        }

    }

    /**
     * The method sorts the give set and returns the sorted list
     * @param set
     * @return sort List
     */
    public static List<String> getSortedList(Set<String> set)
    {
        List<String> list = new LinkedList<String>(set);
        Collections.sort(list);
        return list;
    }

    /**
     * This method is responsible for writing template/original stats xml file.
     * Using JAXB consturt the Measurement collection file object and writes
     * the same to tempalte file
     *
     * @param mocClassToMeasTypes
     * @param fileName
     */
    public static void writeTemplateFile(
            final Map<String, List<MeasurementType>> mocClassToMeasTypes,
            final String fileName,Map<String,MocCfgDataHolder> mocCfgData,Map<String,String> mocRealtions ,final String nodeType, Map<String,String> mocNameMapToPmGroupId, String node_type) {
        /*
         *Create a object factory which is responsible for creation of object which represents the xml structure. 
         */
        ObjectFactory factory = new ObjectFactory();

        /*
         * Create measCollecFile object which holds all other xml tag objects
         */
        MeasCollecFile measCollecFile = factory.createMeasCollecFile();
        FileHeader fileHeader = factory.createMeasCollecFileFileHeader();

        /*
         * Fill the required attributes in the fileHeader
         */
        fileHeader.setFileFormatVersion("32.435 V10.0");
        fileHeader.setVendorName("Ericsson AB");
        fileHeader.setDnPrefix("dnPrefix");

        FileSender fileSender = factory
                .createMeasCollecFileFileHeaderFileSender();

        fileSender.setLocalDn("ManagedElement=1");
        fileSender.setElementType(nodeType);
        fileHeader.setFileSender(fileSender);
        FileHeader.MeasCollec measCollec = factory
                .createMeasCollecFileFileHeaderMeasCollec();

        measCollec.setBeginTime(getXMLGregorianCalendar());

        fileHeader.setMeasCollec(measCollec);

        MeasData measData = factory.createMeasCollecFileMeasData();
        ManagedElement me = factory
                .createMeasCollecFileMeasDataManagedElement();
        measData.setManagedElement(me);
        me.setLocalDn("ManagedElement=1");
        me.setSwVersion("r0.1");

            for (String moClassName : getSortedList(mocClassToMeasTypes.keySet())) {

            if (mocCfgData.containsKey(moClassName)) {
                MeasInfo measInfo = factory.createMeasCollecFileMeasDataMeasInfo();
                String pmGroupId = mocNameMapToPmGroupId.get(moClassName);
                if (pmGroupId != null) {
                    measInfo.setMeasInfoId(pmGroupId);
                }else
                {
                    measInfo.setMeasInfoId(moClassName);
                }

                if ((node_type.equalsIgnoreCase("vpp")) || (node_type.equalsIgnoreCase("vrm"))) {
                    measInfo.setMeasInfoId("PM=1,PmGroup=" + measInfo.getMeasInfoId());
                }

                Job job = factory.createMeasCollecFileMeasDataMeasInfoJob();
                job.setJobId("1_USERDEF.ALL_COUNTERS.Profile_1.Continuous_Y.MEASJOB");
                GranPeriod granP = factory
                        .createMeasCollecFileMeasDataMeasInfoGranPeriod();
                granP.setDuration(getDuration());
                granP.setEndTime(getXMLGregorianCalendar());

                RepPeriod ropP = factory.createMeasCollecFileMeasDataMeasInfoRepPeriod();
                ropP.setDuration(getDuration());
                measInfo.setGranPeriod(granP);
                measInfo.setRepPeriod(ropP);
                measInfo.setJob(job);
                List<MeasurementType> measList = mocClassToMeasTypes
                        .get(moClassName);
                long index = 1;
                for (MeasurementType meas : measList) {
                    MeasType measType = factory
                            .createMeasCollecFileMeasDataMeasInfoMeasType();
                    measType.setP(BigInteger.valueOf(index));
                    measType.setValue(meas.getMeasId());
                    index++;
                    measInfo.getMeasType().add(measType);
                }


                long instanceVal = mocCfgData.get(moClassName)
                        .getNumOfInstance();

                for (long val = 1; val <= instanceVal; val++) {

                    MeasValue measValue = factory
                            .createMeasCollecFileMeasDataMeasInfoMeasValue();
                    String parentDn = "";
                    if(!"EUtranCellTDD".equalsIgnoreCase(measInfo.getMeasInfoId())){
                        parentDn = getMeasObjLdn(moClassName, mocRealtions).replace("TDD", "FDD");
                    }else{
                        parentDn = getMeasObjLdn(moClassName, mocRealtions).replace("FDD", "TDD");
                    }
                    measValue.setMeasObjLdn(parentDn + EcimStatsConstant.MOID_INT_SEP +val);
                    index=1;
                    for (MeasurementType meas : measList) {
                        R r = factory
                                .createMeasCollecFileMeasDataMeasInfoMeasValueR();

                        r.setP(BigInteger.valueOf(index++));
                        StringBuilder measVal=new StringBuilder("");
                        if( meas.getMeasValueType() == MeasValueType.MULTI_VALUE) {
                            for(int i=0; i < meas.getMultiplicity()-1; i++) {
                                measVal.append(Long.toString(Math.abs(new Random()
                                .nextLong() % 100))).append(EcimStatsConstant.MEAS_VAL_SEP);
                            }
                        }
                        measVal.append(Long.toString(Math.abs(new Random()
                            .nextLong() % 100)));
                        r.setValue(measVal.toString());
                        measValue.getR().add(r);
                    }

                    measValue.setSuspect(false);
                    measInfo.getMeasValue().add(measValue);
                }
                if(instanceVal > 0){
                    measData.getMeasInfo().add(measInfo);
                }
            }
        }

        measCollecFile.getMeasData().add(measData);
        measCollecFile.setFileHeader(fileHeader);
        FileFooter fileFooter = factory.createMeasCollecFileFileFooter();
        FileFooter.MeasCollec mc = factory
                .createMeasCollecFileFileFooterMeasCollec();


        mc.setEndTime(getXMLGregorianCalendar());
        fileFooter.setMeasCollec(mc);
        measCollecFile.setFileFooter(fileFooter);
        /*
         * Write measCollecFile object to file
         */
        try {
            JAXBContext jc = JAXBContext
                    .newInstance("org._3gpp.ftp.specs.archive._32_series._32");

            Marshaller marshaller = jc.createMarshaller();

            marshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT,
                    Boolean.TRUE);
            marshaller.setProperty("com.sun.xml.internal.bind.xmlDeclaration",
                    Boolean.FALSE);
            final PrintStream outPutFile = new PrintStream(fileName);
            outPutFile.println("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
            outPutFile
                    .print("<?xml-stylesheet type=\"text/xsl\" href=\"MeasDataCollection.xsl\"?>");

            marshaller.marshal(measCollecFile, outPutFile);
            outPutFile.close();
            System.out.println(fileName + " file successfully created");
        } catch (JAXBException je) {
            // TODO Auto-generated catch block
            je.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    /**
     * This method constructs and returns the measObjLdn ID
     * @param moClassName
     * @param mocRealtions
     * @return measObjLdn ID
     */
    private static String getMeasObjLdn(String moClassName,
            Map<String, String> mocRealtions) {

        StringBuilder moid = new StringBuilder(EcimStatsConstant.MANAGED_ELEMENT).append(EcimStatsConstant.MOID_INT_SEP).append(EcimStatsConstant.PARENT_MOC_INS_VAL).append(EcimStatsConstant.MOID_MOC_SEP);
        Stack<String> mocHierarchy = new Stack<String>();
        String currentParent = mocRealtions.get(moClassName);;
        while(currentParent != null) {
            mocHierarchy.push(currentParent);
            currentParent = mocRealtions.get(currentParent);
        }

        int size = mocHierarchy.size();
        int i=0;
        while (i<size) {
            String moc = mocHierarchy.pop();
            moid.append(moc).append(EcimStatsConstant.MOID_INT_SEP).append(EcimStatsConstant.PARENT_MOC_INS_VAL).append(EcimStatsConstant.MOID_MOC_SEP);
            i++;
        }
        return moid.append(moClassName).toString();
    }


    /**
     * Returns Duration object with value as O seconds
     * @return Duration
     */
    private static Duration getDuration() {
        Duration dur = null;
        try {
            dur = DatatypeFactory.newInstance().newDuration(0);

        } catch (Exception e) {
            e.printStackTrace();
        }
        return dur;
    }


    /**
     * Returns XMLGregorianCalendar object with epic start date in UTC
     * @return XMLGregorianCalendar
     */
    private static XMLGregorianCalendar getXMLGregorianCalendar() {
        XMLGregorianCalendar cal = null;
         GregorianCalendar gCalendar = new GregorianCalendar();
         gCalendar.setTimeZone(TimeZone.getTimeZone("UTC"));
         gCalendar.setTime(new Date(0));
        try {
            cal = DatatypeFactory.newInstance().newXMLGregorianCalendar(gCalendar);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return cal;
    }



    /**
     * This method is responsible for writing measurement property file
     * @param mocClassToMeasTypes
     * @param fileName
     */
    public static void writeMeasPropFile(
            final Map<String, List<MeasurementType>> mocClassToMeasTypes,
            final String fileName) {
        try {
            /*
             * Example of the content in the file
             *
             * NodeBLocalCell,pmAverageRssi,RESET,SINGLE_VALUE
             * EthernetPort,pmIfHCOutOctets,RESET,SINGLE_VALUE
             * EthernetPort,pmIfOutDiscards,RESET,SINGLE_VALUE

             */
            BufferedWriter bw = new BufferedWriter(new FileWriter(fileName));


            for (String moClassName : mocClassToMeasTypes.keySet()) {

                List<MeasurementType> measList = mocClassToMeasTypes
                        .get(moClassName);

                for (MeasurementType meas : measList) {
                    String isCompressed = "UNCOMPRESSED";
                    if(meas.isCompressed()){
                        isCompressed = "COMPRESSED";
                    }
                    bw.write(moClassName + ""
                            + EcimStatsConstant.CNT_PROP_TOKEN_SEP + ""
                            + meas.getMeasName() + ""
                            + EcimStatsConstant.CNT_PROP_TOKEN_SEP + ""
                            + meas.getMeasResetType() + ""
                            + EcimStatsConstant.CNT_PROP_TOKEN_SEP + ""
                            + meas.getMeasValueType()
                            + EcimStatsConstant.CNT_PROP_TOKEN_SEP + ""
                            + isCompressed
                            + EcimStatsConstant.LINE_SEPERATOR);
                }
            }

            bw.close();
            System.out.println(fileName + " file successfully created");
        } catch (IOException ie) {
            ie.printStackTrace();
        } catch (Exception ex) {
            ex.printStackTrace();
        }

    }
}
