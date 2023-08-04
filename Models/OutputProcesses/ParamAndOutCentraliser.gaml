/**
* In: SahelFlux
* Name: ParamAndOutCentraliser
* Centralises in one place parameters and outputs to save, and varibale parameters and input data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ParamAndOutCentraliser

import "ComputeOutputs.gaml"

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
		"villageName",
		"cellSize",
		"meteoUpdateType",
		"fallowEnabled",
		"totalAreaHa",
		"biomassProducingSurface",
		"rangelandSurface",
		"bushfieldsSurface",
		"homefieldsSurface",
		"nbHomefieldsParcelsTotal",
		"nbRangelandParcelsTotal",
		
		// Population
		"nbHousehold",
		"meanHerdSize",
		"nbTLUHerds",
		"homeFieldsProportion",
		"averageNbRangelandsPerHh",
		"averageNbHomefieldsPerHh",
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
		
		// Animal density
		"nbTLUHerdsInArea",
		"nbTLUFattened",
		
		// Biomass
		"averageCroplandBiomass (kgDM)",
		"averageRangelandBiomass (kgDM)",
		
		// SOC
		"meanHomefieldsSOCS (kgC)",
		"meanBushfieldsSOCS (kgC)",
		"meanRangelandSOCS (kgC)",
		"totalMeanSOCS (kgC)",
		"meanHomefieldsSOCSVariation (kgC)",
		"meanBushfieldsSOCSVariation (kgC)",
		"meanRangelandSOCSVariation (kgC)",
		"totalMeanSOCSVariation (kgC)"
		
		// Moran
	];
	
	action gatherOutputsAndParameters {
		
		do gatherFlows;
		do computeOutputs;
		
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		float nbTLUHerdsInArea <- nbTLUHerds;
		ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
		float nbTLUFattened <- fattenedAnimal sum_of each.groupSize;
		float biomassProducingSurface <- length(grazableLandscape) / hectareToCell; // ha
		float rangelandSurface <- (grazableLandscape count (each.cellLU = "Rangeland")) / hectareToCell; // ha
		float bushfieldsSurface <- (grazableLandscape count (each.cellLU = "Cropland" and (each.myParcel = nil or !each.myParcel.homeField ))) / hectareToCell; // ha
		float homefieldsSurface <- (grazableLandscape count (each.cellLU = "Cropland" and (each.homefieldCell ))) / hectareToCell; // ha
		int nbHomefieldsParcelsTotal <- parcel count (each.homeField);
		int nbRangelandParcelsTotal <- parcel count (!each.homeField);
		float bushfieldsSurfacePerHh <- household mean_of (each.myHomeParcelsList sum_of each.parcelSurface);
		float homefieldsSurfacePerHh <- household mean_of (each.myBushParcelsList sum_of each.parcelSurface);
		float averageNbHomefieldsPerHh <- household mean_of (length(each.myHomeParcelsList));
		float averageNbRangelandsPerHh <- household mean_of (length(each.myBushParcelsList));
		float averageCroplandBiomass <- (grazableLandscape where (each.cellLU = "Cropland") mean_of each.biomassContent) / hectareToCell; // kgDM/ha
		float averageRangelandBiomass <- (grazableLandscape where (each.cellLU = "Rangeland") mean_of each.biomassContent) / hectareToCell; // kgDM/ha
		
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
			villageName,
			cellSize,
			meteoUpdateType,
			fallowEnabled,
			totalAreaHa,
			biomassProducingSurface,
			rangelandSurface,
			bushfieldsSurface,
			homefieldsSurface,
			nbHomefieldsParcelsTotal,
			nbRangelandParcelsTotal,
			
			// Population
			nbHousehold,
			meanHerdSize,
			nbTLUHerds,
			homeFieldsProportion,
			averageNbRangelandsPerHh,
			averageNbHomefieldsPerHh,
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
			
			// Animal density
			nbTLUHerdsInArea,
			nbTLUFattened,
			
			// Biomass
			averageCroplandBiomass,
			averageRangelandBiomass,
			
			// SOC
			meanHomefieldsSOCS, // kgC
			meanBushfieldsSOCS, // kgC
			meanRangelandSOCS, // kgC
			totalMeanSOCS, // kgC
			meanHomefieldsSOCSVariation, // kgC
			meanBushfieldsSOCSVariation, // kgC
			meanRangelandSOCSVariation, // kgC
			totalMeanSOCSVariation // kgC
		];
		
		assert length(outputsList) = length(outputsStringList);
		assert length(parametersList) = length(parametersStringList);
	}
}
