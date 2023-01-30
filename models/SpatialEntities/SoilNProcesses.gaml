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
	
}

species soilNProcesses {
	landscape myCell;
	map<string, float> NInflows <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	map<string, float> thisYearAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	map<string, float> nextYearAfterEffect <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	
	action computeNAvailable {
		// TODO Virer les emissions
		
		// Computing after-effect from the period NInflows
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
		
		//float NAvailable <- sum(NInflowsDirectlyMineralised) + sum(thisYearAfterEffect);
		
		// Updating after effect memory variables
		loop inputType over: thisYearAfterEffect.keys {
			thisYearAfterEffect[inputType] <- NInflowsNextYearAfterEffect[inputType] + nextYearAfterEffect[inputType];
		}
		nextYearAfterEffect <- NInflowsInTwoYearsAfterEffect;
	}
	
}


