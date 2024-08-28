/*
 * This Class responsible for parsing the Relationship MIB files and cache the relationships with between counter groups/MOC
 * 
 */


package ecim.stats.parser;

import java.io.File;
import java.io.IOException;
import java.util.*;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import ecim.stats.data.EcimStatsConstant;


public class MocRelationMibFileReader extends DefaultHandler {

	
	static String inputFile;

	private String relationName;

	private String parent;

	private String child;
	
	private Set<String> mocs;

	Map<String,String> childToParentMap= new HashMap<String,String>();

	
	
	/**
	 * This method parses the inputFIle to fetches relationships between counter
	 * groups/MOC
	 * 
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
	public void startElement(final String uri, final String localName,
			final String qName, final Attributes attributes)
			throws SAXException {

		MibTag tag = MibTag.getTag(qName);

		if (tag != null) {
			switch (tag) {
			case RELATIONSHIP:
				
				relationName = attributes.getValue(MibConstants.NAME_ATRR);
				
				if (relationName
						.contains(EcimStatsConstant.MOC_RELATIONSHIP_SEP)) {
					if (relationName.contains(EcimStatsConstant.COLUMN)) {
						relationName = relationName
								.split(EcimStatsConstant.COLUMN)[1];
					}

					parent = relationName.substring(0, relationName
							.indexOf(EcimStatsConstant.MOC_RELATIONSHIP_SEP));
					child = relationName
							.substring(
									relationName
											.indexOf(EcimStatsConstant.MOC_RELATIONSHIP_SEP)
											+ EcimStatsConstant.MOC_RELATIONSHIP_SEP
													.length(), relationName
											.length());

					if (mocs.contains(child.trim())) {
						childToParentMap.put(child.trim(), parent.trim());
					}

				}
				break;
			default:
				break;
			}
		}
	}
	
	
	
	
	/**
	 * This method will returns a Map with Parent MO as Key and Its child as
	 * value
	 * 
	 * @param fileList
	 *            - List of Relationship MIB files
	 * @return Map MO class and measurement type list associated to it
	 * @throws Exception
	 */
	public Map<String, String> getChildToParentRel(
			final List<String> fileList,final Set<String> mocs) throws Exception {
		
		
		for(String file : fileList)
		{
			File xmlFile = new File(file);

			if (file == null || (!xmlFile.exists()) || (!xmlFile.isFile())
					|| (!xmlFile.canRead())) {

				System.out.println("Invalid file or No read permission");

			}

			inputFile = file;
			this.mocs=mocs;
			parse(file);

		}
			
			
		return childToParentMap;
	}
}
