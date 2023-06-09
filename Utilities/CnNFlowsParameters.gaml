/**
* In: SahelFlux
* Name: CnNFlowsParameters
* Holds C and N flows and stock contents
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model CnNFlowsParameters

/* Insert your model definition here */

global {
	
	// Animals
	float TLUNContent <- 0.0294; // kgN/kg Le Noë 2017 and own calculation
	float TLUCContent <- 0.273; // kgC/kg Le Noë 2017 and own calculation
	
	// Gas
	float coefCO2ToC <- 0.2729; // Proportion of C in the mass of CO2
	float coefCH4ToC <- 0.7487; // Proportion of C in the mass of CH4
	float coefCOToC <- 0.4288; // Proportion of C in the mass of CH4
	float coefN2OToN <- 0.6365; // Proportion of N in the mass of N2O
	float coefNOxToN <- 0.3045; // Proportion of N in the mass of NO2 (default)
	
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
	
	// Heap
	float heapNContentInit <- 0.0; // kgN Init value is 0 because start of dry season?
	float heapCContentInit <- 0.0; // kgC Init value is 0 because start of dry season?
	
}