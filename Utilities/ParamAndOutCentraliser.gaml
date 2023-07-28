/**
* In: SahelFlux
* Name: ParamAndOutCentraliser
* Centralises in one place parameters and outputs to save, and varibale parameters and input data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ParamAndOutCentraliser

import "GenerateExportFiles.gaml"

global {
	list parametersList;
	list parametersStringList <- [
		// Simulation
		"machine_time",
		"int(self)",
		"experimentType",
		// Time
		"starting_date",
		"endDate",
		"cycle",
		"(current_date - starting_date)/#year",
		"runTime",
		// Landscape structure
		"meteoUpdateType",
		"fallowEnabled",
		"totalAreaHa",
		"biomassProducingSurface",
		"rangelandSurface",
		"bushfieldsSurface",
		"homefieldsSurface",
		"homeFieldsRadius",
		// Population
		"nbHousehold",
		"meanHerdSize",
		"nbTLUHerds",
		"nbBushFieldsPerHh",
		"nbHomeFieldsPerHh",
		"bushfieldsSurfacePerHh",
		"homefieldsSurfacePerHh",
		// Practices
		"maxNbNightsPerCellInPaddock",
		"maxNbFallowPaddock",
		"propTranshumantHh",
		"nbTranshumantHh",
		"propFatteningHh",
		"nbFatteningHh",
		"meanFattenedGroupSize",
		// Biophysical
		"SOCxSONOn",
		"SOCxSONAlpha",
		"SOCxSONBeta",
		"homefieldsSOChaInit",
		"bushfieldsSOChaInit",
		"rangelandSOChaInit"
	];
		
	list outputsList;
	list outputsStringList <- [
		
		// Global flows
		"totalNFlows (kgN)",
		"totalNInflows (kgN)",
		"totalNThroughflows (kgN)",
		"totalNOutflows (kgN)",
		"totalCFlows (kgC)",
		"totalCInflows (kgC)",
		"totalCThroughflows (kgC)",
		"totalCOutflows (kgC)",
		
		// Circularity (ENA framework)
		"TSTN",
		"ICRN",
		"FinnN",
		"TSTC",
		"ICRC",
		"FinnC",
		
		// GHG
		"totalCO2 (kgCO2)",
		"totalCH4 (kgCH4)",
		"totalN2O (kgN2O)",
		"totalGHG (kgCO2eq)",
		
		// Carbon balance
		"ecosystemCBalance",
		"ecosystemCO2Balance (kgCO2)",
		"ecosystemGHGBalance (kgCO2eq)",
		"SCS",
		"CFootprint",
		
		// SOC
		"meanHomefieldsSOCSVariation (kgC)",
		"meanBushfieldsSOCSVariation (kgC)",
		"meanRangelandSOCSVariation (kgC)",
		"totalMeanSOCSVariation (kgC)"
	];
	
	action gatherOutputsAndParameters {
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
		float biomassProducingSurface <- length(grazableLandscape) / hectareToCell; // ha
		float rangelandSurface <- (landscape count (each.cellLU = "Rangeland")) / hectareToCell; // ha
		float bushfieldsSurface <- (landscape count (each.cellLU = "Cropland" and (each.myParcel = nil or !each.myParcel.homeField ))) / hectareToCell; // ha
		float homefieldsSurface <- (landscape count (each.cellLU = "Cropland" and (each.homefieldCell ))) / hectareToCell; // ha
		float bushfieldsSurfacePerHh <- household mean_of (each.myHomeParcelsList sum_of each.parcelSurface);
		float homefieldsSurfacePerHh <- household mean_of (each.myBushParcelsList sum_of each.parcelSurface);
		
		parametersList <- [
			// Simulation
			machine_time,
			int(self),
			experimentType,
			// Time
			starting_date,
			endDate,
			cycle,
			(current_date - starting_date)/#year,
			runTime,
			// Landscape structure
			meteoUpdateType,
			fallowEnabled,
			totalAreaHa,
			biomassProducingSurface,
			rangelandSurface,
			bushfieldsSurface,
			homefieldsSurface,
			homeFieldsRadius,
			// Population
			nbHousehold,
			meanHerdSize,
			nbTLUHerds,
			nbBushFieldsPerHh,
			nbHomeFieldsPerHh,
			bushfieldsSurfacePerHh,
			homefieldsSurfacePerHh,
			// Practices
			maxNbNightsPerCellInPaddock,
			maxNbFallowPaddock,
			propTranshumantHh,
			nbTranshumantHh,
			propFatteningHh,
			nbFatteningHh,
			meanFattenedGroupSize,
			// Biophysical
			SOCxSONOn,
			SOCxSONAlpha,
			SOCxSONBeta,
			homefieldsSOChaInit,
			bushfieldsSOChaInit,
			rangelandSOChaInit
		];
		
		outputsList <- [
			
			// Global flows
			totalNFlows, // kgN
			totalNInflows, // kgN
			totalNThroughflows, // kgN
			totalNOutflows, // kgN
			totalCFlows, // kgC
			totalCInflows, // kgC
			totalCThroughflows, // kgC
			totalCOutflows, // kgC
			
			// Circularity (ENA framework)
			TSTN,
			ICRN,
			FinnN,
			TSTC,
			ICRC,
			FinnC,
			
			// GHG
			totalCO2, // kgCO2
			totalCH4, // kgCH4
			totalN2O, // kgN2O
			totalGHG, // kgCO2eq
			
			// Carbon balance
			ecosystemCBalance,
			ecosystemCO2Balance, // kgCO2, atmo fix - CO2 emissions, used for validation
			ecosystemGHGBalance, // kgCO2eq, SOCS accumulation - GHG emissions
			SCS,
			CFootprint,
			
			// SOC
			meanHomefieldsSOCSVariation, // kgC
			meanBushfieldsSOCSVariation, // kgC
			meanRangelandSOCSVariation, // kgC
			totalMeanSOCSVariation // kgC
		];
	}
}

experiment ExplorationParameters virtual: true {
	
	parameter "Home fields area radius (m)" category: "Scenario - Spatial layout" var: homeFieldsRadius min: 0.0;
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold min: 0;
	parameter "Proportion of transhuming households" category: "Scenario - Population structure" var: propTranshumantHh min: 0.0 max: 1.0;
	parameter "Proportion of fattening households" category: "Scenario - Population structure" var: propFatteningHh min: 0.0 max: 1.0;
	parameter "Mobile herds mean sizes (TLU)" category: "Scenario - Production means repartition" var: meanHerdSize min: 0.0;
	parameter "Bush fields parcels per household" category: "Scenario - Production means repartition" var: nbBushFieldsPerHh min: 0;
	parameter "Home fields parcels per household" category: "Scenario - Production means repartition" var: nbHomeFieldsPerHh min: 0;
	parameter "Mean number of fattened animals per season" category: "Scenario - Production means repartition" var: meanFattenedGroupSize min: 0.0;
}
	
