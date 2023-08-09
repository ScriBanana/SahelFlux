/**
* In: SahelFlux
* Name: BiophysicalParameters
* Holds C and N flows and stock contents
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

global {
	
	// Animals
	float TLUNContent <- 0.0294 const: true; // kgN/kg Le Noë 2017 and own calculation
	float TLUCContent <- 0.273 const: true; // kgC/kg Le Noë 2017 and own calculation
	
	// Feed
	float milletResiduesNContent <- 0.010 const: true; // kgN/kgDM Grillot 2018
	float fattenedRationNContent <- 0.01577 const: true; // kgN/kgDM Surveys, INRA 2018, Feedipedia
	float fattenedComplementsNContent <- 0.018 const: true; // kgN/kgDM Surveys, INRA 2018, Feedipedia
	float forageDSNContent <- 0.006 const: true; // kgN/kgDM Grillot 2018
	float forageRSNContent <- 0.02 const: true; // kgN/kgDM Grillot 2018
	float milletResiduesCContent <- 0.431 const: true; // kgC/kgDM INRA 2018
	float fattenedRationCContent <- 0.457 const: true; // kgC/kgDM Surveys, INRA 2018, Feedipedia
	float fattenedComplementsCContent <- 0.462 const: true; // kgC/kgDM Surveys, INRA 2018, Feedipedia
	float forageDSCContent <- 0.468 const: true; // kgC/kgDM INRA 2018
	float forageRSCContent <- 0.427 const: true; // kgC/kgDM INRA 2018
	
	// Crops
	float rangelandVegCContent <- forageRSCContent const: true; // kgC/kgDM
	float rangelandVegNContent <- forageRSNContent const: true; // kgN/kgDM
	float milletEarNContent <- 0.024 const: true; // kgN/kgDM Grillot 2016
	float milletEarCContent <- 0.353 const: true; // kgC/kgDM Manlay 2000
	float milletStrawNContent <- 0.010 const: true; // kgN/kgDM Feedipedia
	float milletStrawCContent <- 0.444 const: true; // kgC/kgDM Feedipedia
	float wholeMilletCContent <- 0.355 const: true; // kgC/kgDM Manlay 2000
	float milletRootPartCContent <- 0.351 const: true; // kgC/kgDM Manlay, 2000
	float milletRootPartNContent <- 0.0104 const: true; // kgN/kgDM Manlay, 2000
	float groundnutAerialPartNContent <- 0.0193 const: true; // kgN/kgDM Manlay, 2000
	float groundnutAerialPartCContent <- 0.375 const: true; // kgC/kgDM Manlay, 2000
	float groundnutRootPartCContent <- 0.36 const: true; // kgC/kgDM Manlay, 2000
	float groundnutRootPartNContent <- 0.01 const: true; // kgN/kgDM Manlay, 2000
	float fallowVegNContent <- forageRSNContent const: true; // kgN/kgDM
	float fallowVegCContent <- forageRSCContent const: true; // kgC/kgDM
	float fallowRootPartCContent <- 0.3545 const: true; // kgC/kgDM Manlay, 2000
	float fallowRootPartNContent <- 0.0059 const: true; // kgN/kgDM Manlay, 2000
	float weedsCContent <- 0.0 const: true; // Weeds out
	
	// Wastes
	float kitchenWastesNInputRate <- 0.594 const: true; // kgN/day/hh (Grillot 2018)
	float otherWastesNContent <- 0.001 const: true; // kgN/kgDM TODO DUMMY
	float kitchenWastesCContent <- 0.6 const: true; // kgC/kgDM TODO DUMMY
	float otherWastesCContent <- 0.4 const: true; // kgC/kgDM TODO DUMMY
	
	// CH4 from soils emissions parameters
	float methaneProdFromManure <- 0.087 const: true; // kgCH4/kgDM IPCC 10.16
	float methaneConversionFactorHerd <- 0.02 const: true; // dimless IPCC 10.17
	float methaneConversionFactorORPPile <- 0.05 const: true; // dimless IPCC 10.17
	float methaneConversionFactorORPSpread <- 0.01 const: true; // dimless IPCC 10.17
	
	// N gases emission factors
	float emissionFactorN2OInHeap <- 0.01 const: true; // IPCC t10.21
	float emissionFactorN2ODeposits <- 0.005 const: true; // IPCC t11.1
	float emissionFactorN2ODungUrine <- 0.002 const: true; // IPCC t11.1
	float fractionGasLossMineralFerti <- 0.15 const: true; // IPCC t11.3
	float fractionGasLossOrganicFerti <- 0.21 const: true; // IPCC t11.3
	float fractionGasLossORPHeap <- 0.45 const: true; // IPCC t10.22
	
	// Fire emissions
	float milletCombustionFactor <- 0.85 const: true; // IPCC tab2.6
	float fireCO2EmissionFactor <- 1.51500 const: true;  // kg/kgDM const: true; IPCC tab2.4
	float fireCOEmissionFactor <- 0.09200 const: true;  // kg/kgDM const: true; IPCC tab2.4
	float fireCH4EmissionFactor <- 0.00270 const: true;  // kg/kgDM const: true; IPCC tab2.4
	float fireN2OEmissionFactor <- 0.00007 const: true;  // kg/kgDM const: true; IPCC tab2.4
	float fireNOxEmissionFactor <- 0.00250 const: true;  // kg/kgDM const: true; IPCC tab2.4
	float CO2FromBurning <- milletCombustionFactor * fireCO2EmissionFactor const: true;
	float COFromBurning <- milletCombustionFactor * fireCOEmissionFactor const: true;
	float CH4FromBurning <- milletCombustionFactor * fireCH4EmissionFactor const: true;
	float N2OFromBurning <- milletCombustionFactor * fireN2OEmissionFactor const: true;
	float NOxFromBurning <- milletCombustionFactor * fireNOxEmissionFactor const: true;
	
	// Gas stoichiometry
	float coefCO2ToC <- 0.2729 const: true; // Proportion of C in the mass of CO2
	float coefCH4ToC <- 0.7487 const: true; // Proportion of C in the mass of CH4
	float coefCOToC <- 0.4288 const: true; // Proportion of C in the mass of CH4
	float coefN2OToN <- 0.6365 const: true; // Proportion of N in the mass of N2O
	float coefNOxToN <- 0.3045 const: true; // Proportion of N in the mass of NO2 (default)
	
	// PRG
	float PRGCH4 <- 25.0 const: true; // Over 100 years, as recommended by IPCC
	float PRGN2O <- 298.0 const: true;
	
}