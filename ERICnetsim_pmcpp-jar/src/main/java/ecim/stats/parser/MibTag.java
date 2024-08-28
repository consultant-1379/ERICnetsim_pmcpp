/*
 * MibTag : Defines MIB XML tags
 * 
 */

package ecim.stats.parser;

public enum MibTag {
	
	OBJECT,SLOT,HASCLASS,VALUE,RELATIONSHIP,NODETYPE,MIB;	
	
	public static MibTag getTag(final String tagName)
	{
		MibTag tag = null;
		try
		{
	    	tag = MibTag.valueOf(tagName.toUpperCase());
		}
		catch(Exception e)
		{
			
		}
		
		return tag;
	}
}
