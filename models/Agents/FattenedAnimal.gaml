/**
* In: SahelFlux
* Name: FattenedAnimal
* Based on the internal empty template. 
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model FattenedAnimal


import "AnimalGroup.gaml"

species fattenedAnimal parent: animalGroup {
	
	action eat { // reflex ou scheduler?
		float eatenQuantity <- 6.0; //TODO DUMMY
		// ask stock du household >- eatenQuantity
		chymeChunksList <+ [time, "FattenedRation"::eatenQuantity];
	}
}
