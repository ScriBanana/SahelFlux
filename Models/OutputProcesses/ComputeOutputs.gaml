/**
* In: SahelFlux
* Name: ComputeOutputs
* Calculate output indicators based on recorded flows
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ComputeOutputs

import "RecordFlows.gaml"

global {
	
	float TT;
	float TST;
	float ICR;
	float CThroughflow;
	
	action computeOutputs {
		
		// TT
		loop subMap over: NFlowsMap { // TODO ne marchera pas si gatherflows est call plusieurs fois
			loop flowPair over: subMap.pairs where (each.key contains "TF-") {
				TT <- TT + float(flowPair.value);
			}
		}
		write "		TT : " + int(floor(TT)) + " kgN";

		// TST
//		float cropNVarIfNeg <- croplandNFluxMatrix["periodVarCellNstock"] < 0 ? croplandNFluxMatrix["periodVarCellNstock"] : 0.0;
//		float rangeNVarIfNeg <- rangelandNFluxMatrix["periodVarCellNstock"] < 0 ? rangelandNFluxMatrix["periodVarCellNstock"] : 0.0;
//		float herdsNVarIfNeg <- float(NFluxMap["herds"]["varHerdsNStock"]) < 0 ? float(NFluxMap["herds"]["varHerdsNStock"]) : 0.0;
//		TST <- TT + croplandNFluxMatrix["periodAtmoNFix"] + rangelandNFluxMatrix["periodAtmoNFix"] - cropNVarIfNeg - rangeNVarIfNeg - herdsNVarIfNeg;

		// ICR
//		ICR <- TT / TST;

		// Prompt
//		write "		TST : " + TST / hectareToCell + " kgN/ha";
//		write "		ICR : " + ICR;
		
		// Carbon balance
		loop subMap over: CFlowsMap { // TODO ne marchera pas si gatherflows est call plusieurs fois
			loop flowPair over: subMap.pairs where (each.key contains "TF-") {
				CThroughflow <- CThroughflow + float(flowPair.value);
			}
		}
		write "		C throughflow : " + int(floor(CThroughflow)) + " kgC";
	}
}
