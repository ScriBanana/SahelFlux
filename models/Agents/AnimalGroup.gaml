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
	
	action digest { // TODO quid des diff de temporalité herds fattened?
	
		// Excretion after digestionLength
		list nextExcreta <- first(chymeChunksList);
		if time - float(nextExcreta[0]) > digestionLength {
			list excretaOutputs <- excrete(nextExcreta[1]);
			chymeChunksList >- first(chymeChunksList);
			return excretaOutputs;
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
				ingestedNContent <- 0.2; //TODO Dummy
				ingestedCContent <- 0.7; //TODO Dummy
				faecesAshContent <- 0.5; //TODO Dummy
				ingestedDigestibility <- 0.2; //TODO Dummy
			}

			match "Rangeland" {
				ingestedNContent <- 0.2; //TODO Dummy
				ingestedCContent <- 0.7; //TODO Dummy
				faecesAshContent <- 0.5; //TODO Dummy
				ingestedDigestibility <- 0.2; //TODO Dummy
			}

			match "FattenedRation" {
				ingestedNContent <- 0.2; //TODO Dummy
				ingestedCContent <- 0.7; //TODO Dummy
				faecesAshContent <- 0.5; //TODO Dummy
				ingestedDigestibility <- 0.2; //TODO Dummy
			}

		}
		
		// Compute outputs
		float excretedNitrogen <- ingestedMS * ingestedNContent * ratioNExcretedOnIngested;
		float faecesNitrogen <- excretedNitrogen * (1 - ratioNUrineOnFaeces);
		float urineNirogen <- excretedNitrogen * ratioNUrineOnFaeces;
		float excretedCarbon <- ingestedMS * ingestedCContent;
		float faecesAsh <- ingestedMS * faecesAshContent; // (Ash are not digested, so ash quantity is the same in ingested and excreta)
		float volatileSolidExcreted <- ingestedMS * (1 - ingestedDigestibility + urineEnergyFactor) * faecesAshContent; //TODO Besoin du forageEnergyContent ou pas ?
		
		return [faecesNitrogen, urineNirogen, excretedCarbon];

		// Variables reused in other processes :
		//	excretedCarbon in soil carbon model
		//	faecesNitrogen, urineNirogen in nitrogen available for plant growth
		//	faecesNitrogen, urineNirogen in N2O and N gases losses from soil
		//	volatileSolidExcreted in CH4 from soils
	}
	
}
