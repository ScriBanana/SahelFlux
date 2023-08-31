/**
* In: SahelFlux
* Name: SNstock
* Soil nitrogen stock
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "Landscape.gaml"

global {
	
	//// Global soil N parameters
	
	float baseNFromSoilHomefieldsHa <- 27.5 const: true; // kgN/ha const: true; Grillot et al., 2018
	float baseNFromSoilBushfieldsHa <- 12.0 const: true; // kgN/ha const: true; Grillot et al., 2018
	float baseNAtmoMicroOrgaHa <- 7.5 const: true; // kgN/ha const: true; Grillot et al., 2018
	float baseNAtmoGroundnutHa <- 20.0 const: true; // kgN/ha const: true; Grillot et al., 2018
	float baseNFromSoilHomefields <- baseNFromSoilHomefieldsHa * hectareToCell const: true; // kgN/cell
	float baseNFromSoilBushfields <- baseNFromSoilBushfieldsHa * hectareToCell const: true; // kgN/cell
	float baseNAtmoMicroOrga <- baseNAtmoMicroOrgaHa * hectareToCell const: true; // kgN/cell
	float baseNAtmoGroundnut <- baseNAtmoGroundnutHa * hectareToCell const: true; // kgN/cell
	float baseNAtmoPerTree <- 4.0 const: true; // kgN const: true; Grillot et al., 2018
	
	map<string, list> dungMineraPercentMatrix <- [ // Proportion of N available over the years for : 
		"HerdsDung"::[0.6, 0.4, 0.0],
		"HerdsUrine"::[1.0, 0.0, 0.0],
		"ORP"::[0.4, 0.3, 0.3],
		"MineralFerti"::[1.0, 0.0, 0.0]
	] const: true;
	
	// SOC on available N model parameters
	bool SOCxSONOn <- true;
	map<string, float> SOCxSONAlphaMap <- [ // Results 
		"Sob"::0.00429341487873358, "Barry"::-0.0167503557994896, "Diohine"::0.00197924761695453];
	map<string, float> SOCxSONBetaMap <- [
		"Sob"::-9.93564377647462, "Barry"::68.592209925106, "Diohine"::-2.93033048272559];
	
	// Gather NFrom soils for SOCxSON calibration
	list<float> gatherNFromSoils {
		float meanHomefieldsLastNFromSoil;
		float meanBushfieldsLastNFromSoil;
		float meanRangelandLastNFromSoil;
		
		meanHomefieldsLastNFromSoil <- (soilNProcesses where (each.myCell.homefieldCell)) mean_of each.lastNFromSoil;
		meanBushfieldsLastNFromSoil <- (
			soilNProcesses where (each.myCell.cellLU = "Cropland" and !each.myCell.homefieldCell)
		) mean_of each.lastNFromSoil;
		meanRangelandLastNFromSoil <- (
			soilNProcesses where (each.myCell.cellLU = "Rangeland")
		) mean_of each.lastNFromSoil;
		
		return [meanHomefieldsLastNFromSoil, meanBushfieldsLastNFromSoil, meanRangelandLastNFromSoil];
	}
	
}

species soilNProcesses parallel: true schedules: [] {
	
	//// Parameters
	
	landscape myCell;
	// Inflows of N within all other processes (public)
	map<string, float> NInflows <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	// Memory variables
	map<string, float> thisYearAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	map<string, float> nextYearAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	float lastNFromSoil;
	
	float soilGasLossNToEmitInRS; // kgN TODO emit at some point (register in matrix?)
	
	//// Functions
	
	float computeNAvailable { // Yearly
		
		float computedNFromSoil <- computeNFromSoil();
		lastNFromSoil <- computedNFromSoil;
		list<float> NAtmo <- computeNAtmo();
		map<string, float> NFromDepositsAndAfterEffect<- computeNDepositsAndAfterEffect();
		
		float NAvailable <- computedNFromSoil + sum(NAtmo) + sum(NFromDepositsAndAfterEffect);
		assert NAvailable >=0;
		return NAvailable;
	}
	
	float computeNFromSoil {
		float NFromSoil;
		
		if !SOCxSONOn {
			NFromSoil <- myCell.homefieldCell ?
				baseNFromSoilHomefields :
				baseNFromSoilBushfields;
			// Will return the value for bushfields in cropland not part of a parcel and rangeland.
			// TODO Value for rangeland? Nothing in Grillot.
		} else {
			NFromSoil <- SOCxSONAlphaMap[villageName] * myCell.mySOCstock.stableCPool + SOCxSONBetaMap[villageName];
		}
		
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
			(myCell.homefieldCell ? "HomeFields" : "BushFields");
		string fixationRecievingPool <- myCell.cellLU = "Rangeland" ?
			"TF-ToRangelands" :
			(myCell.homefieldCell ? "TF-ToHomeFields" : "TF-ToBushFields");
		ask world {	do saveFlowInMap("N", inflowRecievingPool, "IF-FromAtmo", NAtmoMicroOrga);}
		ask world {	do saveFlowInMap("N", "Groundnut", "IF-FromAtmo", NAtmoGroundnut);}
		ask world {	do saveFlowInMap("N", "Groundnut", fixationRecievingPool, NAtmoGroundnut);}
		ask world {	do saveFlowInMap("N", "Trees", "IF-FromAtmo", NAtmoFromTrees);} // TODO Ajouter la captation pas envoyée au sol?
		ask world {	do saveFlowInMap("N", "Trees", fixationRecievingPool, NAtmoFromTrees);}
		
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


