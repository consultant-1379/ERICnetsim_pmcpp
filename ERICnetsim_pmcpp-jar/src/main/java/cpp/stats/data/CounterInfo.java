package cpp.stats.data;

import java.util.logging.Logger;

public class CounterInfo implements Comparable {
    private static Logger m_Log = Logger.getLogger("xmlgen.CounterInfo");

    public final static int UNKNOWN = -1;

    public final static int SINGLE_VALUE = 1;
    public final static int MULTI_VALUE = 2;

    public final static int MONOTONIC = 1;
    public final static int RESET = 2;

    public final String name;
    public final int type;
    public final int behaviour;
    public final int pdfValues;
    private boolean compressedCounter;

    public CounterInfo(String name, int type, int behaviour, int pdfValues, boolean compressedCounter) {
        this.name = name;
        this.type = type;
        this.behaviour = behaviour;
        this.pdfValues = pdfValues;
        this.compressedCounter = compressedCounter;
        if ((this.pdfValues != 0 && type != MULTI_VALUE) || (this.pdfValues == 0 && type == MULTI_VALUE)) {
            m_Log.warning("CounterInfo inconsistent info for " + name + ": type=" + getTypeName(type) + ", pdfValues=" + pdfValues);
        }
    }

    @Override
    public String toString() {
        return name + "(type=" + getTypeName(type) + " behaviour=" + getBehaviourName(behaviour) + " pdfValues=" + String.valueOf(pdfValues) + ")";
    }

    public static String getBehaviourName(int aBehaviour) {
        if (aBehaviour == RESET) {
            return "RESET";
        } else if (aBehaviour == MONOTONIC) {
            return "MONOTONIC";
        } else {
            return "UNKNOWN";
        }
    }

    public static String getTypeName(int aType) {
        if (aType == MULTI_VALUE) {
            return "MULTI_VALUE";
        } else if (aType == SINGLE_VALUE) {
            return "SINGLE_VALUE";
        } else {
            return "UNKNOWN[" + String.valueOf(aType) + "]";
        }
    }

    public static int parseBehaviour(String casebStr) {
        if (casebStr == null) {
            return UNKNOWN;
        }

        String bStr = casebStr.toUpperCase();
        if (bStr.equals("TRUE")) {
            return RESET;
        } else if (bStr.equals("FALSE")) {
            return MONOTONIC;
        } else if (bStr.equals("YES")) {
            return RESET;
        } else if (bStr.equals("NO")) {
            return MONOTONIC;
        } else {
            m_Log.warning("parseBehaviour Unknown behaviour: " + casebStr);
            return UNKNOWN;
        }
    }

    public static int parseCounterType(String caseTypeStr) {

        if (caseTypeStr == null) {
            return UNKNOWN;
        }

        String typeStr = caseTypeStr.toUpperCase();
        if (typeStr.equals("PDF") || typeStr.equals("DDM")) {
            return MULTI_VALUE;
        } else {
            return SINGLE_VALUE;
        }
    }

    @Override
    public int compareTo(Object otherObj) {
        return name.compareTo(((CounterInfo) otherObj).name);
    }

    public boolean isCompressedCounter() {
        return compressedCounter;
    }

    public void setCompressedCounter(boolean compressedCounter) {
        this.compressedCounter = compressedCounter;
    }

}