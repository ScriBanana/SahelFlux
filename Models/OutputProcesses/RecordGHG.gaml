/**
* In: SahelFlux
* Name: RecordGHG
* Records GHG flows
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model RecordGHG

import "../Main.gaml"

global {
	map<string, float> GHGFlowsMapTemplate <- [
		"CO2"::0.0,
		"CH4"::0.0,
		"N2O"::0.0
	] const: true; // kgCO2/kgCH4/kgN2O
	map<string, map> GHGFlowsMap <- [
			"Households"::copy(GHGFlowsMapTemplate),
			"MobileHerds"::copy(GHGFlowsMapTemplate),
			"FattenedAn"::copy(GHGFlowsMapTemplate),
			"ORPHeaps"::copy(GHGFlowsMapTemplate),
			"StrawPiles"::copy(GHGFlowsMapTemplate),
			"HomeFields"::copy(GHGFlowsMapTemplate),
			"BushFields"::copy(GHGFlowsMapTemplate),
			"Rangelands"::copy(GHGFlowsMapTemplate),
			"Millet"::copy(GHGFlowsMapTemplate),
			"Groundnut"::copy(GHGFlowsMapTemplate),
			"FallowVeg"::copy(GHGFlowsMapTemplate),
			"SpontVeg"::copy(GHGFlowsMapTemplate),
			"Weeds"::copy(GHGFlowsMapTemplate),
			"Trees"::copy(GHGFlowsMapTemplate)
	];
	map<string, map> regularOutputGHGFlowsMap;
	
	action saveGHGFlow (string flowOrigin, string flowType, float flowValue) {
		if enableDebug {
			// Tests for typo
			assert flowType in ["CO2", "CH4", "N2O"];
			assert flowOrigin in GHGFlowsMap.keys;
		}
		GHGFlowsMap[flowOrigin][flowType] <- float(GHGFlowsMap[flowOrigin][flowType]) + flowValue;
		regularOutputGHGFlowsMap[flowOrigin][flowType] <- float(regularOutputGHGFlowsMap[flowOrigin][flowType]) + flowValue;
	}
	
}
