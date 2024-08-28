package cpp.stats.parser;

/*
 */
import java.io.*;
import java.util.*;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.parsers.*;

import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler;

import cpp.stats.data.CounterInfo;

public class CounterReader extends DefaultHandler {
    private static Logger m_Log = Logger.getLogger("xmlgen.CounterReader");

    // static private String className_;

    private final String momFile_;

    Map counterMap = new HashMap();

    private static final int IDLE = 0;
    private static final int CLASS = 1;
    private static final int COUNTER = 2;
    private static final int DESCRIPTION = 3;
    private static final int SEQUENCE = 4;
    private static final int MAX_LENGTH = 5;
    private static final int COUNTER_TYPE = 6;
    private static final int COUNTER_RESET = 7;

    private int m_State = IDLE;

    // Variables used while parsing the MOM
    private String currentClass = null;
    private List counterList = null;

    private String m_CurrCntr;
    private String m_DescStr;
    private String m_MaxLengthStr;
    private boolean m_IsPdf;

    private String m_counterType;
    private String m_counterReset;

    // Added for handling compressed vector field.
    private boolean m_counterCompressed;
    // Patterns used to extract info from the description
    Pattern counterTypePat = Pattern.compile("Counter type:\\s*(\\S+)", Pattern.CASE_INSENSITIVE);
    Pattern counterResetPat = Pattern.compile("Counter is reset after measurement \\S+:\\s*(\\S+)", Pattern.CASE_INSENSITIVE);

    // Public Constructor the MOM XML File needs to be passed
    public CounterReader(String momFile) {
        // System.out.println("In Constructor");
        momFile_ = momFile;
        initReader();
    }

    public Map getCounterMap() {
        return Collections.unmodifiableMap(counterMap);
    }

    // This method returns the vector containing the counterNames
    // for the given class name
    Vector returnCounters(String className) {
        List cntrList = (List) counterMap.get(className);
        if (cntrList == null) {
            return null;
        }

        Vector vec = new Vector();
        for (Iterator itr = cntrList.iterator(); itr.hasNext();) {
            vec.add(((CounterInfo) itr.next()).name);
        }

        Collections.sort(vec);

        return vec;
    }

    @Override
    public void startElement(String namespaceURI, String sName, String qName, Attributes attrs) throws SAXException {
        m_Log.finest("qName=" + qName + " m_State=" + m_State);

        switch (m_State) {
            case IDLE: {
                if (qName.equals("class")) {
                    currentClass = attrs.getValue(0);
                    m_Log.fine("found class " + currentClass);
                    m_State = CLASS;
                    counterList = new LinkedList();
                }
                break;
            }

            case CLASS: {
                if (qName.equals("attribute")) {
                    String attribName = attrs.getValue(0);
                    m_Log.finer("attribName=" + attribName);

                    // Biggest assumption here, all the counters start with
                    // pm as the suffix
                    if (attribName.startsWith(new String("pm"))) {
                        m_Log.fine("found counter " + attribName);

                        m_State = COUNTER;
                        m_CurrCntr = attribName;

                        m_counterType = null;
                        m_counterReset = null;

                        // Initialise the fields for PDF counter info
                        m_IsPdf = false;
                        m_DescStr = null;
                        m_MaxLengthStr = null;
                        m_counterCompressed = false;
                    }
                }
                break;
            }

            case COUNTER: {
                if (qName.equals("description")) {
                    m_State = DESCRIPTION;
                    m_DescStr = "";
                } else if (qName.equals("sequence")) {
                    m_State = SEQUENCE;
                    m_IsPdf = true;
                } else if (qName.equals("counterType")) {
                    m_State = COUNTER_TYPE;
                    m_counterType = "";
                } else if (qName.equals("counterReset")) {
                    m_State = COUNTER_RESET;
                    m_counterReset = "";
                }
                break;
            }

            case SEQUENCE: {
                if (qName.equals("maxLength")) {
                    m_State = MAX_LENGTH;
                    m_IsPdf = true;
                    m_MaxLengthStr = "";
                }
                break;
            }
        }
    }

