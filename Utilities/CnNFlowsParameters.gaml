/**
* In: SahelFlux
* Name: CnNFlowsParameters
* Holds C and N flows and stock contents
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model CnNFlowsParameters

import "ImportZoning.gaml"

global {
	
	// Gas stoichiometry
	float coefCO2ToC <- 0.2729; // Proportion of C in the mass of CO2
	float coefCH4ToC <- 0.7487; // Proportion of C in the mass of CH4
	float coefCOToC <- 0.4288; // Proportion of C in the mass of CH4
	float coefN2OToN <- 0.6365; // Proportion of N in the mass of N2O
	float coefNOxToN <- 0.3045; // Proportion of N in the mass of NO2 (default)
	
	// Animals
	float TLUNContent <- 0.0294; // kgN/kg Le Noë 2017 and own calculation
	float TLUCContent <- 0.273; // kgC/kg Le Noë 2017 and own calculation
	
	// C and N contents of crops TODO utilisé dans le grow pour la photosynth et dans la récolte (cohérence?)
	float rangelandVegCContent <- forageRSCContent; // kgC/kgDM
	float milletEarNContent <- 0.024; // kgN/kgDM Grillot 2016
	float milletEarCContent <- 0.353; // kgC/kgDM Manlay 2000
	float milletStrawNContent <- 0.010; // kgN/kgDM Feedipedia
	float milletStrawCContent <- 0.444; // kgC/kgDM Feedipedia
	float wholeMilletCContent <- 0.355; // kgC/kgDM Manlay 2000
	float groundnutAerialPartNContent <- 0.0193; // Manlay, 2000
	float groundnutAerialPartCContent <- 0.375; // Manlay, 2000
	float fallowVegNContent <- forageRSNContent; // kgN/kgDM
	float fallowVegCContent <- forageRSCContent; // kgC/kgDM
	float weedsCContent <- 0.0; // Weeds out
	
	// Feed
	float milletResiduesNContent <- 0.010; // kgN/kgDM Grillot 2018
	float fattenedRationNContent <- 0.01577; // kgN/kgDM Surveys, INRA 2018, Feedipedia
	float fattenedComplementsNContent <- 0.018; // kgN/kgDM Surveys, INRA 2018, Feedipedia
	float forageDSNContent <- 0.006; // kgN/kgDM Grillot 2018
	float forageRSNContent <- 0.02; // kgN/kgDM Grillot 2018
	float milletResiduesCContent <- 0.431; // kgC/kgDM INRA 2018
	float fattenedRationCContent <- 0.457; // kgC/kgDM Surveys, INRA 2018, Feedipedia
	float fattenedComplementsCContent <- 0.462; // kgC/kgDM Surveys, INRA 2018, Feedipedia
	float forageDSCContent <- 0.468; // kgC/kgDM INRA 2018
	float forageRSCContent <- 0.427; // kgC/kgDM INRA 2018
	
	// Wastes
	float kitchenWastesNInputRate <- 0.594; // kgN/day/hh (Grillot 2018)
	float otherWastesNContent <- 0.001; // kgN/kgDM TODO DUMMY
	float kitchenWastesCContent <- 0.6; // kgC/kgDM TODO DUMMY
	float otherWastesCContent <- 0.4; // kgC/kgDM TODO DUMMY
	
	// CH4 from soils emissions parameters
	float methaneProdFromManure <- 0.087; // kgCH4/kgDM IPCC 10.16
	float methaneConversionFactorHerd <- 0.02; // dimless IPCC 10.17
	float methaneConversionFactorORPPile <- 0.05; // dimless IPCC 10.17
	float methaneConversionFactorORPSpread <- 0.01; // dimless IPCC 10.17
	
	// Soil N model
	float baseNFromSoilHomefieldsHa <- 27.5; // kgN/ha; Grillot et al., 2018
	float baseNFromSoilBushfieldsHa <- 12.0; // kgN/ha; Grillot et al., 2018
	float baseNAtmoMicroOrgaHa <- 7.5; // kgN/ha; Grillot et al., 2018
	float baseNAtmoGroundnutHa <- 20.0; // kgN/ha; Grillot et al., 2018
	float baseNFromSoilHomefields <- baseNFromSoilHomefieldsHa * hectareToCell; // kgN/cell
	float baseNFromSoilBushfields <- baseNFromSoilBushfieldsHa * hectareToCell; // kgN/cell
	float baseNAtmoMicroOrga <- baseNAtmoMicroOrgaHa * hectareToCell; // kgN/cell
	float baseNAtmoGroundnut <- baseNAtmoGroundnutHa * hectareToCell; // kgN/cell
	float baseNAtmoPerTree <- 4.0; // kgN; Grillot et al., 2018
	
	// N gases emission factors
	float emissionFactorN2OInHeap <- 0.01; // IPCC t10.21
	float emissionFactorN2ODeposits <- 0.005; // IPCC t11.1
	float emissionFactorN2ODungUrine <- 0.002; // IPCC t11.1
	float fractionGasLossMineralFerti <- 0.15; // IPCC t11.3
	float fractionGasLossOrganicFerti <- 0.21; // IPCC t11.3
	float fractionGasLossORPHeap <- 0.45; // IPCC t10.22
	
}