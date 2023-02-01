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
	
	action emitMetabo {
		// TODO emit CH4 and CO2
		
		// TODO une fonction pour vérifier que l'émis n'est pas supérieur au digéré?
	}
	
	action excrete (pair someChyme) { //Virtual: true ?
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
		
		// Compute outputs, used in other processes :
		// In nitrogen available for plant growth and N2O and N gases losses from soil
		float excretedNitrogen <- ingestedMS * ingestedNContent * ratioNExcretedOnIngested;
		float faecesNitrogen <- excretedNitrogen * (1 - ratioNUrineOnFaeces);
		float urineNirogen <- excretedNitrogen * ratioNUrineOnFaeces;
		 // In soil carbon model
		float excretedCarbon <- ingestedMS * ingestedCContent;
		// In CH4 from soils
		float faecesAsh <- ingestedMS * faecesAshContent; // (Ash are not digested, so ash quantity is the same in ingested and excreta)
		float volatileSolidExcreted <- ingestedMS * (1 - ingestedDigestibility + urineEnergyFactor) * faecesAshContent; //TODO Besoin du forageEnergyContent ou pas ?
		
		map<string, float> digestatCharacteristics<- ["faecesNitrogen"::faecesNitrogen, "urineNirogen"::urineNirogen, "excretedCarbon"::excretedCarbon];
		return digestatCharacteristics;

	}
	
}
