/**
* In: SahelFlux
* Name: AnimalGroup
* Parent species for mobile herds and fattened animals.
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model AnimalGroup

import "Household.gaml"

global {
	
	//// Global Animals parameters
	
	// Animal constitution
	float TLUNcontent <- 5.0; // kgN TODO DUMMY
	float TLUCcontent <- 250.0; // kgN TODO DUMMY
	
	// Shared parameters for mobile and fattened
	float dailyIntakeRatePerTLU <- 6.25; // kgDM/TLU/day Maximum amount of biomass consumed daily. (Assouma et al., 2018)
	
	// Digestion parameters
	int digestionLengthParamAsInt; // More readable
	float digestionLength <- digestionLengthParamAsInt * 3600.0; // Duration of the digestion of biomass in the animals
	float ratioNExcretedOnIngested <- 0.43; // Lecomte 2002
	float ratioCExcretedOnIngested <- 0.45; // Lecomte 2002
	float ratioNUrineOnFaeces <- 0.25; // Wade 2016
	float forageEnergyContent <- 18.45; // MJ/kgDM IPCC 2019
	float urineEnergyFactor <- 0.04; // IPCC 2019; default value for cattle
}

species animalGroup virtual: true schedules: [] { // Not sure if schedules is not already empty if virtual is true.
	
	//// Parameters
	
	// Ownership
	household myHousehold;
	
	// Digestion process and continuous emissions
	list chymeChunksList;
	
	//// Functions
	
	action emitMetabo {
		// TODO emit CH4 and CO2
		
		// TODO une fonction pour vérifier que l'émis n'est pas supérieur au digéré?
	}
	
	action excrete (pair someChyme) {
		string chymeNature <- someChyme.key;
		float ingestedMS <- float(someChyme.value);
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
		
		// Return outputs
		map<string, float> digestatCharacteristics<- ["faecesNitrogen"::faecesNitrogen, "urineNirogen"::urineNirogen, "excretedCarbon"::excretedCarbon]; // TODO manque les ash et VSE, non?
		return digestatCharacteristics;

	}
	
}