    @Override
    public void endElement(String namespaceURI, String sName, String qName) throws SAXException {
        m_Log.finest("qName=" + qName + " m_State=" + m_State);

        switch (m_State) {
            case CLASS: {
                if (qName.equals("class")) {
                    m_State = IDLE;

                    m_Log.info("end " + currentClass + " counters=" + counterList);

                    if ((counterList.size() > 0) && (currentClass != null)) {
                        counterMap.put(currentClass, counterList);
                    }

                    counterList = null;
                    currentClass = null;
                }
                break;
            }

            case COUNTER: {
                if (qName.equals("attribute")) {
                    m_State = CLASS;

                    String counterType = null;
                    String counterReset = null;

                    if (m_counterType != null && m_counterType.length() > 0) {
                        counterType = m_counterType;
                    }

                    if (m_counterReset != null && m_counterReset.length() > 0) {
                        counterReset = m_counterReset;
                    }

                    if (counterType == null || counterReset == null ) {
                        if (m_DescStr == null) {
                            m_Log.warning("No description tag for " + m_CurrCntr);
                        } else {
                            if (counterType == null) {
                                counterType = match(m_DescStr, counterTypePat);
                            }
                            if (counterReset == null) {
                                counterReset = match(m_DescStr, counterResetPat);
                            }
                            if (counterReset == null || counterType == null) {
                                m_Log.fine("endElement cannot extract counter info for " + m_CurrCntr + " from " + m_DescStr);
                            }
                        }
                    }
                    if(!m_counterCompressed && null != m_DescStr){
                        if (m_DescStr.toLowerCase().contains("compressed: true") || m_DescStr.toLowerCase().contains("compressed pdf")) {
                            m_counterCompressed = true;
                        } else {
                            m_counterCompressed = false;
                        }
                    }
                    m_Log.fine(currentClass + "." + m_CurrCntr + " isPdf=" + m_IsPdf + " counterType=" + counterType + " counterReset="
                            + counterReset);
                    int numPdfValue = 0;
                    if (m_IsPdf) {
                        if (m_MaxLengthStr != null) {
                            m_Log.fine(currentClass + "." + m_CurrCntr + " using maxLength=" + m_MaxLengthStr);
                            numPdfValue = Integer.parseInt(m_MaxLengthStr);
                        } else {
                            m_Log.fine(currentClass + "." + m_CurrCntr + " using description=" + m_DescStr);
                            numPdfValue = extractMaxRange(m_DescStr);
                        }
                    }

                    int counterTypeNum = CounterInfo.parseCounterType(counterType);
                    if (counterTypeNum == CounterInfo.UNKNOWN && m_IsPdf) {
                        counterTypeNum = CounterInfo.MULTI_VALUE;
                    }

                    int behaviour = CounterInfo.parseBehaviour(counterReset);

                    counterList.add(new CounterInfo(m_CurrCntr, counterTypeNum, behaviour, numPdfValue, m_counterCompressed));
                }
                break;
            }

            case DESCRIPTION: {
                if (qName.equals("description")) {
                    m_State = COUNTER;
                }
                break;
            }

            case SEQUENCE: {
                if (qName.equals("sequence")) {
                    m_State = COUNTER;
                }
                break;
            }

            case MAX_LENGTH: {
                if (qName.equals("maxLength")) {
                    m_State = SEQUENCE;
                }
                break;
            }

            case COUNTER_TYPE: {
                if (qName.equals("counterType")) {
                    m_State = COUNTER;
                }
                break;
            }

            case COUNTER_RESET: {
                if (qName.equals("counterReset")) {
                    m_State = COUNTER;
                }
                break;
            }
        }
    }

    // Extracts the max range of a PDF counter from its description in the MOM
    private int extractMaxRange(String desc) {
        int max = -1;

        StringTokenizer sToken = new StringTokenizer(desc, "[]");

        while (sToken.hasMoreTokens()) {
            String thisToken = sToken.nextToken().trim();
            int tempVal = extract(thisToken);
            if (tempVal != -99) { // -99 is used as a flag to signify a non-int
                                  // token
                max = tempVal + 1;
            }
        }
        return max;
    }

    // Returns the integer contained within the string s
    private int extract(String s) {

        try {
            int j = s.length() - 1;
            while (j >= 0 && Character.isDigit(s.charAt(j))) {
                j--;
            }

            boolean containsDot = s.indexOf(".") != -1;

            if (!containsDot) { // if there is no dot in the string
                int value = Integer.parseInt(s.substring(j + 1, s.length()));
                // System.out.println("RETURNING: " + value);
                // System.out.println("containsDot: " + containsDot);
                if (value == 0) {
                    value = -99;
                }
                return value;
            }

        } catch (Exception e) {
            // e.printStackTrace();
            // do nothing
        }
        // -99 is used as a flag to signify a non-int token
        return -99;
    }

    @Override
    public void characters(char buf[], int offset, int len) throws SAXException {
        if (m_State == MAX_LENGTH) {
            m_MaxLengthStr = m_MaxLengthStr + new String(buf, offset, len);
        } else if (m_State == DESCRIPTION) {
            m_DescStr = m_DescStr + new String(buf, offset, len);
        } else if (m_State == COUNTER_TYPE) {
            m_counterType = m_counterType + new String(buf, offset, len);
        } else if (m_State == COUNTER_RESET) {
            m_counterReset = m_counterReset + new String(buf, offset, len);
        }
    }

    @Override
    public void endDocument() throws SAXException {
    }

    void initReader() {
        // use an instance of ourselves as the SAX event handler
        DefaultHandler handler = this;

        // use the default (non-validating) parser
        SAXParserFactory factory = SAXParserFactory.newInstance();
        factory.setValidating(false);

        try {

            SAXParser saxParser = factory.newSAXParser();
            saxParser.parse(new File(momFile_), handler);
        } catch (SAXParseException spe) {
            // Error generated by the parser
            System.out.println("\n** Parsing error" + ", line " + spe.getLineNumber() + ", uri " + spe.getSystemId());
            System.out.println("   " + spe.getMessage());

            // Use the contained exception, if any
            Exception x = spe;
            if (spe.getException() != null) {
                x = spe.getException();
            }
            x.printStackTrace();

        } catch (SAXException sxe) {
            // Error generated by this application
            // (or a parser-initialization error)
            Exception x = sxe;
            if (sxe.getException() != null) {
                x = sxe.getException();
            }
            x.printStackTrace();

        } catch (ParserConfigurationException pce) {
            // Parser with specified options can't be built
            pce.printStackTrace();

        } catch (IOException ioe) {
            // I/O error
            ioe.printStackTrace();
        }
    }

    private String match(String str, Pattern pat) {
        m_Log.finest("match pat=" + pat + " str=" + str);

        try {
            Matcher matcher = pat.matcher(str);
            if (matcher.find()) {
                return matcher.group(1);
            } else {
                return null;
            }
        } catch (IllegalStateException ise) {
            m_Log.throwing("CounterReader", "match", ise);
            return null;
        }
    }

    @Override
    public InputSource resolveEntity(String publicId, String systemId) {
        return new InputSource(new ByteArrayInputStream(new byte[0]));
    }

}

