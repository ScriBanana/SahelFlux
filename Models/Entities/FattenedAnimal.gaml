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
	
	float meanFattenedGroupSize <- 1.0; // TODO DUMMY
	float increaseNbTLUBoughtPerTLUSold <- 0.5; // For each TLU sold last season, increasin in chance to aquire a new one. Arbitrary value
	
}

species fattenedAnimal parent: animalGroup schedules: [] {
	
	//// Parameters
	
	float groupSize; // TLU
	
	//// Functions
	
	action eat {
		float eatenQuantity <- 6.0; //TODO DUMMY
		// ask stock du household >- eatenQuantity
		chymeChunksList <+ [time, "FattenedRation"::eatenQuantity];
	}
	
	action fattenedDigest { // reflex ou scheduler?
		loop chymeChunk over: chymeChunksList {
			list excretaOutputs <- excrete(chymeChunk[1]);
			//ask currentCell   excretaOutputs
		}
		chymeChunksList <- [];
	}
}
