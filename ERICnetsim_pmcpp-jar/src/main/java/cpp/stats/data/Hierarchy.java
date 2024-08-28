package cpp.stats.data;
/*
 */
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.util.Collections;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.helpers.DefaultHandler;

public class Hierarchy extends DefaultHandler {
	static private boolean relationFlag;
	static private boolean parentFlag;
	static private boolean childFlag;
	static private boolean cardinalityFlag;
	static private boolean minFlag;
	static private boolean maxFlag;

	static private Vector relationList;
    static private Vector sequenceList;
	static private Vector parentList;
	static private Vector childList;
	static private Vector minList;
	static private Vector maxList;
	static private Hashtable relationMap;
	static private Hashtable moidMap;
	static private Hashtable minmaxMap;

	static String currentParent;
	static String currentChild;
	static int currentMin;
	static int currentMax;

	static private String xmlFile_;

	public Hierarchy(String xmlFile)
	{
		xmlFile_ = xmlFile;
		relationFlag =false;
		parentFlag =false;
		childFlag =false;
		cardinalityFlag =false;
		minFlag =false;
		maxFlag =false;
		currentMin=-1;
		currentMax=-1;

		currentParent = "UNKNOWN";
		currentChild = "UNKNOWN";
		relationList = new Vector();
        sequenceList = new Vector();
		parentList = new Vector();
		childList = new Vector();
		minList = new Vector();
		maxList = new Vector();
	    relationMap = new Hashtable();
	    moidMap = new Hashtable();
	    minmaxMap = new Hashtable();
	    initHierarchy();
	}


	public void endDocument() throws SAXException
	{
		buildMOIDs();
		//printMOID();
		//printMap();
		//printMOID();
		//printMinMax();
	}

	// This method reorders the keys and vectors in the alphabetical
	// order so that it is easy for viewing
	public void printMap()
	{
		// Find out the Keys in the map
		Enumeration keySet = relationMap.keys();
		Vector keyVector = new Vector();;
		while (keySet.hasMoreElements())
		{
			String Key = (String)keySet.nextElement();
			//System.out.println(Key);
			keyVector.add(Key);
		}
		Collections.sort(keyVector);
		// Now print the sorted map
		Vector tmpVector;
		for (int i=0;i< keyVector.size();i++) {
			System.out.println(keyVector.elementAt(i));
			tmpVector = (Vector)relationMap.get(keyVector.elementAt(i));
			for (int j=0; j<tmpVector.size();j++){
				System.out.println("\t"+tmpVector.elementAt(j));
			}
			//System.out.println("******");
		}
	}

	// This one prints the MOID Map
	void printMOID()
	{
		Enumeration keySet = moidMap.keys();
		while (keySet.hasMoreElements())
		{
			String Key = (String)keySet.nextElement();
			System.out.println(Key+ " : " +
					           returnMOID(Key));
		}
	}

	// This method prints the min and max values
	void printMinMax()
	{
		Enumeration keySet = minmaxMap.keys();
		while (keySet.hasMoreElements())
		{
			String Key = (String)keySet.nextElement();
			System.out.println(Key+ " : " +
					           minmaxMap.get(Key));
		}
		for ( int i=0;i< childList.size();i++){
			String child = (String)childList.elementAt(i);
			System.out.println(child);
			System.out.println("\t"+returnMinValue(child)+ "," +
					                returnMaxValue(child) + "," +
					                parentList.elementAt(i));


		}
	}

	// This metod returns the minValue of the relation
	int returnMinValue(String childName)
	{
		int minValue =0;
		if ( minmaxMap.containsKey(childName)){
			// Found the key get the value
			String value = (String)minmaxMap.get(childName);
			// First string before the , is min and next is max
			int startIndex = value.indexOf(',');
			String min  = value.substring(0,startIndex);
			minValue = Integer.valueOf(min).intValue();
		}
		return minValue;
	}

	//	 This metod returns the maxValue of the relation
	int returnMaxValue(String childName)
	{
		int maxValue =0;
		if ( minmaxMap.containsKey(childName)){
			// Found the key get the value
			String value = (String)minmaxMap.get(childName);
			// First string before the , is min and next is max
			int lastIndex = value.lastIndexOf(',');
			String min  = value.substring(lastIndex+1);
			maxValue = Integer.valueOf(min).intValue();
		}
		return maxValue;
	}

	// This method returns the Parent if available
	public String returnParent(String tmpChild)
	{
		String tmpParent = "NA";
		//System.out.println("Passed String" + tmpChild);
		if ( childList.contains(tmpChild)){
			int index = childList.indexOf(tmpChild);
			//System.out.println("Index: "+ index);
			return (String)parentList.elementAt(index);
		}
		return tmpParent;
	}

	void buildMOIDs()
	{
		String tmpParent;
		String tmpChild;
		String MOID="";

		for (int i=0;i<childList.size();i++){
			// For each child find the parent
			tmpChild = (String)childList.elementAt(i);
			MOID="";
			int j=0;
			while(!(tmpParent = returnParent(tmpChild)).equals("NA"))
			{
				if ( j == 0 )
					MOID = tmpParent + "=1,"  +
				       	   tmpChild  + "=1" ;
				else
					MOID = tmpParent +"=1," + MOID;
				tmpChild = tmpParent;
				j++;
			}
			//System.out.println((String)childList.elementAt(i) +
		    //                " : " + MOID);
			// Insert the elements in the moidMap
			if ( !moidMap.contains(childList.elementAt(i)))
				moidMap.put((String)childList.elementAt(i),MOID);
		}
	}

