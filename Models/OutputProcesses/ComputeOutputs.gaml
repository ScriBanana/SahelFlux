/**
* In: SahelFlux
* Name: ComputeOutputs
* Calculate output indicators based on recorded flows
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ComputeOutputs

import "RecordFlows.gaml"
import "RecordGHG.gaml"
import "../../Utilities/CnNFlowsParameters.gaml"

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
	float ICRN;
	float FinnN;
	float TSTC;
	float ICRC;
	float FinnC;
	
	// GHG
	float totalCO2; // kgCO2
	float totalCH4; // kgCH4
	float totalN2O; // kgN2O
	float totalGHG; // kgCO2eq
	
	// Carbon balance
	float ecosystemCBalance;
	float ecosystemCO2Balance; // kgCO2; atmo fix - CO2 emissions; used for validation
	float ecosystemGHGBalance; // kgCO2eq; SOCS accumulation - GHG emissions
	float SCS;
	float CFootprint;
	
	// SOC
	float meanHomefieldsSOCSVariation; // kgC
	float meanBushfieldsSOCSVariation; // kgC
	float meanRangelandSOCSVariation; // kgC
	float totalMeanSOCSVariation; // kgC
	
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
	
	//// Output computer ////
	
	action computeOutputs {
		
		//// Gather flows
		
		// Nitrogen
		loop poolPair over: NFlowsMap.pairs { // TODO ne marchera pas si gatherflows est call plusieurs fois
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
					
					poolFlowsMap[poolKey][1] <- float(poolFlowsMap[poolKey][1]) + flowValue;
					switch flowKey {
						match "IF-FromMarket" {
							poolFlowsMap["Market"][1] <- float(poolFlowsMap["Market"][1]) - flowValue;
						} match "IF-FromTranshu" {
							poolFlowsMap["Transhumance"][1] <- float(poolFlowsMap["Transhumance"][1]) - flowValue;
						} match "IF-FromAtmo" {
							poolFlowsMap["Atmosphere"][1] <- float(poolFlowsMap["Atmosphere"][1]) - flowValue;
						}
					}
				} else if flowKey contains "OF-" {
					
					totalNOutflows <- totalNOutflows + flowValue;
					
					poolFlowsMap[poolKey][1] <- float(poolFlowsMap[poolKey][1]) - flowValue;
					switch flowKey {
						match "OF-SoldOnMarket" {
							poolFlowsMap["Market"][1] <- float(poolFlowsMap["Market"][1]) + flowValue;
						} match "OF-ToTranshu" {
							poolFlowsMap["Transhumance"][1] <- float(poolFlowsMap["Transhumance"][1]) + flowValue;
						} match_one ["OF-GHG", "OF-AtmoLosses"] {
							poolFlowsMap["Atmosphere"][1] <- float(poolFlowsMap["Atmosphere"][1]) + flowValue;
						}
					}
				} else if flowKey contains "TF-" {
					
					totalNThroughflows <- totalNThroughflows + flowValue;
					TSTN <- TSTN + flowValue;
					
					poolFlowsMap[poolKey][1] <- float(poolFlowsMap[poolKey][1]) - flowValue;
					poolFlowsMap[flowPool][1] <- float(poolFlowsMap[flowPool][1]) + flowValue;
				}
			}
		}
		
		
		// Carbon
		loop poolPair over: CFlowsMap.pairs {
			string poolKey <- poolPair.key;
			map poolMap <- poolPair.value;
			loop flowPair over: poolMap.pairs {
				string flowKey <- flowPair.key;
				string flowPool <- replace (flowKey, "TF-To", "");
				float flowValue <- float(flowPair.value);
				
				totalCFlows <- totalCFlows + flowValue;
				if flowKey contains "IF-" {
					
					totalCInflows <- totalCInflows + flowValue;
					ecosystemCBalance <- ecosystemCBalance + flowValue;
					
					poolFlowsMap[poolKey][0] <- float(poolFlowsMap[poolKey][0]) + flowValue;
					switch flowKey {
						match "IF-FromMarket" {
							poolFlowsMap["Market"][0] <- float(poolFlowsMap["Market"][0]) - flowValue;
						} match "IF-FromTranshu" {
							poolFlowsMap["Transhumance"][0] <- float(poolFlowsMap["Transhumance"][0]) - flowValue;
						} match "IF-FromAtmo" {
							ecosystemCO2Balance <- ecosystemCO2Balance + flowValue / coefCO2ToC;
							poolFlowsMap["Atmosphere"][0] <- float(poolFlowsMap["Atmosphere"][0]) - flowValue;
						}
					}
				} else if flowKey contains "OF-" {
					
					totalCOutflows <- totalCOutflows + flowValue;
					ecosystemCBalance <- ecosystemCBalance - flowValue;
					
					poolFlowsMap[poolKey][0] <- float(poolFlowsMap[poolKey][0]) - flowValue;
					switch flowKey {
						match "OF-SoldOnMarket" {
							poolFlowsMap["Market"][0] <- float(poolFlowsMap["Market"][0]) + flowValue;
						} match "OF-ToTranshu" {
							poolFlowsMap["Transhumance"][0] <- float(poolFlowsMap["Transhumance"][0]) + flowValue;
						} match_one ["OF-GHG", "OF-AtmoLosses"] {
							poolFlowsMap["Atmosphere"][0] <- float(poolFlowsMap["Atmosphere"][0]) + flowValue;
						}
					}
				} else if flowKey contains "TF-" {
					
					totalCThroughflows <- totalCThroughflows + flowValue;
					
					poolFlowsMap[poolKey][0] <- float(poolFlowsMap[poolKey][0]) - flowValue;
					poolFlowsMap[flowPool][0] <- float(poolFlowsMap[flowPool][0]) + flowValue;
				}
			}
		}
		
		// GHG
		loop subMap over: GHGFlowsMap.pairs {
			string poolKey <- subMap.key;
			map GHGMap <- subMap.value;
			loop flowPair over: GHGMap.pairs {
				string GHGKey <- flowPair.key;
				float flowValue <- float(flowPair.value);
				
				if GHGKey = "CO2" {
					totalCO2 <- totalCO2 + flowValue;
					totalGHG <- totalGHG + flowValue;
					ecosystemCO2Balance <- ecosystemCO2Balance - flowValue;
					poolFlowsMap[poolKey][2] <- float(poolFlowsMap[poolKey][2]) + flowValue;
				} else if GHGKey = "CH4" {
					totalCH4 <- totalCH4 + flowValue;
					totalGHG <- totalGHG + flowValue * PRGCH4;
					poolFlowsMap[poolKey][2] <- float(poolFlowsMap[poolKey][2]) + flowValue * PRGCH4;
				} else if GHGKey = "N2O" {
					totalN2O <- totalN2O + flowValue;
					totalGHG <- totalGHG + flowValue * PRGN2O;
					poolFlowsMap[poolKey][2] <- float(poolFlowsMap[poolKey][2]) + flowValue * PRGN2O;
				}
			}
		}
		
		// SOC		
		do getMeanSOCS;
		meanHomefieldsSOCSVariation <- meanHomefieldsSOCS - meanHomefieldsSOCSInit; // kgC
		meanBushfieldsSOCSVariation <- meanBushfieldsSOCS - meanBushfieldsSOCSInit; // kgC
		meanRangelandSOCSVariation <- meanRangelandSOCS - meanRangelandSOCSInit; // kgC
		totalMeanSOCSVariation <- totalMeanSOCS - totalMeanSOCSInit; // kgC
		
		//// Compute derivated outputs
		
		// Carbon balance
		ecosystemGHGBalance <- totalMeanSOCSVariation - totalGHG;
		
		// TST
//		float cropNVarIfNeg <- croplandNFluxMatrix["periodVarCellNstock"] < 0 ? croplandNFluxMatrix["periodVarCellNstock"] : 0.0;
//		float rangeNVarIfNeg <- rangelandNFluxMatrix["periodVarCellNstock"] < 0 ? rangelandNFluxMatrix["periodVarCellNstock"] : 0.0;
//		float herdsNVarIfNeg <- float(NFluxMap["herds"]["varHerdsNStock"]) < 0 ? float(NFluxMap["herds"]["varHerdsNStock"]) : 0.0;
//		TST <- TT + croplandNFluxMatrix["periodAtmoNFix"] + rangelandNFluxMatrix["periodAtmoNFix"] - cropNVarIfNeg - rangeNVarIfNeg - herdsNVarIfNeg;

		// ICR
		if TSTN != 0 {
			ICRN <- totalNThroughflows / TSTN;
		}
		if TSTC != 0 {
			ICRC <- totalCThroughflows / TSTC;
		}
		
	}
	
}
