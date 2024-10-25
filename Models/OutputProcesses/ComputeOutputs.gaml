/**
* In: SahelFlux
* Name: ComputeOutputs
* Calculate output indicators based on recorded flows
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "../Main.gaml"
import "ComputeMoranI.gaml"

global {
	
	//// Output variables ////
	
	// Global flows
	float totalNFlows; // kgN
	float totalNInflows; // kgN
	float totalNThroughflows; // kgN
	float totalNOutflows; // kgN
	float totalCFlows; // kgC
	float totalCInflows; // kgC
	float totalCThroughflows; // kgC
	float totalCOutflows; // kgC
	
	// Circularity (ENA framework)
	float TSTN;
	float pathLengthN;
	float ICRN;
	float TSTC;
	float pathLengthC;
	float ICRC;
	
	// GHG
	float totalCO2; // kgCO2
	float totalCH4; // kgCH4
	float totalN2O; // kgN2O
	float totalGHG; // kgCO2eq
	
	// Carbon and nitrogen balance
	float ecosystemCBalance; // Whole system : inputs - outputs
	float ecosystemNBalance;
	float ecosystemApparentCBalance; // Balance with no gas fixation nor emissions - human driven flows only
	float ecosystemApparentNBalance;
	float ecosystemCO2Balance; // kgCO2; atmo fix - CO2 emissions; used for validation
	float ecosystemGHGBalance; // kgCO2eq; GHG emissions - SOCS accumulation
	float CFootprint;
	
	// SOC
	float totalMeanSOCVariation; // kgC
	
	// SOC Moran Is
	float homefieldsSOCMoran;
	float bushfieldsSOCMoran;
	float croplandSOCMoran;
	float rangelandSOCMoran;
	float globalSOCMoran;
	
	// Flow balance gatherer
	map<string, list> poolFlowsMap <- [ // [string::pool :: [float::Cbalance(kgC), float::Nbalance(kgN), float::GHG(kgCO2eq)]]
		"Households"::[0.0, 0.0, 0.0],
		"MobileHerds"::[0.0, 0.0, 0.0],
		"FattenedAn"::[0.0, 0.0, 0.0],
		"ORPHeaps"::[0.0, 0.0, 0.0],
		"StrawPiles"::[0.0, 0.0, 0.0],
		"HomeFields"::[0.0, 0.0, 0.0],
		"BushFields"::[0.0, 0.0, 0.0],
		"Rangelands"::[0.0, 0.0, 0.0],
		"Millet"::[0.0, 0.0, 0.0],
		"Groundnut"::[0.0, 0.0, 0.0],
		"FallowVeg"::[0.0, 0.0, 0.0],
		"SpontVeg"::[0.0, 0.0, 0.0],
		"Weeds"::[0.0, 0.0, 0.0],
		"Trees"::[0.0, 0.0, 0.0],
		"Market"::[0.0, 0.0, 0.0],
		"Transhumance"::[0.0, 0.0, 0.0],
		"Atmosphere"::[0.0, 0.0, 0.0]
	];
	
	// Derivative of each pools N and C contents (see Finn, 1980)
	map<string, list> poolsDerivativeMap <- [ // [string::pool :: [float::NFlowDerivative, float::CFlowDerivative]]
		"Households"::[0.0, 0.0],
		"MobileHerds"::[0.0, 0.0],
		"FattenedAn"::[0.0, 0.0],
		"ORPHeaps"::[0.0, 0.0],
		"StrawPiles"::[0.0, 0.0],
		"HomeFields"::[0.0, 0.0],
		"BushFields"::[0.0, 0.0],
		"Rangelands"::[0.0, 0.0],
		"Millet"::[0.0, 0.0],
		"Groundnut"::[0.0, 0.0],
		"FallowVeg"::[0.0, 0.0],
		"SpontVeg"::[0.0, 0.0],
		"Weeds"::[0.0, 0.0],
		"Trees"::[0.0, 0.0]
	];
	
	//// Output computer ////
	
	action computeOutputs (map NMap, map CMap, map GHGMap) {
		
		//// Gather flows
		
		// Nitrogen
		loop poolPair over: NMap.pairs {
			string poolKey <- poolPair.key;
			map poolMap <- poolPair.value;
			loop flowPair over: poolMap.pairs {
				string flowKey <- flowPair.key;
				string flowPool <- replace (flowKey, "TF-To", "");
				float flowValue <- float(flowPair.value);
				
				totalNFlows <- totalNFlows + flowValue;
				if flowKey contains "IF-" {
					
					totalNInflows <- totalNInflows + flowValue;
					TSTN <- TSTN + flowValue;
					poolsDerivativeMap[poolKey][0] <- float(poolsDerivativeMap[poolKey][0]) + flowValue;
					ecosystemNBalance <- ecosystemNBalance + flowValue;
					ecosystemApparentNBalance <- ecosystemApparentNBalance + flowValue;
					
					poolFlowsMap[poolKey][1] <- float(poolFlowsMap[poolKey][1]) + flowValue;
					switch flowKey {
						match "IF-FromMarket" {
							poolFlowsMap["Market"][1] <- float(poolFlowsMap["Market"][1]) - flowValue;
						} match "IF-FromTranshu" {
							poolFlowsMap["Transhumance"][1] <- float(poolFlowsMap["Transhumance"][1]) - flowValue;
						} match "IF-FromAtmo" {
							poolFlowsMap["Atmosphere"][1] <- float(poolFlowsMap["Atmosphere"][1]) - flowValue;
							ecosystemApparentNBalance <- ecosystemApparentNBalance - flowValue;
						}
					}
				} else if flowKey contains "OF-" {
					
					totalNOutflows <- totalNOutflows + flowValue;
					poolsDerivativeMap[poolKey][0] <- float(poolsDerivativeMap[poolKey][0]) - flowValue;
					ecosystemNBalance <- ecosystemNBalance - flowValue;
					ecosystemApparentNBalance <- ecosystemApparentNBalance - flowValue;
					
					poolFlowsMap[poolKey][1] <- float(poolFlowsMap[poolKey][1]) - flowValue;
					switch flowKey {
						match "OF-SoldOnMarket" {
							poolFlowsMap["Market"][1] <- float(poolFlowsMap["Market"][1]) + flowValue;
						} match "OF-ToTranshu" {
							poolFlowsMap["Transhumance"][1] <- float(poolFlowsMap["Transhumance"][1]) + flowValue;
						} match_one ["OF-GHG", "OF-AtmoLosses"] {
							poolFlowsMap["Atmosphere"][1] <- float(poolFlowsMap["Atmosphere"][1]) + flowValue;
							ecosystemApparentNBalance <- ecosystemApparentNBalance - flowValue;
						}
					}
				} else if flowKey contains "TF-" {
					
					totalNThroughflows <- totalNThroughflows + flowValue;
					TSTN <- TSTN + flowValue;
					poolsDerivativeMap[poolKey][0] <- float(poolsDerivativeMap[poolKey][0]) - flowValue;
					poolsDerivativeMap[flowPool][0] <- float(poolsDerivativeMap[flowPool][0]) + flowValue;
					
					poolFlowsMap[poolKey][1] <- float(poolFlowsMap[poolKey][1]) - flowValue;
					poolFlowsMap[flowPool][1] <- float(poolFlowsMap[flowPool][1]) + flowValue;
				}
			}
		}
		
		// Carbon
		loop poolPair over: CMap.pairs {
			string poolKey <- poolPair.key;
			map poolMap <- poolPair.value;
			loop flowPair over: poolMap.pairs {
				string flowKey <- flowPair.key;
				string flowPool <- replace (flowKey, "TF-To", "");
				float flowValue <- float(flowPair.value);
				
				totalCFlows <- totalCFlows + flowValue;
				if flowKey contains "IF-" {
					
					totalCInflows <- totalCInflows + flowValue;
					TSTC <- TSTC + flowValue;
					poolsDerivativeMap[poolKey][1] <- float(poolsDerivativeMap[poolKey][1]) + flowValue;
					ecosystemCBalance <- ecosystemCBalance + flowValue;
					ecosystemApparentCBalance <- ecosystemApparentCBalance + flowValue;
					
					poolFlowsMap[poolKey][0] <- float(poolFlowsMap[poolKey][0]) + flowValue;
					switch flowKey {
						match "IF-FromMarket" {
							poolFlowsMap["Market"][0] <- float(poolFlowsMap["Market"][0]) - flowValue;
						} match "IF-FromTranshu" {
							poolFlowsMap["Transhumance"][0] <- float(poolFlowsMap["Transhumance"][0]) - flowValue;
						} match "IF-FromAtmo" {
							ecosystemCO2Balance <- ecosystemCO2Balance - flowValue / coefCO2ToC;
							poolFlowsMap["Atmosphere"][0] <- float(poolFlowsMap["Atmosphere"][0]) - flowValue;
							ecosystemApparentCBalance <- ecosystemApparentCBalance - flowValue;
						}
					}
				} else if flowKey contains "OF-" {
					
					totalCOutflows <- totalCOutflows + flowValue;
					poolsDerivativeMap[poolKey][1] <- float(poolsDerivativeMap[poolKey][1]) - flowValue;
					ecosystemCBalance <- ecosystemCBalance - flowValue;
					ecosystemApparentCBalance <- ecosystemApparentCBalance - flowValue;
					
					poolFlowsMap[poolKey][0] <- float(poolFlowsMap[poolKey][0]) - flowValue;
					switch flowKey {
						match "OF-SoldOnMarket" {
							poolFlowsMap["Market"][0] <- float(poolFlowsMap["Market"][0]) + flowValue;
						} match "OF-ToTranshu" {
							poolFlowsMap["Transhumance"][0] <- float(poolFlowsMap["Transhumance"][0]) + flowValue;
						} match_one ["OF-GHG", "OF-AtmoLosses"] {
							poolFlowsMap["Atmosphere"][0] <- float(poolFlowsMap["Atmosphere"][0]) + flowValue;
							ecosystemApparentCBalance <- ecosystemApparentCBalance + flowValue;
						}
					}
				} else if flowKey contains "TF-" {
					
					totalCThroughflows <- totalCThroughflows + flowValue;
					TSTC <- TSTC + flowValue;
					poolsDerivativeMap[poolKey][1] <- float(poolsDerivativeMap[poolKey][1]) - flowValue;
					poolsDerivativeMap[flowPool][1] <- float(poolsDerivativeMap[flowPool][1]) + flowValue;
					
					poolFlowsMap[poolKey][0] <- float(poolFlowsMap[poolKey][0]) - flowValue;
					poolFlowsMap[flowPool][0] <- float(poolFlowsMap[flowPool][0]) + flowValue;
				}
			}
		}
		
		// GHG
		loop subMap over: GHGMap.pairs {
			string poolKey <- subMap.key;
			map GHGMapMap <- subMap.value;
			loop flowPair over: GHGMapMap.pairs {
				string GHGKey <- flowPair.key;
				float flowValue <- float(flowPair.value);
				
				if GHGKey = "CO2" {
					totalCO2 <- totalCO2 + flowValue;
					totalGHG <- totalGHG + flowValue;
					ecosystemCO2Balance <- ecosystemCO2Balance + flowValue;
					poolFlowsMap[poolKey][2] <- float(poolFlowsMap[poolKey][2]) + flowValue;
				} else if GHGKey = "CH4" {
					totalCH4 <- totalCH4 + flowValue;
					totalGHG <- totalGHG + flowValue * GWPCH4;
					poolFlowsMap[poolKey][2] <- float(poolFlowsMap[poolKey][2]) + flowValue * GWPCH4;
				} else if GHGKey = "N2O" {
					totalN2O <- totalN2O + flowValue;
					totalGHG <- totalGHG + flowValue * GWPN2O;
					poolFlowsMap[poolKey][2] <- float(poolFlowsMap[poolKey][2]) + flowValue * GWPN2O;
				}
			}
		}
		
		// SOC		
		do getMeanSOCS;
		totalMeanSOCVariation <- globalMeanSOC - totalMeanSOCInit; // kgC/cell
		
		//// Compute derivated outputs
		
		// Carbon balance
		ecosystemGHGBalance <- totalGHG - (totalMeanSOCVariation  * (length(grazableLandscape) * hectarePerCell) / coefCO2ToC); // kgCO2eq
		
		// SOC moran indexes
		if moranOn {do getMoranSOCS;}
		
		// Global ENA indicators (Finn, 1980; Stark, 2016; Balandier, 2017; Latham, 2006)
		float negNDerivatives <- poolsDerivativeMap.values sum_of (float(each[0]) < 0.0 ?  float(each[0]) : 0.0);
		float posNDerivatives <- poolsDerivativeMap.values sum_of (float(each[0]) > 0.0 ?  float(each[0]) : 0.0);
		float negCDerivatives <- poolsDerivativeMap.values sum_of (float(each[1]) < 0.0 ?  float(each[1]) : 0.0);
		float posCDerivatives <- poolsDerivativeMap.values sum_of (float(each[1]) > 0.0 ?  float(each[1]) : 0.0);
		
		if enableDebug {
			assert totalNInflows - negNDerivatives = totalNOutflows + posNDerivatives;
			assert totalCInflows - negCDerivatives = totalCOutflows + posCDerivatives;
		}
		
		// TST
		TSTN <- TSTN - negNDerivatives;
		TSTC <- TSTC - negCDerivatives;
		
		// PL
		pathLengthN <- totalNInflows - negNDerivatives != 0.0 ? TSTN / (totalNInflows - negNDerivatives) : 0.0;
		pathLengthC <- totalCInflows - negCDerivatives != 0.0 ? TSTC / (totalCInflows - negCDerivatives) : 0.0;
		
		// ICR
		ICRN <- TSTN != 0.0 ? totalNThroughflows / TSTN : 0.0;
		ICRC <- TSTC != 0.0 ? totalCThroughflows / TSTC : 0.0;
		
	}
	
}
