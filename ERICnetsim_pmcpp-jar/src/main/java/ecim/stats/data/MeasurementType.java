/*
 * MeasurementType : Data holder to store the Measurement/Counter information.
 *
 */

package ecim.stats.data;

public class MeasurementType {

    private String measName;
    private final String measId;
    private MeasResetType measResetType;
    private MeasValueType measValueType;
    private String pmGroupId;
    private int multiplicity;
    private boolean isCompressed;

    public MeasurementType(final String measName, final String measId, MeasResetType measResetType, MeasValueType measValueType, String pmGroupId,
                           int multiplicity, boolean isCompressed) {
        super();
        this.measName = measName;
        this.measId = measId;
        this.measResetType = measResetType;
        this.measValueType = measValueType;
        this.pmGroupId = pmGroupId;
        this.multiplicity = multiplicity;
        this.isCompressed = isCompressed;
    }

    public String getMeasName() {
        return measName;
    }

    public String getMeasId() {
        return measId;
    }

    public void setMeasName(String measName) {
        this.measName = measName;
    }

    public MeasResetType getMeasResetType() {
        return measResetType;
    }

    public void setMeasResetType(MeasResetType measResetType) {
        this.measResetType = measResetType;
    }

    public MeasValueType getMeasValueType() {
        return measValueType;
    }

    public void setMeasValueType(MeasValueType measValueType) {
        this.measValueType = measValueType;
    }

    public String getPmGroupId() {
        return pmGroupId;
    }

    public void setPmGroupId(String pmGroupId) {
        this.pmGroupId = pmGroupId;
    }

    public int getMultiplicity() {
        return multiplicity;
    }

    public void setMultiplicity(int multiplicity) {
        this.multiplicity = multiplicity;
    }

    public boolean isCompressed() {
        return isCompressed;
    }

    public void setCompressed(boolean isCompressed) {
        this.isCompressed = isCompressed;
    }
}