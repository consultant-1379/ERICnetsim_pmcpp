/*
 * This Class responsible for parsing and caching data from MIB files such counter groups and corresponding counter information
 * 
 */

package ecim.stats.parser;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.LinkedList;
import java.util.Map;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import ecim.stats.data.MeasResetType;
import ecim.stats.data.MeasValueType;
import ecim.stats.data.MeasurementType;

public class MibFileReader extends DefaultHandler {

    public MibFileReader() {
        // TODO Auto-generated constructor stub
    }

    static String inputFile;

    private String parentDn;

    private String moClassName;

    private String hasClass;

    private String pmGroupId;

    private String mimName;

    private boolean isPmGroup;

    private boolean isMeasType;

    private String measName;

    private String measId;

    @SuppressWarnings("unused")
	private String measResult;

    private String multiplicity;

    private String slotName;

    private SlotType currentSlot;

    private String restAtGranPeriod;

    private String isCompressed;

    /**
     * To store counter group id to counter group name
     */
    Map<String, String> pmGroupIdToMocNameMap = new HashMap<String, String>();

    /**
     * To store moc name to pmGroup ID
     */
    Map<String, String> mocNameToPmGroupIdMap = new HashMap<String, String>();

    /**
     * To store counter group id to counter group
     */
    Map<String, String> pmGroupToMIMNameMap = new HashMap<String, String>();

    /**
     * To store counter group id to corresponding counters
     */
    Map<String, List<MeasurementType>> pmGroupIdToMeasTypesMap = new HashMap<String, List<MeasurementType>>();

    /**
     * To store counter group to corresponding counters
     */
    Map<String, List<MeasurementType>> moClassToMeasTypesMap = new HashMap<String, List<MeasurementType>>();

    /**
     * This method parses the inputFIle to fetchs the counter group and its
     * counter information
     *
     * @param inputFile
     */
    private void parse(final String inputFile) {

        try {

            SAXParserFactory spf = SAXParserFactory.newInstance();

            spf.setValidating(true);

            SAXParser parser = spf.newSAXParser();

            parser.parse(new File(inputFile), this);

        } catch (final ParserConfigurationException pce) {
            System.out.println("Cannot process " + inputFile + " Reason;"
                    + pce.getMessage());
        } catch (final SAXException saxe) {
            System.out.println("Cannot process " + inputFile + " Reason;"
                    + saxe.getMessage());
        } catch (final IOException ioe) {
            System.out.println("Cannot read " + inputFile + " Reason;"
                    + ioe.getMessage());
        }
    }

    @Override
    public InputSource resolveEntity(String publicId, String systemId) {
        return new InputSource(new ByteArrayInputStream(new byte[0]));
    }

    /**
     * Overridden method to fetch required info when xml start tag encountered
     */
    @Override
    public void startElement(final String uri, final String localName,
            final String qName, final Attributes attributes)
            throws SAXException {

        MibTag tag = MibTag.getTag(qName);

        if (tag != null) {
            switch (tag) {
            case OBJECT:

                resetAllFields();
                parentDn = attributes.getValue(MibConstants.PARENTDN_ATRR);
                break;

            case HASCLASS:
                hasClass = attributes.getValue(MibConstants.NAME_ATRR);
                if (hasClass.equals(MibConstants.PM_GROUP)) {
                    isPmGroup = true;
                } else if (hasClass.equals(MibConstants.MEAS_TYPE)) {
                    isMeasType = true;
                }
                break;

            case SLOT:
                slotName = attributes.getValue(MibConstants.NAME_ATRR);
                break;

            case VALUE:
                currentSlot = SlotType.getSlot(slotName);
                break;

            default:
            }
        }
    }

    /**
     * Overridden method to fetch required info when data encountered
     */
    @Override
    public void characters(char[] ch, int start, int length)
            throws SAXException {

        if (currentSlot != null) {
            switch (currentSlot) {
            case PMGROUPID:
                pmGroupId += new String(ch, start, length);
                break;

            case MIMNAME:
                mimName += new String(ch, start, length);
                break;

            case MOCLASSNAME:
                moClassName += new String(ch, start, length);
                break;

            case MEASUREMENTNAME:
                measName += new String(ch, start, length);
                break;

            case MEASUREMENTTYPEID:
                measId += new String(ch, start, length);
                break;

            case MEASUREMENTRESULT:
                measResult += new String(ch, start, length);
                break;

            case MULTIPLICITY:
                multiplicity += new String(ch, start, length);
                break;

            case RESETATGRANPERIOD:
                restAtGranPeriod += new String(ch, start, length);
                break;

            case ISCOMPRESSED:
                isCompressed += new String(ch, start, length);
                break;
            default:

            }
        }

    }

    /**
     * Overridden method to fetch required info when xml end tag encountered
     */

