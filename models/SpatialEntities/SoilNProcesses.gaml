/**
* In: SahelFlux
* Name: SNstock
* Soil nitrogen stock
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SoilNProcesses

import "Landscape.gaml"

global {
	map<string, list> dungMineraPercentMatrix <- [ // N available over the years for : 
		"HerdsDung"::[0.6, 0.4, 0.0],
		"HerdsUrine"::[1.0, 0.0, 0.0],
		"ORP"::[0.4, 0.3, 0.3],
		"MineralFerti"::[1.0, 0.0, 0.0]
	];
	
	float baseNFromSoilHomefields <- 27.5; // kgN/ha; Grillot et al., 2018
	float baseNFromSoilBushfields <- 12.0; // kgN/ha; Grillot et al., 2018
	float baseNAtmoMicroOrga <- 7.5; // kgN/ha; Grillot et al., 2018
	float baseNAtmoGroundnut <- 20.0; // kgN/ha; Grillot et al., 2018
	float baseNAtmoPerTree <- 4.0; // kgN; Grillot et al., 2018
	
}

species soilNProcesses {
	landscape myCell;
	// Inflows of N within all other processes (public)
	map<string, float> NInflows <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	// Memory variables
	map<string, float> thisYearAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	map<string, float> nextYearAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	
	float computeNAvailable {
		
		float NFromSoil <- computeNFromSoil();
		list<float> NAtmo <- computeNAtmo();
		map<string, float> NFromDepositsAndAfterEffect<- computeNDepositsAndAfterEffect();
		
		float NAvailble <- NFromSoil + sum(NAtmo) + sum(NFromDepositsAndAfterEffect);
		return NAvailble;
	}
	
	float computeNFromSoil {
		float NFromSoil <- myCell.myParcel.homeField ? baseNFromSoilHomefields : baseNFromSoilBushfields; // Will return the value for bushfields in cropland not part of a parcel and rangeland.
		// TODO Value for rangeland?
		return NFromSoil;
	}
	
	list<float> computeNAtmo {
		float NAtmoMicroOrga <- baseNAtmoMicroOrga;
		float NAtmoGroundnut <- baseNAtmoGroundnut;
		float NAtmoFromTrees <- baseNAtmoPerTree * myCell.nbTrees;
		return;
	}
	
	map<string, float> computeNDepositsAndAfterEffect {
		// TODO Virer les emissions
		
		// Computing directly mineralised N and after-effect from the period NInflows
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


