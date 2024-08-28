/**
 * This class represents the enum for slot types defined in the  MIB file
 */

package ecim.stats.parser;

public enum SlotType {

    PMGROUPID, MOCLASSNAME, MEASUREMENTNAME, MEASUREMENTTYPEID, MEASUREMENTRESULT, MULTIPLICITY, RESETATGRANPERIOD, MIMNAME, ISCOMPRESSED;

    public static SlotType getSlot(final String name) {
        SlotType tag = null;
        try {
            tag = SlotType.valueOf(name.toUpperCase());
        } catch (Exception e) {
        }

        return tag;
    }
}