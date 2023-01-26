/**
* In: SahelFlux
* Name: AnimalGroup
* Parent species for mobile herds and fattened animals.
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model AnimalGroup

import "MobileHerd.gaml"
import "FattenedAnimal.gaml"

global {
	// Digestion parameters
	float digestionLength <- 20.0 #h; // Duration of the digestion of biomass in the animals (expert knowledge -> ref ou préciser?)
	float ratioNExcretedOnIngested <- 0.43; // Lecomte 2002
	float ratioCExcretedOnIngested <- 0.45; // Lecomte 2002
	float ratioNUrineOnFaeces <- 0.25; // Wade 2016
	float forageEnergyContent <- 18.45; // MJ/kgDM IPCC 2019
	float urineEnergyFactor <- 0.04; // IPCC 2019; default value for cattle
}

species animalGroup {
	
	// Digestion process and continuous emissions
	list chymeChunksList;
	
	reflex digest when: !empty(chymeChunksList) {
		
		do emitMetabo;
		
		// Excretion after digestionLength
		list nextExcreta <- first(chymeChunksList);
		if time - float(nextExcreta[0]) > digestionLength {
			do excrete(nextExcreta[1]);
			chymeChunksList >- first(chymeChunksList);
		}
	}
	
	action emitMetabo {
		// TODO emit CH4 and CO2
		
		// TODO une fonction pour vérifier que l'émis n'est pas supérieur au digéré?
	}
	
	action excrete (pair someChyme) {
		string chymeNature <- someChyme.value;
		float ingestedMS <- float(someChyme.key);

		// Ration type specific variables
		float ingestedNContent;
		float ingestedCContent;
		float faecesAshContent;
		float ingestedDigestibility;
		switch chymeNature {
			match "Cropland" {
				ingestedNContent <- 1.0; //TODO Dummy
				ingestedCContent <- 1.0; //TODO Dummy
				faecesAshContent <- 0.5; //TODO Dummy
				ingestedDigestibility <- 0.2; //TODO Dummy
			}

			match "Rangeland" {
				ingestedNContent <- 1.0; //TODO Dummy
				ingestedCContent <- 1.0; //TODO Dummy
				faecesAshContent <- 0.5; //TODO Dummy
				ingestedDigestibility <- 0.2; //TODO Dummy
			}

			match "FattenedRation" {
				ingestedNContent <- 1.0; //TODO Dummy
				ingestedCContent <- 1.0; //TODO Dummy
				faecesAshContent <- 0.5; //TODO Dummy
				ingestedDigestibility <- 0.2; //TODO Dummy
			}

		}
		
		// Compute outputs
		float excretedNitrogen <- ingestedMS * ingestedNContent * ratioNExcretedOnIngested;
		float faecesNitrogen <- excretedNitrogen * (1 - ratioNUrineOnFaeces);
		float urineNirogen <- excretedNitrogen * ratioNUrineOnFaeces;
		float excretedCarbon <- ingestedMS * ingestedCContent;
		float faecesAsh <- ingestedMS * faecesAshContent; // (Ash are not digested, so ash quantity is the same)
		
		// Input data for relevant processes
		float soilCInput;
		float soilNOrganicDeposit;
		float volatileSolidExcreted <- ingestedMS * (1 - ingestedDigestibility + urineEnergyFactor) * faecesAshContent; //Besoin du forageEnergyContent ou pas ?

		// Sorties : excretedCarbon, faecesNitrogen, urineNirogen
	}
	
}
