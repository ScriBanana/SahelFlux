/**
* In: SahelFlux
* Name: AnimalGroup
* Parent species for mobile herds and fattened animals.
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "../../Main.gaml"

global {
	
	//// Global Animals parameters
	
	// Animal constitution
	float weightTLU <- 250.0 const: true; //kg live weight
	
	// Shared parameters for mobile and fattened
	float dailyIntakeRatePerMobileTLU <- 6.25; // kgDM/TLU/day Maximum amount of forage biomass consumed daily. (Rivière, 1991)
	
	// Digestion parameters
	int digestionLengthParamAsInt <- 20; // Hours
	float digestionLength <- digestionLengthParamAsInt * 3600.0; // Duration of the digestion of biomass in the animals
	float ratioNExcretedOnIngested <- 0.43 const: true; // Lecomte 2002
	float ratioCExcretedOnIngested <- 0.45 const: true; // Lecomte 2002
	float ratioNUrineOnFaeces <- 0.25 const: true; // Wade 2016
	float urineEnergyFactor <- 0.04 const: true; // IPCC 2019; default value for cattle
	float dietaryEnergyConversionFactor <- 18.45 const: true;
	
	// Feed nutritional values
	float milletResiduesEnergyContent <- 17.17 const: true; // MJ/kgDM INRA 2018
	float fattenedRationEnergyContent <- 18.79 const: true; // MJ/kgDM Surveys, INRA 2018, Feedipedia
	float forageDSEnergyContent <- 18.67 const: true; // MJ/kgDM INRA 2018
	float forageRSEnergyContent <- 17.94 const: true; // MJ/kgDM INRA 2018 (mean value)
	float milletResiduesAshContent <- 11.40 const: true; // % INRA 2018
	float fattenedRationAshContent <- 3.838 const: true; // % Surveys, INRA 2018, Feedipedia
	float forageDSAshContent <- 4.6 const: true; // % INRA 2018
	float forageRSAshContent <- 10.25 const: true; // % INRA 2018 (mean value)
	float milletResiduesDigestibility <- 30.0 const: true; // % INRA 2018
	float fattenedRationDigestibility <- 54.9 const: true; // % Surveys, INRA 2018, Feedipedia
	float forageDSDigestibility <- 49.0 const: true; // % INRA 2018
	float forageRSDigestibility <- 60.5 const: true; // % INRA 2018 (mean value)
	
	// Carboned gases parameters
	float Fm <- 0.07 const: true; // Fraction of gross energy in feed converted to methane (IPCC, 2019)
	float methaneEnergyContent <- 55.65 const: true; // MJ/kgCH4
	float CH4ToCO2Slope <- 0.02859 const: true; // Adapted from Aubry et al
	float CH4ToCO2Offset <- 0.01141 const: true; // Adapted from Aubry et al
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
			match_one ["Cropland", "HomeFields", "BushFields"] {
				eatenEnergy <- milletResiduesEnergyContent * eatenQuantity;
			}
			default {
				write eatenBiomassType;
				assert false; // Error in eatenBiomassType
			}
		}
		
		float entericCH4 <- eatenEnergy * Fm / methaneEnergyContent; // kgCH4/herd/timestep
		float metaboCO2 <- max((entericCH4 - CH4ToCO2Offset) / CH4ToCO2Slope, 0.0); // kgCO2/herd/timestep
		
		string emittingPool <- eatenBiomassType = "FattenedRation" ? "FattenedAn" : "MobileHerds";
		ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG", entericCH4 * coefCH4ToC + metaboCO2 * coefCO2ToC);}
		ask world { do saveGHGFlow(emittingPool, "CH4", entericCH4);}
		ask world { do saveGHGFlow(emittingPool, "CO2", metaboCO2);}
		// TODO une fonction pour vérifier que l'émis n'est pas supérieur au digéré?
	}
	
	action excrete (pair someChyme) {
		
		string chymeNature <- someChyme.key;
		float ingestedDM <- float(someChyme.value);
		
		// Ration type specific variables
		float ingestedNContent; // kgN/kgDM
		float ingestedCContent; // kgC/kgDM
		float faecesAshContent; // %
		float ingestedDigestibility; // %
		float ingestedEnergyContent; // MJ/kgDM
		
		switch chymeNature {
			match "Cropland" {
				ingestedNContent <- milletResiduesNContent * 0.01;
				ingestedCContent <- milletResiduesCContent * 0.01;
				faecesAshContent <- milletResiduesAshContent * 0.01;
				ingestedDigestibility <- milletResiduesDigestibility * 0.01;
				ingestedEnergyContent <- milletResiduesEnergyContent;
			}

			match "Rangeland" {
				if !drySeason {
					ingestedNContent <- forageRSNContent * 0.01;
					ingestedCContent <- forageRSCContent * 0.01;
					faecesAshContent <- forageRSAshContent * 0.01;
					ingestedDigestibility <- forageRSDigestibility * 0.01;
					ingestedEnergyContent <- forageRSEnergyContent;
				} else {
					ingestedNContent <- forageDSNContent * 0.01;
					ingestedCContent <- forageDSCContent * 0.01;
					faecesAshContent <- forageDSAshContent * 0.01;
					ingestedDigestibility <- forageDSDigestibility * 0.01;
					ingestedEnergyContent <- forageDSEnergyContent;
				}
			}

			match "FattenedRation" {
				ingestedNContent <- fattenedRationNContent * 0.01;
				ingestedCContent <- fattenedRationCContent * 0.01;
				faecesAshContent <- fattenedRationAshContent * 0.01;
				ingestedDigestibility <- fattenedRationDigestibility * 0.01;
				ingestedEnergyContent <- fattenedRationEnergyContent;
			}

		}
		
		// Compute outputs, used in other processes :
		// In CH4 from soils
		float volatileSolidExcreted <- ingestedDM * ( 1 - faecesAshContent) * (1 - ingestedDigestibility + urineEnergyFactor); // kgDM
		// In nitrogen available for plant growth and N2O and N gases losses from soil
		float excretedNitrogen <- ingestedDM * ingestedNContent * ratioNExcretedOnIngested; // kgN
		float faecesNitrogen <- excretedNitrogen * (1 - ratioNUrineOnFaeces); // kgN
		float urineNirogen <- excretedNitrogen * ratioNUrineOnFaeces; // kgN
		 // In soil carbon model
		float excretedCarbon <- ingestedDM * ingestedCContent * ratioCExcretedOnIngested; // kgC
		// As a tracker for global outputs
		float excretedDM <- ingestedDM * (1 - ingestedDigestibility + urineEnergyFactor);
		
		if enableDebug {
			assert excretedCarbon >= volatileSolidExcreted * ingestedCContent * ratioCExcretedOnIngested;
		}
		
		// Return outputs
		map<string, float> digestatCharacteristics<- [
			"volatileSolidExcreted"::volatileSolidExcreted,
			"faecesNitrogen"::faecesNitrogen,
			"urineNirogen"::urineNirogen,
			"excretedCarbon"::excretedCarbon,
			"excretedDM"::excretedDM
		];
		return digestatCharacteristics;

	}
	
}
