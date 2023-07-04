/**
* In: SahelFlux
* Name: ComputeOutputs
* Calculate output indicators based on recorded flows
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ComputeOutputs

import "RecordFlows.gaml"

global {
	
	float totalNFlows;
	float totalCFlows;
	float TT;
	float TST;
	float ICR;
	float CThroughflow;
	float ecosystemCBalance;
	float totalGHG;
	float SCS;
	float CFootprint;
	
	action computeOutputs {
		
		// TT
		loop subMap over: NFlowsMap { // TODO ne marchera pas si gatherflows est call plusieurs fois
			loop flowPair over: subMap.pairs {
				totalNFlows <- totalNFlows + float(flowPair.value);
				
				if flowPair.key contains "TF-" {
					TT <- TT + float(flowPair.value);
					TST <- TST + float(flowPair.value);
				} else if flowPair.key contains "IF-" {
					TST <- TST + float(flowPair.value);
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
		ICR <- TT / TST;
		
		// Carbon balance
		loop subMap over: CFlowsMap { // TODO ne marchera pas si gatherflows est call plusieurs fois
			loop flowPair over: subMap.pairs {
				totalCFlows <- totalCFlows + float(flowPair.value);
				if flowPair.key contains "TF-" {
					CThroughflow <- CThroughflow + float(flowPair.value);
				} else if flowPair.key contains "IF-" {
					ecosystemCBalance <- ecosystemCBalance + float(flowPair.value);
				} else if flowPair.key contains "OF-" {
					ecosystemCBalance <- ecosystemCBalance - float(flowPair.value);
				}
			}
		}
	}
}
