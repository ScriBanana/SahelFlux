/**
* In: SahelFlux
* Name: RecordFlows
* Records flows in flow maps and holds a function to transform it in ENA compliant matrixes
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model RecordFlows

import "../Main.gaml"

global {
	
	//// Initiate data gathering tools ////
	
	// Modular maps to structure matrixes (could just be matrixes, but clearer with maps)
	// Structure of the map for inflows to, throughflows from and outflows from a pool
	map<string, float> flowsMapTemplate <- [
		// Inflows
		"IF-FromMarket"::0.0,
		"IF-FromAtmo"::0.0,
		// Throughflows
		"TF-ToHouseholds"::0.0,
		"TF-ToMobileHerds"::0.0,
		"TF-ToFattenedAn"::0.0,
		"TF-ToORPHeaps"::0.0,
		"TF-ToStrawPiles"::0.0,
		"TF-ToHomeFields"::0.0,
		"TF-ToBushFields"::0.0,
		"TF-ToRangelands"::0.0,
		"TF-ToMillet"::0.0,
		"TF-ToGroundnut"::0.0,
		"TF-ToFallowVeget"::0.0,
		"TF-ToSpontVeget"::0.0,
		"TF-ToWeeds"::0.0,
		// Outflows
		"OF-soldOnMarket"::0.0,
		"OF-GHG"::0.0,
		"OF-AtmoLosses"::0.0
	];
	int nbFlows <- length(flowsMapTemplate);
	int nbInflows <- flowsMapTemplate.pairs count (each.key contains "IF-");
	int nbThroughflows <- flowsMapTemplate.pairs count (each.key contains "TF-");
	int nbOutflows <- flowsMapTemplate.pairs count (each.key contains "OF-");
	
	// Maps of flows for each pool
	map<string, map> NFlowsMap;
	map<string, map> CFlowsMap;
	
	// Resets values of the flows map to 0.0
	action resetFlowsMaps {
		NFlowsMap <- [
				"Households"::copy(flowsMapTemplate),
				"MobileHerds"::copy(flowsMapTemplate),
				"FattenedAn"::copy(flowsMapTemplate),
				"ORPHeaps"::copy(flowsMapTemplate),
				"StrawPiles"::copy(flowsMapTemplate),
				"HomeFields"::copy(flowsMapTemplate),
				"BushFields"::copy(flowsMapTemplate),
				"Rangelands"::copy(flowsMapTemplate),
				"Millet"::copy(flowsMapTemplate),
				"Groundnut"::copy(flowsMapTemplate),
				"FallowVeg"::copy(flowsMapTemplate),
				"SpontVeg"::copy(flowsMapTemplate),
				"Weeds"::copy(flowsMapTemplate)
			];
		CFlowsMap <- [ // Copy(NFlowsMap) doesn't work, apparently
				"Households"::copy(flowsMapTemplate),
				"MobileHerds"::copy(flowsMapTemplate),
				"FattenedAn"::copy(flowsMapTemplate),
				"ORPHeaps"::copy(flowsMapTemplate),
				"StrawPiles"::copy(flowsMapTemplate),
				"HomeFields"::copy(flowsMapTemplate),
				"BushFields"::copy(flowsMapTemplate),
				"Rangelands"::copy(flowsMapTemplate),
				"Millet"::copy(flowsMapTemplate),
				"Groundnut"::copy(flowsMapTemplate),
				"FallowVeg"::copy(flowsMapTemplate),
				"SpontVeg"::copy(flowsMapTemplate),
				"Weeds"::copy(flowsMapTemplate)
			];
	}
	
	// Flows matrix creation
	matrix<float> NFlowsMatrix <- {nbFlows - nbOutflows, nbFlows - nbInflows} matrix_with 0.0;
	matrix<float> CFlowsMatrix  <- {nbFlows - nbOutflows, nbFlows - nbInflows} matrix_with 0.0; // <- copy(NFlowsMatrix) might not work
	
	
	//// Functions ////
	
	// Gather flows saved in the global map into the ENA matrix
	action gatherFlows {
		// Could have been a loop over N and C, but nested maps turn into containers somehow, so whatever.
		
		// N flows
		int originPoolId <- 0;
		loop poolFlowsMap over: NFlowsMap.pairs {
			// In and throughflows on each line
			map poolInAndThroughflowsMap <- map(poolFlowsMap.value.pairs where (each.key contains_any ["IF-", "TF-"]));
			loop recievingPoolId from: 0 to: nbInflows + nbThroughflows - 1 {
				NFlowsMatrix[{recievingPoolId, originPoolId}] <-
					NFlowsMatrix[{recievingPoolId, originPoolId}] +
					float(poolInAndThroughflowsMap.values[recievingPoolId]);
			}
			// Outflows on the relevant column
			map poolOutflowsMap <- map(poolFlowsMap.value.pairs where (each.key contains "OF-"));
			loop recevingPoolId from: 0 to: nbOutflows - 1 {
				NFlowsMatrix[{nbInflows + originPoolId, nbThroughflows + recevingPoolId}]  <-
					NFlowsMatrix[{nbInflows + originPoolId, nbThroughflows + recevingPoolId}] +
					int(poolOutflowsMap.values[recevingPoolId]);
			}
			originPoolId <- originPoolId + 1;
		}
		write "N flows :";
		write NFlowsMatrix;
		
		// C flows
		originPoolId <- 0;
		loop poolFlowsMap over: CFlowsMap.pairs {
			// In and throughflows on each line
			map poolInAndThroughflowsMap <- map(poolFlowsMap.value.pairs where (each.key contains_any ["IF-", "TF-"]));
			loop recievingPoolId from: 0 to: nbInflows + nbThroughflows - 1 {
				CFlowsMatrix[{recievingPoolId, originPoolId}] <-
					CFlowsMatrix[{recievingPoolId, originPoolId}] +
					float(poolInAndThroughflowsMap.values[recievingPoolId]);
			}
			// Outflows on the relevant column
			map poolOutflowsMap <- map(poolFlowsMap.value.pairs where (each.key contains "OF-"));
			loop recevingPoolId from: 0 to: nbOutflows - 1 {
				CFlowsMatrix[{nbInflows + originPoolId, nbThroughflows + recevingPoolId}]  <-
					CFlowsMatrix[{nbInflows + originPoolId, nbThroughflows + recevingPoolId}] +
					int(poolOutflowsMap.values[recevingPoolId]);
			}
			originPoolId <- originPoolId + 1;
		}
		write "C flows :";
		write CFlowsMatrix;
		
		do resetFlowsMaps;
	}
	
	
	// Used by agents in ask world statement to save emitted flows in the flows maps
	action saveFlowInMap (string flowType, string emittingPool, string flowDestination, float flowValue) {
		// Tests for typo
		assert flowType in ["C", "N"];
		assert emittingPool in NFlowsMap.keys;
		assert flowDestination in flowsMapTemplate.keys;
		
		// Assign to flows map
		// (Switch more robust and allows addition of a flow type)
		switch flowType {
			match "C" {
				CFlowsMap[emittingPool][flowDestination] <- float(CFlowsMap[emittingPool][flowDestination]) + flowValue;
			}
			match "N" {
				NFlowsMap[emittingPool][flowDestination] <- float(NFlowsMap[emittingPool][flowDestination]) + flowValue;
			}
		}
	}
	
	// Compute global ENA indicators at the end of the simulation (Stark, 2016; Balandier, 2017, Latham, 2006)
	
}


