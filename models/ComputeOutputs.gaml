/**
* In: SahelFlux
* Name: ComputeOutputs
* Soil organic carbon stock
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ComputeOutputs

global {
	// Modular maps to structure matrixes (could just be matrixes, but clearer with maps)
	// Structure of the map for inflows to, throughflows from and outflows from a pool
	map<string, float> flowsMapTemplate <- [
		// Inflows
		"IF-FromMarket"::0.0,
		"IF-FromAtmo"::0.0,
		// Throughflows
		"TF-ToHousehold"::0.0,
		"TF-ToMobileHerds"::0.0,
		"TF-ToFattenedAn"::0.0,
		"TF-ToORPHeap"::0.0,
		"TF-ToStrawPile"::0.0,
		"TF-ToHomeFields"::0.0,
		"TF-ToBushFields"::0.0,
		"TF-ToRangeland"::0.0,
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
	int nbInflows <- length(map(flowsMapTemplate.pairs where (each.key contains "IF-")));
	int nbThroughflows <- length(map(flowsMapTemplate.pairs where (each.key contains "TF-")));
	int nbOutflows <- length(map(flowsMapTemplate.pairs where (each.key contains "OF-")));
	
	// Maps of flows for each pool
	map<string, map> NFlowsMap;
	map<string, map> CFlowsMap;
	
	// Flows matrix creation
	matrix<float> NFlowsMatrix <- {nbFlows - nbOutflows, nbFlows - nbInflows} matrix_with rnd(100.0);
	matrix<float> CFlowsMatrix  <- {nbFlows - nbOutflows, nbFlows - nbInflows} matrix_with rnd(-100.0); // <- copy(NFlowsMatrix); TODO
	
	// Gather flows saved in the global map into the ENA matrix
	action gatherFlows {
		// Could have been a loop, but whatever...
		
		// N flows
		int originPoolId <- 0;
		loop poolFlowsMap over: NFlowsMap.pairs {
			// In and throughflows on each line
			map poolInAndThroughflowsMap <- map(poolFlowsMap.value.pairs where (each.key contains_any ["IF-", "TF-"]));
			loop recievingPoolId from: 0 to: nbInflows + nbThroughflows {
				NFlowsMatrix[{recievingPoolId, originPoolId}] <-
//					NFlowsMatrix[{recievingPoolId, originPoolId}] +
					float(poolInAndThroughflowsMap.values[recievingPoolId]);
			}
			// Outflows on the relevant column
			map poolOutflowsMap <- map(poolFlowsMap.value.pairs where (each.key contains "OF-"));
			loop recevingPoolId from: 0 to: nbOutflows {
				NFlowsMatrix[{nbInflows + originPoolId, nbThroughflows + recevingPoolId}]  <-
//					NFlowsMatrix[{nbInflows + originPoolId, nbThroughflows + recevingPoolId}] +
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
			loop recievingPoolId from: 0 to: nbInflows + nbThroughflows {
				CFlowsMatrix[{recievingPoolId, originPoolId}] <-
//					CFlowsMatrix[{recievingPoolId, originPoolId}] +
					float(poolInAndThroughflowsMap.values[recievingPoolId]);
			}
			// Outflows on the relevant column
			map poolOutflowsMap <- map(poolFlowsMap.value.pairs where (each.key contains "OF-"));
			loop recevingPoolId from: 0 to: nbOutflows {
				CFlowsMatrix[{nbInflows + originPoolId, nbThroughflows + recevingPoolId}]  <-
//					CFlowsMatrix[{nbInflows + originPoolId, nbThroughflows + recevingPoolId}] +
					int(poolOutflowsMap.values[recevingPoolId]);
			}
			originPoolId <- originPoolId + 1;
		}
		write "C flows :";
		write CFlowsMatrix;
		
		do resetFlowsMaps;
	}
	
	// Resets values of the flows map to 0.0
	action resetFlowsMaps {
		NFlowsMap <- [
				"Household"::flowsMapTemplate,
				"MobileHerds"::flowsMapTemplate,
				"FattenedAn"::flowsMapTemplate,
				"ORPHeap"::flowsMapTemplate,
				"StrawPile"::flowsMapTemplate,
				"HomeFields"::flowsMapTemplate,
				"BushFields"::flowsMapTemplate,
				"Rangeland"::flowsMapTemplate,
				"Millet"::flowsMapTemplate,
				"Groundnut"::flowsMapTemplate,
				"FallowVeg"::flowsMapTemplate,
				"Weeds"::flowsMapTemplate
			];
		CFlowsMap <- copy(NFlowsMap);
	}
	
	// Compute global ENA indicators at the end of the simulation (Stark, 2016; Balandier, 2017, Latham, 2006)
	
	
	
}