	// This method returns the MOID if available
	String returnMOID(String className)
	{
		//System.out.println("returnMOID " + className);
		String tmpMOID = "NA";
		if ( moidMap.containsKey(className)){
			tmpMOID = (String)moidMap.get(className);
		}
		return tmpMOID;
	}
	public void startElement(String namespaceURI,String sName,
			String qName, Attributes attrs)
	throws SAXException
	{

		//System.out.println("Q Name:" + qName);
		if ( qName.equals("relationship"))
		{
			relationFlag =true;
			relationList.addElement(attrs.getValue(0));
		}

		if (qName.equals("parent"))
		{
			parentFlag = true;
		}

		if ( qName.equals("hasClass"))
		{
			if ( parentFlag )
			{
				parentList.addElement(attrs.getValue(0));
				currentParent = attrs.getValue(0);
			}

			if ( childFlag )
			{
                //System.out.println("childFlag=true, hasClass=true, attrs.getValue(0):" + attrs.getValue(0));
				childList.addElement(attrs.getValue(0));
				currentChild = attrs.getValue(0);
			}
		}


		if ( qName.equals("child"))
		{
			childFlag = true;
		}
		if ( qName.equals("cardinality"))
		{
			cardinalityFlag = true;
		}
		if ( qName.equals("min"))
		{
			minFlag = true;
		}
		if ( qName.equals("max"))
		{
			maxFlag = true;
		}
	}
	public void endElement(String namespaceURI,String sName,
            String qName)
	throws SAXException
	{
		//System.out.println("EndElement method. Q Name:" + qName);

		if ( qName.equals("relationship"))
		{
	        processMap();
			if ( relationFlag )
				relationFlag =false;
			// Reset the values
			currentParent = "UNKNOWN";
			currentChild = "UNKNOWN";
			currentMin = -1;
			currentMax = -1;
		}
		if ( qName.equals("parent"))
		{
			if ( parentFlag )
			{
				parentFlag =false;
			}
		}
		if ( qName.equals("child"))
		{
			if ( childFlag )
			{
				childFlag =false;
			}
		}

		if ( qName.equals("cardinality"))
		{
			if ( cardinalityFlag )
				cardinalityFlag =false;
		}
		if ( qName.equals("min"))
		{
			if ( minFlag )
				minFlag =false;
		}
		if ( qName.equals("max"))
		{
			if ( maxFlag )
				maxFlag =false;
		}
	}

	public void characters(char buf[], int offset, int len) throws SAXException
	{
		String s =new String(buf,offset,len);
		if ( cardinalityFlag && minFlag )
			currentMin = Integer.valueOf(s).intValue();
			//System.out.println("Min: " + s);
		if ( cardinalityFlag && maxFlag)
			currentMax = Integer.valueOf(s).intValue();
			//maxList.add(Integer.valueOf(s).intValue());
			//System.out.println("Max: " + s);

	}

	// This is the method which inserts the hierarchy correctly in the
	// vectors and prepares the hashtable
	public void processMap()
	{
		// This method tries to process the map
		// First Find out whether the parent is present or not
		if ( (!currentParent.equals("UNKNOWN")) &&
			 ( currentMin !=-1 ) &&	( currentMax !=-1 ))
		{

			if (relationMap.containsKey(currentParent))
			{
				// Fish out the vector and add the value
				Vector tmpVector = (Vector)relationMap.get(currentParent);
				String tmpChild = currentChild +"," +
				                  currentMin + ","+ currentMax;
				// The currentMin and currentMax are ignored for time
				// being
				tmpVector.addElement(currentChild);
				String tmpValue = currentMin + "," + currentMax;
				minmaxMap.put(currentChild, tmpValue);
				Collections.sort(tmpVector);
			}else
			{
				// Insert the new key and value
				Vector tmpVector = new Vector();
				String tmpChild = currentChild +"," +
                				  currentMin + ","+ currentMax;
				tmpVector.addElement(tmpChild);
				relationMap.put(currentParent,tmpVector);
			}
		}
	}

	public void initHierarchy()
	{
//		use an instance of ourselves as the SAX event handler
		DefaultHandler handler = this;

		//use the default (non-validating) parser
		SAXParserFactory factory = SAXParserFactory.newInstance();
		factory.setValidating(true);

		try {

			SAXParser saxParser = factory.newSAXParser();
			saxParser.parse(new File(xmlFile_),handler);

		 } catch (SAXParseException spe) {
	           // Error generated by the parser
	           System.out.println("\n** Parsing error"
	              + ", line " + spe.getLineNumber()
	              + ", uri " + spe.getSystemId());
	           System.out.println("   " + spe.getMessage() );

	           // Use the contained exception, if any
	           Exception  x = spe;
	           if (spe.getException() != null)
	               x = spe.getException();
	           x.printStackTrace();

	        } catch (SAXException sxe) {
	           // Error generated by this application
	           // (or a parser-initialization error)
	           Exception  x = sxe;
	           if (sxe.getException() != null)
	               x = sxe.getException();
	           x.printStackTrace();

	        } catch (ParserConfigurationException pce) {
	            // Parser with specified options can't be built
	            pce.printStackTrace();

	        } catch (IOException ioe) {
	           // I/O error
	           ioe.printStackTrace();
	        }
	}

	 @Override
     public InputSource resolveEntity(String publicId, String systemId){
         return new InputSource(new ByteArrayInputStream(new byte[0]));
     }

	public static void main(String[] args) {
		//System.out.println("In Main method");
		//if ( args.length != 1) {
		//	System.err.println("Usage java Hierarchy <fileName>");
		//	System.exit(1);
		//}
		Hierarchy hh = new Hierarchy("cxc1323353_R5M01.xml");
	    //hh.printMOID();
		System.exit(0);
	}
}