    @Override
    public void endElement(final String uri, final String localName,
            final String qName) throws SAXException {

        MibTag tag = MibTag.getTag(qName);
        if (tag != null) {
            switch (tag) {
            case OBJECT:

                if (isPmGroup) {
                    // System.out.println("pmGroupId"+pmGroupId
                    // +" :moclassName "+moClassName);
                    if (moClassName != null && !moClassName.isEmpty()) {
                        pmGroupIdToMocNameMap.put(pmGroupId.trim(),
                                moClassName.trim());

                        pmGroupToMIMNameMap.put(moClassName.trim(), mimName);
                    } else {
                        pmGroupIdToMocNameMap.put(pmGroupId.trim(),
                                pmGroupId.trim());
                        pmGroupToMIMNameMap.put(pmGroupId.trim(), mimName);
                    }

                } else if (isMeasType) {

                    MeasurementType meas = createMeasurementType();

                    if (meas != null) {
                        List<MeasurementType> measList = pmGroupIdToMeasTypesMap
                                .get(meas.getPmGroupId());
                        if (measList == null) {
                            measList = new LinkedList<MeasurementType>();
                            measList.add(meas);

                            pmGroupIdToMeasTypesMap.put(meas.getPmGroupId(),
                                    measList);
                            // System.out.println("pmGroupId"+meas.getPmGroupId()
                            // +" :List "+measList);
                        } else {
                            measList.add(meas);
                        }

                    }
                }

                break;

            case HASCLASS:
                break;

            case SLOT:
                break;

            case VALUE:
                break;
            default:
                break;
            }
        }
    }

    /**
     * This method creates MeasurementType from the fetched info from MIB xml
     * file
     *
     * @return MeasurementType
     */
    private MeasurementType createMeasurementType() {

        try {
            Boolean isRestAtGranPer = Boolean.valueOf(restAtGranPeriod.trim());
            Boolean compressed = Boolean.valueOf(isCompressed.trim());
            MeasResetType measResetType;
            if (isRestAtGranPer) {
                measResetType = MeasResetType.RESET;
            } else {
                measResetType = MeasResetType.MONOTONIC;
            }
            int multipli=1;
            if(!multiplicity.trim().isEmpty()){
                multipli = Integer.parseInt(multiplicity.trim());
            }

            MeasValueType measValueType;
            if (multipli > 1 && !measId.contains("pmFlex")) {
                measValueType = MeasValueType.MULTI_VALUE;
            } else {
                measValueType = MeasValueType.SINGLE_VALUE;

            }

            String pmGroupId = parentDn.trim().substring(
                    parentDn.lastIndexOf("=") + 1, parentDn.length());
            // System.out.println(pmGroupId);
            if (measName == null || measName.isEmpty()) {
                measName = measId;
            }


            return new MeasurementType(measName.trim(), measId.trim(),
                    measResetType, measValueType, pmGroupId.trim(), multipli,
                    compressed);
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * This method resets all the required instance values so next counter
     * groups values are correctly fetched
     */
    private void resetAllFields() {

        parentDn = "";

        moClassName = "";

        hasClass = "";

        pmGroupId = "";

        mimName = "";

        isPmGroup = false;

        isMeasType = false;

        measName = "";

        measId = "";

        measResult = "";

        multiplicity = "";

        slotName = "";

        currentSlot = null;

        restAtGranPeriod = "";

        isCompressed = "";

    }

    /**
     * This method will return the MO class and measurement type list associated
     * to it.
     */

    /**
     * This method will return the MO class and measurement type list associated
     * to it.
     *
     * @param fileList
     *            - List MIB files
     * @return Map MO class and measurement type list associated to it
     * @throws Exception
     */
    public Map<String, List<MeasurementType>> getMoClassDetails(
            final List<String> fileList) throws Exception {

        for (String file : fileList) {
            File xmlFile = new File(file);

            if (file == null || (!xmlFile.exists()) || (!xmlFile.isFile())
                    || (!xmlFile.canRead())) {

                System.out.println("Invalid file or No read permission");

            }

            inputFile = file;
            parse(file);

        }

        for (String pmGroupId : pmGroupIdToMeasTypesMap.keySet()) {
            String moClassName = pmGroupIdToMocNameMap.get(pmGroupId);
            if (moClassName != null) {
                moClassToMeasTypesMap.put(moClassName,
                        pmGroupIdToMeasTypesMap.get(pmGroupId));
                mocNameToPmGroupIdMap.put(moClassName, pmGroupId);
            }
        }

        return moClassToMeasTypesMap;
    }

    /**
     * This method returns MocNameMapToPmGroupIdMap
     *
     * @return mocNameToPmGroupIdMap
     */
    public Map<String, String> getMocNameToPmGroupIdMap() {
        return mocNameToPmGroupIdMap;
    }

    /**
     * This method returns the PmGroup to MIM name mapping
     *
     * @param fileList
     * @return
     * @throws Exception
     */
    public Map<String, String> getPmGroupToMimName(final List<String> fileList)
            throws Exception {

        for (String file : fileList) {
            File xmlFile = new File(file);

            if (file == null || (!xmlFile.exists()) || (!xmlFile.isFile())
                    || (!xmlFile.canRead())) {

                System.out.println("Invalid file or No read permission");

            }

            inputFile = file;
            parse(file);

        }

        return pmGroupToMIMNameMap;
    }
}
