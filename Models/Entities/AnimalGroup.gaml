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
	float urineEnergyFactor <- 0.04; // IPCC 2019; default value for cattle
	
	// Feed nutritional values
	float milletResiduesEnergyContent <- 17.17; // MJ/kgDM INRA 2018
	float fattenedRationEnergyContent <- 18.79; // MJ/kgDM Surveys, INRA 2018, Feedipedia
	float forageDSEnergyContent <- 18.67; // MJ/kgDM INRA 2018
	float forageRSEnergyContent <- 17.94; // MJ/kgDM INRA 2018 (mean value)
	float milletResiduesAshContent <- 11.40; // % INRA 2018
	float fattenedRationAshContent <- 3.838; // % Surveys, INRA 2018, Feedipedia
	float forageDSAshContent <- 4.6; // % INRA 2018
	float forageRSAshContent <- 10.25; // % INRA 2018 (mean value)
	float milletResiduesDigestibility <- 30.0; // % INRA 2018
	float fattenedRationDigestibility <- 54.9; // % Surveys, INRA 2018, Feedipedia
	float forageDSDigestibility <- 49.0; // % INRA 2018
	float forageRSDigestibility <- 60.5; // % INRA 2018 (mean value)
	
	// Feed N and C contents
	float milletResiduesNContent <- 0.006; // kgN/kgDM Grillot 2018
	float fattenedRationNContent <- 0.01577; // kgN/kgDM Surveys, INRA 2018, Feedipedia
	float forageDSNContent <- 0.006; // kgN/kgDM Grillot 2018
	float forageRSNContent <- 0.02; // kgN/kgDM Grillot 2018
	float milletResiduesCContent <- 0.7; // kgC/kgDM TODO DUMMY
	float fattenedRationCContent <- 0.7; // kgC/kgDM TODO DUMMY
	float forageDSCContent <- 0.7; // kgC/kgDM TODO DUMMY
	float forageRSCContent <- 0.7; // kgC/kgDM TODO DUMMY
	
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
		// Has to be daily for the CO2 regression to work
		float eatenEnergy; // MJ/TLU
		switch eatenBiomassType {
			match "FattenedRation" {
				eatenEnergy <- fattenedRationEnergyContent * eatenQuantity;
			}
			match "Rangeland" {
				eatenEnergy <- drySeason ? forageDSEnergyContent * eatenQuantity : forageRSEnergyContent * eatenQuantity;
			}
			match "Cropland" {
				eatenEnergy <- milletResiduesEnergyContent * eatenQuantity;
			}
		}
		
		float entericCH4 <- eatenEnergy * Fm / methaneEnergyContent; // kgCH4/herd/timestep
		float metaboCO2 <- max((entericCH4 - 0.01141) / 0.2859, 0.0); // kgCO2/herd/timestep
		
		string emittingPool <- eatenBiomassType = "FattenedRation" ? "FattenedAn" : "MobileHerds";
		ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG", entericCH4 * coefCH4ToC + metaboCO2 * coefCO2ToC);}
		// TODO une fonction pour vérifier que l'émis n'est pas supérieur au digéré?
	}
	
	action excrete (pair someChyme) {
		
		string chymeNature <- someChyme.key;
		float ingestedMS <- float(someChyme.value);
		
		// Ration type specific variables
		float ingestedNContent; // kgN/kgDM
		float ingestedCContent; // kgC/kgDM
		float faecesAshContent; // %
		float ingestedDigestibility; // %
		
		switch chymeNature {
			match "Cropland" {
				ingestedNContent <- milletResiduesNContent;
				ingestedCContent <- milletResiduesCContent;
				faecesAshContent <- milletResiduesAshContent;
				ingestedDigestibility <- milletResiduesDigestibility;
			}

			match "Rangeland" {
				if !drySeason {
					ingestedNContent <- forageRSNContent;
					ingestedCContent <- forageRSCContent;
					faecesAshContent <- forageRSAshContent;
					ingestedDigestibility <- forageRSDigestibility;
				} else {
					ingestedNContent <- forageDSNContent;
					ingestedCContent <- forageDSCContent;
					faecesAshContent <- forageDSAshContent;
					ingestedDigestibility <- forageDSDigestibility;
				}
			}

			match "FattenedRation" {
				ingestedNContent <- fattenedRationNContent;
				ingestedCContent <- fattenedRationCContent;
				faecesAshContent <- fattenedRationAshContent;
				ingestedDigestibility <- fattenedRationDigestibility;
			}

		}
		
		// Compute outputs, used in other processes :
		// In nitrogen available for plant growth and N2O and N gases losses from soil
		float excretedNitrogen <- ingestedMS * ingestedNContent * ratioNExcretedOnIngested;
		float faecesNitrogen <- excretedNitrogen * (1 - ratioNUrineOnFaeces);
		float urineNirogen <- excretedNitrogen * ratioNUrineOnFaeces;
		 // In soil carbon model
		float excretedCarbon <- ingestedMS * ingestedCContent * ratioCExcretedOnIngested;
		// In CH4 from soils
		float faecesAsh <- ingestedMS * faecesAshContent; // (Ash are not digested, so ash quantity is the same in ingested and excreta)
		float volatileSolidExcreted <- ingestedMS * (1 - ingestedDigestibility + urineEnergyFactor) * faecesAshContent; //TODO Besoin du forageEnergyContent ou pas ?
		
		// Return outputs
		map<string, float> digestatCharacteristics<- ["faecesNitrogen"::faecesNitrogen, "urineNirogen"::urineNirogen, "excretedCarbon"::excretedCarbon]; // TODO manque les ash et VSE, non?
		return digestatCharacteristics;

	}
	
}
