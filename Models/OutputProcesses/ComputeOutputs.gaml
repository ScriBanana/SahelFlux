/**
* In: SahelFlux
* Name: ComputeOutputs
* Calculate output indicators based on recorded flows
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ComputeOutputs

import "RecordFlows.gaml"
import "RecordGHG.gaml"

global {
	
	// Global flows
	float totalNFlows;
	float totalCFlows;
	
	// Circularity (ENA framework)
	float TTN;
	float TSTN;
	float ICRN;
	float FinnN;
	float TTC;
	float TSTC;
	float ICRC;
	float FinnC;
	
	// GHG
	float totalCO2;
	float totalCH4;
	float totalN2O;
	float totalGHG;
	
	// Carbon balance
	float ecosystemCBalance;
	float ecosystemCO2Balance; // kgCO2; used for validation
	float ecosystemGHGBalance; // kgCO2eq
	float SCS;
	float CFootprint;
	
	action computeOutputs {
		
		// TT
		loop subMap over: NFlowsMap { // TODO ne marchera pas si gatherflows est call plusieurs fois
			loop flowPair over: subMap.pairs {
				totalNFlows <- totalNFlows + float(flowPair.value);
				
				if flowPair.key contains "TF-" {
					TTN <- TTN + float(flowPair.value);
					TSTN <- TSTN + float(flowPair.value);
				} else if flowPair.key contains "IF-" {
					TSTN <- TSTN + float(flowPair.value);
				} else if flowPair.key contains "OF-" {
					
				}
			}
		}
		
		// TST
//		float cropNVarIfNeg <- croplandNFluxMatrix["periodVarCellNstock"] < 0 ? croplandNFluxMatrix["periodVarCellNstock"] : 0.0;
//		float rangeNVarIfNeg <- rangelandNFluxMatrix["periodVarCellNstock"] < 0 ? rangelandNFluxMatrix["periodVarCellNstock"] : 0.0;
//		float herdsNVarIfNeg <- float(NFluxMap["herds"]["varHerdsNStock"]) < 0 ? float(NFluxMap["herds"]["varHerdsNStock"]) : 0.0;
//		TST <- TT + croplandNFluxMatrix["periodAtmoNFix"] + rangelandNFluxMatrix["periodAtmoNFix"] - cropNVarIfNeg - rangeNVarIfNeg - herdsNVarIfNeg;

		// ICR
		ICRN <- TTN / TSTN;
		
		// Carbon balance
		loop subMap over: CFlowsMap { // TODO ne marchera pas si gatherflows est call plusieurs fois
			loop flowPair over: subMap.pairs {
				totalCFlows <- totalCFlows + float(flowPair.value);
				if flowPair.key contains "TF-" {
					TTC <- TTC + float(flowPair.value);
				} else if flowPair.key contains "IF-" {
					ecosystemCBalance <- ecosystemCBalance + float(flowPair.value);
				} else if flowPair.key contains "OF-" {
					ecosystemCBalance <- ecosystemCBalance - float(flowPair.value);
				}
			}
		}
	}
}
