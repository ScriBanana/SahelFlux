/**
* In: SahelFlux
* Name: SNstock
* Soil nitrogen stock
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SoilNProcesses

import "Landscape.gaml"
import "../../OutputProcesses/RecordFlows.gaml"

global {
	
	//// Global soil N parameters
	
	map<string, list> dungMineraPercentMatrix <- [ // Proportion of N available over the years for : 
		"HerdsDung"::[0.6, 0.4, 0.0],
		"HerdsUrine"::[1.0, 0.0, 0.0],
		"ORP"::[0.4, 0.3, 0.3],
		"MineralFerti"::[1.0, 0.0, 0.0]
	];
	
	// N gases emission factors
	float emissionFactorN2ODeposits <- 0.005; // IPCC t11.1
	float emissionFactorN2ODungUrine <- 0.002; // IPCC t11.1
	float fractionGasLossMineralFerti <- 0.15; // IPCC t11.3
	float fractionGasLossOrganicFerti <- 0.21; // IPCC t11.3
	
}

species soilNProcesses parallel: true schedules: [] {
	
	//// Parameters
	
	landscape myCell;
	// Inflows of N within all other processes (public)
	map<string, float> NInflows <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	// Memory variables
	map<string, float> thisYearAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	map<string, float> nextYearAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	
	float gasLossNToEmitInRS; // kgN TODO emit at some point (register in matrix?)
	
	//// Functions
	
	float computeNAvailable { // Yearly
		
		float NFromSoil <- computeNFromSoil();
		list<float> NAtmo <- computeNAtmo();
		map<string, float> NFromDepositsAndAfterEffect<- computeNDepositsAndAfterEffect();
		
		float NAvailable <- NFromSoil + sum(NAtmo) + sum(NFromDepositsAndAfterEffect);
		assert NAvailable >=0;
		return NAvailable;
	}
	
	float computeNFromSoil {
		float NFromSoil <- (myCell.myParcel != nil and myCell.myParcel.homeField) ?
			baseNFromSoilHomefields :
			baseNFromSoilBushfields;
		// Will return the value for bushfields in cropland not part of a parcel and rangeland.
		// TODO Value for rangeland? Nothing in Grillot.
		
		// Version + should account for SOC.
		
		return NFromSoil;
	}
	
	list<float> computeNAtmo {
		
		// TODO étaler dans l'année
		// TODO Valider le groundnut
		
		float NAtmoMicroOrga <- baseNAtmoMicroOrga;
		float NAtmoGroundnut <- myCell.myParcel != nil and
			myCell.myParcel.nextRSCover = "Groundnut" ? baseNAtmoGroundnut : 0.0;
		float NAtmoFromTrees <- baseNAtmoPerTree * myCell.nbTrees;
		
		string inflowRecievingPool <- myCell.cellLU = "Rangeland" ?
			"Rangelands" :
			(myCell.myParcel != nil and myCell.myParcel.homeField ? "HomeFields" : "BushFields");
		string treeFixationRecievingPool <- myCell.cellLU = "Rangeland" ?
			"TF-ToRangelands" :
			(myCell.myParcel != nil and myCell.myParcel.homeField ? "TF-ToHomeFields" : "TF-ToBushFields");
		ask world {	do saveFlowInMap("N", inflowRecievingPool, "IF-FromAtmo", NAtmoMicroOrga);}
		ask world {	do saveFlowInMap("N", inflowRecievingPool, "IF-FromAtmo", NAtmoGroundnut);}
		ask world {	do saveFlowInMap("N", "Trees", "IF-FromAtmo", NAtmoFromTrees);} // TODO Ajouter la captation pas envoyée au sol?
		ask world {	do saveFlowInMap("N", "Trees", treeFixationRecievingPool, NAtmoFromTrees);}
		
		return [NAtmoMicroOrga, NAtmoGroundnut, NAtmoFromTrees];
	}
	
	map<string, float> computeNDepositsAndAfterEffect {
		
		// Computing directly mineralised N and after-effect from the period NInflows
		// Emissions and gas losses must be removed at the source (temporality discrepancy)
		map<string, float> NInflowsDirectlyMineralised <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
		map<string, float> NInflowsNextYearAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
		map<string, float> NInflowsInTwoYearsAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
		int yearInt <- 0;
		loop minNList over: [NInflowsDirectlyMineralised, NInflowsNextYearAfterEffect, NInflowsInTwoYearsAfterEffect] {
			loop inputType over: minNList.keys {
				minNList[inputType] <- NInflows[inputType] * float((dungMineraPercentMatrix[inputType])[yearInt]);
			}
			yearInt <- yearInt + 1;
		}
		
		// Saving direct mineralisation and after effect for following years
		map<string, float> NFromDeposits <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
		loop inputType over: NFromDeposits.keys {
			NFromDeposits[inputType] <- NInflowsDirectlyMineralised[inputType] + thisYearAfterEffect[inputType];
			thisYearAfterEffect[inputType] <- NInflowsNextYearAfterEffect[inputType] + nextYearAfterEffect[inputType];
		}
		nextYearAfterEffect <- NInflowsInTwoYearsAfterEffect;
		
		return NFromDeposits;
	}
	
}


