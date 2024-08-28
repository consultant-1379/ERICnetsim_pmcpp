/*
 * MeasurementType : Data holder to store the information fetched from MOC CFG file i.e <NE Type>_<NE VER>.cfg 
 * 
 */

package ecim.stats.data;



public class MocCfgDataHolder {
	
	private String mocName;
	private long numOfInstance;
	
	
	/**
	 * Constructor
	 * @param mocName
	 * @param numOfInstance
	 */
	public MocCfgDataHolder(String mocName, long numOfInstance) {
		super();
		this.mocName = mocName;
		this.numOfInstance = numOfInstance;
		
	}
	
	
	
	/**
	 * THis method returns measurement class/Counter group name
	 * @return : MOC Name
	 */
	public String getMocName() {
		return mocName;
	}
	

	/**
	 * THis method sets measurement class/Counter group name
	 * 
	 */
	public void setMocName(String mocName) {
		this.mocName = mocName;
	}
	
	
	/**
	 * THis method returns number of instances
	 * @return : Number of MOC instances
	 */
	public long getNumOfInstance() {
		return numOfInstance;
	}
	
	
	/**
	 * THis set value of number of MOC instances
	 */
	public void setNumOfInstance(int numOfInstance) {
		this.numOfInstance = numOfInstance;
	}
		
}
