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
	
	// SOC
	float meanHomefieldsSOCS;
	float meanBushfieldsSOCS;
	float meanRangelandSOCS;
	float totalMeanSOCS;
	
	
	//// Output computer ////
	
	action computeOutputs {
		
		//// Gather flows
		
		// Nitrogen
		loop subMap over: NFlowsMap { // TODO ne marchera pas si gatherflows est call plusieurs fois
			loop flowPair over: subMap.pairs {
				string flowKey <- flowPair.key;
				float flowValue <- float(flowPair.value);
				
				totalNFlows <- totalNFlows + flowValue;
				if flowKey contains "TF-" {
					totalNThroughflows <- totalNThroughflows + flowValue;
					TSTN <- TSTN + flowValue;
				} else if flowKey contains "IF-" {
					totalNInflows <- totalNInflows + flowValue;
					TSTN <- TSTN + flowValue;
				} else if flowKey contains "OF-" {
					totalNOutflows <- totalNOutflows + flowValue;
				}
			}
		}
		
		// Carbon
		loop subMap over: CFlowsMap {
			loop flowPair over: subMap.pairs {
				string flowKey <- flowPair.key;
				float flowValue <- float(flowPair.value);
				
				totalCFlows <- totalCFlows + flowValue;
				if flowKey contains "TF-" {
					totalCThroughflows <- totalCThroughflows + flowValue;
				} else if flowKey contains "IF-" {
					totalCInflows <- totalCInflows + flowValue;
					ecosystemCBalance <- ecosystemCBalance + flowValue;
					if flowKey = "IF-FromAtmo" {
						ecosystemCO2Balance <- ecosystemCO2Balance + flowValue / coefCO2ToC;
					}
				} else if flowKey contains "OF-" {
					totalCOutflows <- totalCOutflows + flowValue;
					ecosystemCBalance <- ecosystemCBalance - flowValue;
				}
			}
		}
		
		// GHG
		loop subMap over: GHGFlowsMap {
			loop flowPair over: subMap.pairs {
				string flowKey <- flowPair.key;
				float flowValue <- float(flowPair.value);
				
				if flowKey = "CO2" {
					totalCO2 <- totalCO2 + flowValue;
					totalGHG <- totalGHG + flowValue;
					ecosystemCO2Balance <- ecosystemCO2Balance - flowValue;
				} else if flowKey = "CH4" {
					totalCH4 <- totalCH4 + flowValue;
					totalGHG <- totalGHG + flowValue * PRGCH4;
				} else if flowKey = "N2O" {
					totalN2O <- totalN2O + flowValue;
					totalGHG <- totalGHG + flowValue * PRGN2O;
				}
			}
		}
		
		// SOC		
		meanHomefieldsSOCS <- (
			SOCStock where (each.myCell.cellLU = "Cropland" and each.myCell.myParcel != nil and each.myCell.myParcel.homeField)
		) mean_of each.stableCPool;
		meanBushfieldsSOCS <- (
			SOCStock where (each.myCell.cellLU = "Cropland" and (each.myCell.myParcel = nil or !each.myCell.myParcel.homeField))
		) mean_of each.stableCPool;
		meanRangelandSOCS <- (
			SOCStock where (each.myCell.cellLU = "Rangeland")
		) mean_of each.stableCPool;
		// TODO Unoptimised triple loop
		totalMeanSOCS <- meanHomefieldsSOCS + meanBushfieldsSOCS + meanRangelandSOCS;
	
		//// Compute derivated outputs
		
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
