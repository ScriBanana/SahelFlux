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
	float fattenedRationEnergyContent <- 16.24; // MJ/kgDM Surveys, INRA 2018, Feedipedia
	// TODO Corriger avec le Jarga
	float milletResiduesEnergyContent <- 17.17; // MJ/kgDM INRA 2018
	float forageEnergyContentDS <- 18.67; // MJ/kgDM INRA 2018
	float forageEnergyContentRS <- 17.94; // MJ/kgDM INRA 2018 (mean value)
	float urineEnergyFactor <- 0.04; // IPCC 2019; default value for cattle
	
	// TODO à grouper dans un fichier param
	// Carboned gases parameters
	float coefCO2ToC <- 0.2729; // Proportion of C in the mass of CO2
	float coefCH4ToC <- 0.7487; // Proportion of C in the mass of CH4
	float Fm <- 0.07; // Fraction of gross energy in feed converted to methane (IPCC, 2019)
	float methaneEnergyContent <- 55.65; // MJ/kgCH4
}

species animalGroup virtual: true schedules: [] { // Not sure if schedules is not already empty if virtual is true.
	
	//// Parameters
	
	// Ownership
	household myHousehold;
	
	// Digestion process and continuous emissions
	list chymeChunksList;
	
	//// Functions
	
	action emitMetaboIntake (string eatenBiomassType, float eatenQuantity) {
		float eatenEnergy; // MJ/TLU
		switch eatenBiomassType {
			match "FattenedRation" {
				eatenEnergy <- fattenedRationEnergyContent * eatenQuantity;
			}
			match "Rangeland" {
				eatenEnergy <- drySeason ? forageEnergyContentDS * eatenQuantity : forageEnergyContentRS * eatenQuantity;
			}
			match "Cropland" {
				eatenEnergy <- milletResiduesEnergyContent * eatenQuantity;
			}
		}
		assert eatenEnergy >= 0.0;
		float entericCH4 <- eatenEnergy * Fm / methaneEnergyContent; // kgCH4/herd/timestep
		float metaboCO2 <- (entericCH4 - 0.01141) / 0.2859; // kgCO2/herd/timestep
		
		string emittingPool <- eatenBiomassType = "FattenedRation" ? "FattenedAn" : "MobileHerds";
		ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG", entericCH4 * coefCH4ToC + metaboCO2 * coefCO2ToC);}
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
