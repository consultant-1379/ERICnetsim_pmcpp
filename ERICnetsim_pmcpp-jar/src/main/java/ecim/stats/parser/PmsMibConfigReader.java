/*
 * This Class responsible for parsing the PMS MIB configuration file. 
 * 
 */

package ecim.stats.parser;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import ecim.stats.data.EcimStatsConstant;

public class PmsMibConfigReader extends DefaultHandler {

	static String inputFile;

	private String neTypeAndVersion;

	Map<String, List<String>> neTypeToMibFiles = new HashMap<String, List<String>>();

	/**
	 * This method is responsible for parsing the PMS MIB configuration file and
	 * fetches the MIB files corresponding to Node Type and Node version
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
			case NODETYPE:

				String nodeType = attributes.getValue(MibConstants.NAME_ATRR);
				String nodeRelease = attributes
						.getValue(MibConstants.NODE_RELEASE);
				// String[] neType =
				// nodeType.split(EcimStatsConstant.UNDERSCORE);
				neTypeAndVersion = nodeType + EcimStatsConstant.UNDERSCORE
						+ nodeRelease;

				neTypeToMibFiles
						.put(neTypeAndVersion, new LinkedList<String>());
				break;

			case MIB:

				String mibName = attributes.getValue(MibConstants.NAME_ATRR);
				String version = attributes.getValue(MibConstants.VERSION);

				String mib = mibName
						+ "_v"
						+ version.replaceAll("\\.",
								EcimStatsConstant.UNDERSCORE)
						+ EcimStatsConstant.XML_EXTENSION;

				List<String> mibList = neTypeToMibFiles.get(neTypeAndVersion);

				if (mibList != null) {
					mibList.add(EcimStatsConstant.WRAN_MOM_DAT_PATH + mib);
					neTypeToMibFiles.put(neTypeAndVersion, mibList);

				}

				break;
			default:
				break;
			}
		}
	}

	@Override
	public void endElement(final String uri, final String localName,
			final String qName) throws SAXException {

		MibTag tag = MibTag.getTag(qName);
		if (tag != null) {

			switch (tag) {
			case NODETYPE:
				neTypeAndVersion = null;
				break;

			default:
				break;
			}
		}
	}

	public static void main(String args[]) {
		String version = "1_0";
		String[] neType = version.split("_");
		System.out.println(neType[0]);

	}

	/**
	 * This method returns the list MIB files for passed NodeType and Node
	 * Version.
	 * 
	 * @param pmsMibConfigFile
	 *            : pms mib configuraiton file
	 * @return fileList - List MIB files
	 * @throws Exception
	 */
	public List<String> getMibList(final String pmsMibConfigFile,
			final String nodeType, final String nodeVersion) throws Exception {

		File xmlFile = new File(pmsMibConfigFile);

		if (pmsMibConfigFile == null || (!xmlFile.exists())
				|| (!xmlFile.isFile()) || (!xmlFile.canRead())) {

			System.out.println("Invalid file or No read permission");

		}

		parse(pmsMibConfigFile);

		return neTypeToMibFiles.get(nodeType + EcimStatsConstant.UNDERSCORE
				+ nodeVersion);
	}

}
