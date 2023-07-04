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
	];
		
	list outputsList;
	list outputsStringList <- [
		
	];
	
	action gatherOutputsAndParameters {
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
		float biomassProducingSurface <- (landscape count (each.biomassProducer)) / hectareToCell; // ha
		float rangelandSurface <- (landscape count (each.cellLU = "Rangeland")) / hectareToCell; // ha
		float bushfieldsSurface <- (landscape count (each.cellLU = "Cropland" and (each.myParcel = nil or !each.myParcel.homeField ))) / hectareToCell; // ha
		float homefieldsSurface <- (landscape count (each.cellLU = "Cropland" and (each.myParcel != nil and each.myParcel.homeField ))) / hectareToCell; // ha
		
		float bushfieldsSurfacePerHh;
		float homefieldsSurfacePerHh;
		
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
			maxNbCroplandParcels,
			parcelRadiusDistri,
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
		
		list<float> meanSOCS <- getMeanSOCS();
		float meanHomefieldsSOCS <- meanSOCS[0];
		float meanBushfieldsSOCS <- meanSOCS[1];
		float meanRangelandSOCS <- meanSOCS[2];
		
		outputsList <- [
			// SOC
			meanHomefieldsSOCS, meanBushfieldsSOCS, meanRangelandSOCS,
			// Ecosystem carbon balance
			TT, CThroughflow,
			// Carbon footprint
			
			// C and N fluxes analysis
			totalNFlows, totalCFlows
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
	
