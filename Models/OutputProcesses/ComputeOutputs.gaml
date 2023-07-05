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
	float totalNFlows;
	float totalNInflows;
	float totalNThroughflows;
	float totalNOutflows;
	float totalCFlows;
	float totalCInflows;
	float totalCThroughflows;
	float totalCOutflows;
	
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
	float ecosystemCO2Balance; // kgCO2; used for validation
	float ecosystemGHGBalance; // kgCO2eq
	float SCS;
	float CFootprint;
	
	
	//// Output computer ////
	
	action computeOutputs {
		
		// Nitrogen
		loop subMap over: NFlowsMap { // TODO ne marchera pas si gatherflows est call plusieurs fois
			loop flowPair over: subMap.pairs {
				totalNFlows <- totalNFlows + float(flowPair.value);
				if flowPair.key contains "TF-" {
					totalNThroughflows <- totalNThroughflows + float(flowPair.value);
					TSTN <- TSTN + float(flowPair.value);
				} else if flowPair.key contains "IF-" {
					totalNInflows <- totalNInflows + float(flowPair.value);
					TSTN <- TSTN + float(flowPair.value);
				} else if flowPair.key contains "OF-" {
					totalNOutflows <- totalNOutflows + float(flowPair.value);
				}
			}
		}
		
		// Carbon
		loop subMap over: CFlowsMap { // TODO ne marchera pas si gatherflows est call plusieurs fois
			loop flowPair over: subMap.pairs {
				totalCFlows <- totalCFlows + float(flowPair.value);
				if flowPair.key contains "TF-" {
					totalCThroughflows <- totalCThroughflows + float(flowPair.value);
				} else if flowPair.key contains "IF-" {
					totalCInflows <- totalCInflows + float(flowPair.value);
					ecosystemCBalance <- ecosystemCBalance + float(flowPair.value);
				} else if flowPair.key contains "OF-" {
					totalCOutflows <- totalCOutflows + float(flowPair.value);
					ecosystemCBalance <- ecosystemCBalance - float(flowPair.value);
				}
			}
		}
		
		// GHG
		loop subMap over: GHGFlowsMap {
			loop flowPair over: subMap.pairs {
				if flowPair.key = "CO2" {
					totalCO2 <- totalCO2 + float(flowPair.value);
					totalGHG <- totalGHG + float(flowPair.value);
				} else if flowPair.key = "CH4" {
					totalCH4 <- totalCH4 + float(flowPair.value);
					totalGHG <- totalGHG + float(flowPair.value) * PRGCH4;
				} else if flowPair.key = "N2O" {
					totalN2O <- totalN2O + float(flowPair.value);
					totalGHG <- totalGHG + float(flowPair.value) * PRGN2O;
				}
			}
		}
		
		
		// TST
//		float cropNVarIfNeg <- croplandNFluxMatrix["periodVarCellNstock"] < 0 ? croplandNFluxMatrix["periodVarCellNstock"] : 0.0;
//		float rangeNVarIfNeg <- rangelandNFluxMatrix["periodVarCellNstock"] < 0 ? rangelandNFluxMatrix["periodVarCellNstock"] : 0.0;
//		float herdsNVarIfNeg <- float(NFluxMap["herds"]["varHerdsNStock"]) < 0 ? float(NFluxMap["herds"]["varHerdsNStock"]) : 0.0;
//		TST <- TT + croplandNFluxMatrix["periodAtmoNFix"] + rangelandNFluxMatrix["periodAtmoNFix"] - cropNVarIfNeg - rangeNVarIfNeg - herdsNVarIfNeg;

		// ICR
		ICRN <- totalNThroughflows / TSTN;
		ICRC <- totalCThroughflows / TSTC;
		
	}
}
