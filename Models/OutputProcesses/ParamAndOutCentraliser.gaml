/**
* In: SahelFlux
* Name: ParamAndOutCentraliser
* Centralises in one place parameters and outputs to save, and varibale parameters and input data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "ComputeOutputs.gaml"

global {
	
	// Maps of variables to export in CSV files
	map<string, unknown> parametersMap; // Parameters for the log
	map<string, float> variableOutputsMap; // Flows, states
	map<string, float> initialOutputsMap; // InitialState
	map<string, float> differentialOutputsMap; // Differences of states from init
	
	action gatherParameters {
		
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		float biomassProducingSurface <- length(grazableLandscape) / hectareToCell; // ha
		float rangelandSurface <- (grazableLandscape count (each.cellLU = "Rangeland")) / hectareToCell; // ha
		float bushfieldsSurface <- (grazableLandscape count (
			each.cellLU = "Cropland" and (each.myParcel = nil or !each.myParcel.homeField )
		)) / hectareToCell; // ha
		float homefieldsSurface <- (
			grazableLandscape count (each.cellLU = "Cropland" and (each.homefieldCell ))
		) / hectareToCell; // ha
		int nbHomefieldsParcelsTotal <- parcel count (each.homeField);
		int nbRangelandParcelsTotal <- parcel count (!each.homeField);
		float bushfieldsSurfacePerHh <- household mean_of (each.myHomeParcelsList sum_of each.parcelSurface);
		float homefieldsSurfacePerHh <- household mean_of (each.myBushParcelsList sum_of each.parcelSurface);
		float averageNbHomefieldsPerHh <- household mean_of (length(each.myHomeParcelsList));
		float averageNbRangelandsPerHh <- household mean_of (length(each.myBushParcelsList));
		
		parametersMap <- [
			// Simulation
			"machine_time"::machine_time,
			"simulation"::int(self),
			"experimentType"::experimentType,
			
			// Time
			"starting_date"::starting_date,
			"endDate"::endDate,
			"cycle"::cycle,
			"run length (years)"::(current_date - starting_date)/#year,
			"runTime"::runTime,
			
			// Landscape structure
			"villageName"::villageName,
			"cellSize"::cellSize,
			"meteoUpdateType"::meteoUpdateType,
			"fallowEnabled"::fallowEnabled,
			"totalAreaHa"::totalAreaHa,
			"biomassProducingSurface"::biomassProducingSurface,
			"rangelandSurface"::rangelandSurface,
			"bushfieldsSurface"::bushfieldsSurface,
			"homefieldsSurface"::homefieldsSurface,
			"nbHomefieldsParcelsTotal"::nbHomefieldsParcelsTotal,
			"nbRangelandParcelsTotal"::nbRangelandParcelsTotal,
			
			// Population
			"nbHousehold"::nbHousehold,
			"meanHerdSize"::meanHerdSize,
			"nbTLUHerds"::nbTLUHerds,
			"homeFieldsProportion"::homeFieldsProportion,
			"averageNbRangelandsPerHh"::averageNbRangelandsPerHh,
			"averageNbHomefieldsPerHh"::averageNbHomefieldsPerHh,
			"bushfieldsSurfacePerHh"::bushfieldsSurfacePerHh,
			"homefieldsSurfacePerHh"::homefieldsSurfacePerHh,
			
			// Practices
			"maxNbNightsPerCellInPaddock"::maxNbNightsPerCellInPaddock,
			"maxNbFallowPaddock"::maxNbFallowPaddock,
			"propTranshumantHh"::propTranshumantHh,
			"nbTranshumantHh"::nbTranshumantHh,
			"propFatteningHh"::propFatteningHh,
			"nbFatteningHh"::nbFatteningHh,
			"meanFattenedGroupSize"::meanFattenedGroupSize,
			
			// Biophysical
			"SOCxSONOn"::SOCxSONOn,
			"SOCxSONAlpha"::SOCxSONAlpha,
			"SOCxSONBeta"::SOCxSONBeta,
			"homefieldsSOChaInit"::homefieldsSOChaInit,
			"bushfieldsSOChaInit"::bushfieldsSOChaInit,
			"rangelandSOChaInit"::rangelandSOChaInit
		];
		
	}
	
	action gatherInitState (map NMap, map CMap, map GHGMap)  {
		
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		float nbTLUHerdsInArea <- nbTLUHerds;
		ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
		float nbTLUFattened <- fattenedAnimal sum_of each.groupSize;
		float averageCroplandBiomass <- (
			grazableLandscape where (each.cellLU = "Cropland") mean_of each.biomassContent
		) / hectareToCell; // kgDM/ha
		float averageRangelandBiomass <- (
			grazableLandscape where (each.cellLU = "Rangeland") mean_of each.biomassContent
		) / hectareToCell; // kgDM/ha
		
		do getMeanSOCS;
		do getMoranSOCS;
		
		initialOutputsMap <- [
			
			// Global C&N flows
			"totalNFlows (kgN)"::0.0,
			"totalNInflows (kgN)"::0.0,
			"totalNThroughflows (kgN)"::0.0,
			"totalNOutflows (kgN)"::0.0,
			"totalCFlows (kgC)"::0.0,
			"totalCInflows (kgC)"::0.0,
			"totalCThroughflows (kgC)"::0.0,
			"totalCOutflows (kgC)"::0.0,
			
			// Circularity (ENA framework)
			"TSTN"::0.0,
			"pathLengthN"::0.0,
			"ICRN"::0.0,
			"TSTC"::0.0,
			"pathLengthC"::0.0,
			"ICRC"::0.0,
			
			// GHG
			"totalCO2 (kgCO2)"::0.0,
			"totalCH4 (kgCH4)"::0.0,
			"totalN2O (kgN2O)"::0.0,
			"totalGHG (kgCO2eq)"::0.0,
			
			// Carbon balance
			"ecosystemCBalance"::0.0,
			"ecosystemCO2Balance (kgCO2)"::0.0,
			"ecosystemGHGBalance (kgCO2eq)"::0.0,
			"SCS"::0.0,
			"CFootprint"::0.0,
			
			// Animal density
			"nbTLUHerdsInArea"::nbTLUHerdsInArea,
			"nbTLUFattened"::nbTLUFattened,
			"herdsIntakeFlow (kgDM)"::0.0,
			"herdsExcretionsFlow (kgDM VSE)"::0.0,
			
			// Biomass
			"averageCroplandBiomass (kgDM)"::averageCroplandBiomass,
			"averageRangelandBiomass (kgDM)"::averageRangelandBiomass,
			
			// SOC
			"meanHomefieldsSOCS (kgC)"::meanHomefieldsSOCS,
			"meanBushfieldsSOCS (kgC)"::meanBushfieldsSOCS,
			"meanRangelandSOCS (kgC)"::meanRangelandSOCS,
			"totalMeanSOCS (kgC)"::totalMeanSOCS,
			
			// Moran
			"homefieldsSOCMoran"::homefieldsSOCMoran,
			"bushfieldsSOCMoran"::bushfieldsSOCMoran,
			"croplandSOCMoran"::croplandSOCMoran,
			"rangelandSOCMoran"::rangelandSOCMoran,
			"globalSOCMoran"::globalSOCMoran
		];
		
	}
	
	action gatherRegularOutputs (map NMap, map CMap, map GHGMap)  {
		
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		float nbTLUHerdsInArea <- nbTLUHerds;
		ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
		float nbTLUFattened <- fattenedAnimal sum_of each.groupSize;
		float averageCroplandBiomass <- (
			grazableLandscape where (each.cellLU = "Cropland") mean_of each.biomassContent
		) / hectareToCell; // kgDM/ha
		float averageRangelandBiomass <- (
			grazableLandscape where (each.cellLU = "Rangeland") mean_of each.biomassContent
		) / hectareToCell; // kgDM/ha
		
		do computeOutputs(NMap, CMap, GHGMap);
		
		variableOutputsMap <- [
			
			// Global C&N flows
			"totalNFlows (kgN)"::totalNFlows,
			"totalNInflows (kgN)"::totalNInflows,
			"totalNThroughflows (kgN)"::totalNThroughflows,
			"totalNOutflows (kgN)"::totalNOutflows,
			"totalCFlows (kgC)"::totalCFlows,
			"totalCInflows (kgC)"::totalCInflows,
			"totalCThroughflows (kgC)"::totalCThroughflows,
			"totalCOutflows (kgC)"::totalCOutflows,
			
			// Circularity (ENA framework)
			"TSTN"::TSTN,
			"pathLengthN"::pathLengthN,
			"ICRN"::ICRN,
			"TSTC"::TSTC,
			"pathLengthC"::pathLengthC,
			"ICRC"::ICRC,
			
			// GHG
			"totalCO2 (kgCO2)"::totalCO2,
			"totalCH4 (kgCH4)"::totalCH4,
			"totalN2O (kgN2O)"::totalN2O,
			"totalGHG (kgCO2eq)"::totalGHG,
			
			// Carbon balance
			"ecosystemCBalance"::ecosystemCBalance,
			"ecosystemCO2Balance (kgCO2)"::ecosystemCO2Balance,
			"ecosystemGHGBalance (kgCO2eq)"::ecosystemGHGBalance,
			"SCS"::SCS,
			"CFootprint"::CFootprint,
			
			// Animal density
			"nbTLUHerdsInArea"::nbTLUHerdsInArea,
			"nbTLUFattened"::nbTLUFattened,
			"herdsIntakeFlow (kgDM)"::herdsIntakeFlow,
			"herdsExcretionsFlow (kgDM VSE)"::herdsExcretionsFlow,
			
			// Biomass
			"averageCroplandBiomass (kgDM)"::averageCroplandBiomass,
			"averageRangelandBiomass (kgDM)"::averageRangelandBiomass,
			
			// SOC
			"meanHomefieldsSOCS (kgC)"::meanHomefieldsSOCS,
			"meanBushfieldsSOCS (kgC)"::meanBushfieldsSOCS,
			"meanRangelandSOCS (kgC)"::meanRangelandSOCS,
			"totalMeanSOCS (kgC)"::totalMeanSOCS,
			
			// Moran
			"homefieldsSOCMoran"::homefieldsSOCMoran,
			"bushfieldsSOCMoran"::bushfieldsSOCMoran,
			"croplandSOCMoran"::croplandSOCMoran,
			"rangelandSOCMoran"::rangelandSOCMoran,
			"globalSOCMoran"::globalSOCMoran
		];
		
	}
	
	action gatherFinalOutputs (map NMap, map CMap, map GHGMap)  {
		do gatherRegularOutputs(NMap, CMap, GHGMap);
		loop outputItem over: variableOutputsMap.keys {
			differentialOutputsMap[outputItem] <-
				variableOutputsMap[outputItem] - initialOutputsMap[outputItem];
		}
	}
	
}
