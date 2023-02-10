/**
* In: SahelFlux
* Name: FattenedAnimal
* Based on the internal empty template. 
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model FattenedAnimal


import "AnimalGroup.gaml"

species fattenedAnimal parent: animalGroup schedules: [] {
	
	action eat { // reflex ou scheduler?
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
