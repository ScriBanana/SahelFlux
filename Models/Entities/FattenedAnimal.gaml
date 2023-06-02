/**
* In: SahelFlux
* Name: FattenedAnimal
* Fattened animals mechanisms
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model FattenedAnimal

import "AnimalGroup.gaml"

global {
	
	//// Global fattening parameters
	
	float meanFattenedGroupSize <- 1.0; // TLU TODO DUMMY
	float increaseNbTLUBoughtPerTLUSold <- 0.5; // For each TLU sold last season, increase in chance to aquire a new one. Arbitrary value
	
	float fattenedTLUDailyIntake <- 9.59; // kgDM/TLU/day Ndiaye 2022
	
}

species fattenedAnimal parent: animalGroup schedules: [] {
	
	//// Parameters
	
	float groupSize; // TLU
	
	//// Functions
	
	action eat {
		float eatenQuantity <- fattenedTLUDailyIntake * groupSize;
		
		// TODO ask stock du household >- eatenQuantity
		
		
		
		chymeChunksList <+ [time, "FattenedRation"::eatenQuantity];
		do emitMetaboIntake("FattenedRation", eatenQuantity);
		ask world {	do saveFlowInMap("C", "FattenedAn", "IF-FromMarket", eatenQuantity * fattenedRationCContent);}
		ask world {	do saveFlowInMap("N", "FattenedAn", "IF-FromMarket", eatenQuantity * fattenedRationNContent);}
	}
	
	action fattenedDigest { // reflex ou scheduler?
		loop chymeChunk over: chymeChunksList {
			list excretaOutputs <- excrete(chymeChunk[1]);
			//ask currentCell   excretaOutputs
		}
		chymeChunksList <- [];
	}
}
