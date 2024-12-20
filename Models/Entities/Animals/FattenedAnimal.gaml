/**
* In: SahelFlux
* Name: FattenedAnimal
* Fattened animals mechanisms
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "AnimalGroup.gaml"

global {
	
	//// Global fattening parameters and variables
	
	float meanFattenedGroupSize; // TLU
	
	float fattenedTLUDailyIntake <- 9.59; // kgDM/TLU/day Ndiaye 2022 TODO too high. 7.5 Valenza
	float strawInFattenedTLUDailyRation <- 2.79; // kgDM/TLU/day Ndiaye 2022, Audouin 2014
	
	float weightWhenSold <- 320.0; // kg Valenza, 1971 TODO Probably too much
	float ratioWeightSoldOnBought <- weightWhenSold / weightTLU;
	
	float increaseNbTLUBoughtPerTLUSold <- 0.5; // For each TLU sold last season, increase in chance to aquire a new one. Arbitrary value
	
	// Variables
	float fattenedIntakeFlow;
	float fattenedExcretionsFlow;
	float complementsInflow;
	
}

species fattenedAnimal parent: animalGroup schedules: [] {
	
	//// Parameters
	
	float groupSize; // TLU
	
	//// Functions
	
	action fattenedEat {
		float eatenQuantity <- fattenedTLUDailyIntake * groupSize;
		float eatenStraw <- strawInFattenedTLUDailyRation * groupSize;
		
		// Follows global grazing rate
		fattenedIntakeFlow <- fattenedIntakeFlow + eatenQuantity;
		
		// Metabolise and prepare for excretion
		do emitMetaboIntake("FattenedRation", eatenQuantity);
		chymeChunksList <+ [time, "FattenedRation"::eatenQuantity];
		
		// Save flows and remove from straw pile if need be
		// TODO refusals not taken into account
		if myHousehold.myForagePileBiomassContent >= eatenStraw {
			myHousehold.myForagePileBiomassContent <- myHousehold.myForagePileBiomassContent - eatenStraw;
			ask world {	do saveFlowInMap("C", "StrawPiles", "TF-ToFattenedAn", eatenStraw * milletStrawCContent);}
			ask world {	do saveFlowInMap("N", "StrawPiles", "TF-ToFattenedAn", eatenStraw * milletStrawNContent);}
		} else {
			ask world {	do saveFlowInMap("C", "FattenedAn", "IF-FromMarket", eatenStraw * milletStrawCContent);}
			ask world {	do saveFlowInMap("N", "FattenedAn", "IF-FromMarket", eatenStraw * milletStrawNContent);}
		}
		
		ask world {	do saveFlowInMap("C", "FattenedAn", "IF-FromMarket", (eatenQuantity - eatenStraw) * fattenedComplementsNContent);}
		ask world {	do saveFlowInMap("N", "FattenedAn", "IF-FromMarket", (eatenQuantity - eatenStraw) * fattenedComplementsCContent);}
		
		complementsInflow <- complementsInflow + eatenQuantity - eatenStraw;
	}
	
	action fattenedDigest {
		if !empty(chymeChunksList) {
			// Compute excreted OM
			loop while: !empty(chymeChunksList)  {
				map excretaOutputs <- excrete(first(chymeChunksList)[1]);
				chymeChunksList >- first(chymeChunksList);
				
				// Follows global grazing rate
				fattenedExcretionsFlow <- fattenedExcretionsFlow + float(excretaOutputs["excretedDM"]);
				
				myHousehold.myORPHeap.heapFattenedInput <+ [
					excretaOutputs["volatileSolidExcreted"],
					excretaOutputs["excretedCarbon"],
					float(excretaOutputs["faecesNitrogen"]),
					float(excretaOutputs["urineNirogen"])
				];
				
				ask world {	do saveFlowInMap("C", "FattenedAn", "TF-ToORPHeaps" , float(excretaOutputs["excretedCarbon"]));}
				ask world {	do saveFlowInMap("N", "FattenedAn", "TF-ToORPHeaps" ,
					float(excretaOutputs["faecesNitrogen"]) + float(excretaOutputs["urineNirogen"])
				);}
				
			}
			chymeChunksList <- [];
		}
	}
}
