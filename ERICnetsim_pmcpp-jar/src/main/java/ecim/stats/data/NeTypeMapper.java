package ecim.stats.data;

import java.util.HashMap;
import java.util.Map;

public class NeTypeMapper {

	private static Map<String, String> NeTypeToMibConfigNeType = new HashMap<String, String>();

	static {
		NeTypeToMibConfigNeType.put("PRBS", "PRBS_WRAN");
		NeTypeToMibConfigNeType.put("SAPC", "ESAPC");
	}

	public static String getMibConfigNeType(final String neType) {

		String mibNeType = neType;
		if (NeTypeToMibConfigNeType.containsKey(neType)) {
			mibNeType = NeTypeToMibConfigNeType.get(neType);
		}

		return mibNeType;
	}
}
