/**
* In: SahelFlux
* Name: OutputVariablesGatherer
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
		float biomassProducingSurface <- length(grazableLandscape) * hectarePerCell; // ha
		float rangelandSurface <- (grazableLandscape count (each.cellLU = "Rangeland")) * hectarePerCell; // ha
		float bushfieldsSurface <- (grazableLandscape count (
			each.cellLU = "Cropland" and (each.myParcel = nil or !each.myParcel.homeField )
		)) * hectarePerCell; // ha
		float homefieldsSurface <- (
			grazableLandscape count (each.cellLU = "Cropland" and (each.homefieldCell ))
		) * hectarePerCell; // ha
		int nbHomefieldsParcelsTotal <- parcel count (each.homeField);
		int nbBushfieldsParcelsTotal <- parcel count (!each.homeField);
		float homefieldsSurfacePerHh <- household mean_of (each.myHomeParcelsList sum_of each.parcelSurface);
		float bushfieldsSurfacePerHh <- household mean_of (each.myBushParcelsList sum_of each.parcelSurface);
		float averageNbHomefieldsPerHh <- household mean_of (length(each.myHomeParcelsList));
		float averageNbBushfieldsPerHh <- household mean_of (length(each.myBushParcelsList));
		
		parametersMap <- [
			// Simulation
			"machine_time"::gama.machine_time,
			"simulation"::int(self),
			"experimentType"::experimentType,
			
			// Time
			"starting_date"::starting_date,
			"endDate"::endDate,
			"cycle"::cycle,
			"run length (years)"::(current_date - starting_date)/#year,
			"runTime (min)"::runTime,
			
			// Landscape structure
			"villageName"::villageName,
			"cellSize"::cellSize,
			"meteoUpdateType"::meteoUpdateType,
			"fallowEnabled"::fallowEnabled,
//			"totalAreaHa"::totalAreaHa,
			"biomassProducingSurface"::biomassProducingSurface,
			"rangelandSurface"::rangelandSurface,
			"bushfieldsSurface"::bushfieldsSurface,
			"homefieldsSurface"::homefieldsSurface,
			"nbHomefieldsParcelsTotal"::nbHomefieldsParcelsTotal,
			"nbBushfieldsParcelsTotal"::nbBushfieldsParcelsTotal,
			
			// Population
			"nbHousehold"::nbHousehold,
			"meanHerdSize"::meanHerdSize,
			"nbTLUHerds"::nbTLUHerds,
			"homeFieldsProportion"::homeFieldsProportion,
			"averageNbBushfieldsPerHh"::averageNbBushfieldsPerHh,
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
			"SOCxSONAlpha"::(SOCxSONAlphaMap[villageName]),
			"SOCxSONBeta"::(SOCxSONBetaMap[villageName]),
			"homefieldsSOChaInit"::homefieldsSOChaInit,
			"bushfieldsSOChaInit"::bushfieldsSOChaInit,
			"rangelandSOChaInit"::rangelandSOChaInit
		];
		
	}
	
	action gatherInitState (map NMap, map CMap, map GHGMap)  {
		// For output values to be compared with init state
		
		write "Storing simulation initial state.";
		
		float averageCroplandBiomass <- (
			grazableLandscape where (each.cellLU = "Cropland") mean_of each.biomassContent
		) / hectarePerCell; // kgDM/ha
		float averageRangelandBiomass <- (
			grazableLandscape where (each.cellLU = "Rangeland") mean_of each.biomassContent
		) / hectarePerCell; // kgDM/ha
		
		do getMeanSOCS;
		totalMeanSOCInit <- globalMeanSOC;
		if moranOn {do getMoranSOCS;}
		
		initialOutputsMap <- [
			
			// Biomass
			"averageCroplandBiomass (kgDM/ha)"::averageCroplandBiomass,
			"averageRangelandBiomass (kgDM/ha)"::averageRangelandBiomass,
			
			// SOC
			"meanHomefieldsSOCS (kgC/ha)"::(meanHomefieldsSOC / hectarePerCell),
			"meanBushfieldsSOCS (kgC/ha)"::(meanBushfieldsSOC / hectarePerCell),
			"meanRangelandSOCS (kgC/ha)"::(meanRangelandSOC / hectarePerCell),
			"globalMeanSOC (kgC/ha)"::(globalMeanSOC / hectarePerCell),
			
			// Moran
			"homefieldsSOCMoran"::homefieldsSOCMoran,
			"bushfieldsSOCMoran"::bushfieldsSOCMoran,
			"croplandSOCMoran"::croplandSOCMoran,
			"rangelandSOCMoran"::rangelandSOCMoran,
			"globalSOCMoran"::globalSOCMoran
		];
		
		write "	Done.";
		
	}
	
	action gatherRegularOutputs (map NMap, map CMap, map GHGMap)  {
		
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		float nbTLUHerdsInArea <- nbTLUHerds;
		ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
		float nbTLUFattened <- fattenedAnimal sum_of each.groupSize;
		float averageCroplandBiomass <- (
			grazableLandscape where (each.cellLU = "Cropland") mean_of each.biomassContent
		) / hectarePerCell; // kgDM/ha
		float averageRangelandBiomass <- (
			grazableLandscape where (each.cellLU = "Rangeland") mean_of each.biomassContent
		) / hectarePerCell; // kgDM/ha
		
		do computeOutputs(NMap, CMap, GHGMap);
		
		do setVariableOutputMap(
			nbTLUHerdsInArea, nbTLUFattened,
			averageCroplandBiomass, averageRangelandBiomass
		);
		
	}
	
	action gatherFinalOutputs (map NMap, map CMap, map GHGMap)  {
		do gatherRegularOutputs(NMap, CMap, GHGMap);
		loop outputItem over: initialOutputsMap.pairs {
			differentialOutputsMap <+
				("Delta_" + outputItem.key) ::
				variableOutputsMap[outputItem.key] - initialOutputsMap[outputItem.key];
		}
	}
	
	action setVariableOutputMap (
		float nbTLUHerdsInArea, float nbTLUFattened,
		float averageCroplandBiomass, float averageRangelandBiomass
	) {
		
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
			
			// Carbon and nitrogen balance
			"ecosystemCBalance"::ecosystemCBalance,
			"ecosystemNBalance"::ecosystemNBalance,
			"ecosystemApparentCBalance"::ecosystemApparentCBalance,
			"ecosystemApparentNBalance"::ecosystemApparentNBalance,
			"ecosystemCO2Balance (kgCO2)"::ecosystemCO2Balance,
			"ecosystemGHGBalance (kgCO2eq)"::ecosystemGHGBalance,
			"CFootprint"::CFootprint,
			
			// Animal density
			"nbTLUHerdsInArea"::nbTLUHerdsInArea,
			"nbTLUFattened"::nbTLUFattened,
			"herdsIntakeFlow (kgDM)"::herdsIntakeFlow,
			"fattenedIntakeFlow (kgDM)"::fattenedIntakeFlow,
			"herdsExcretionsFlow (kgDM)"::herdsExcretionsFlow,
			"fattenedExcretionsFlow (kgDM)"::fattenedExcretionsFlow,
			"complementsInflow (kgDM)"::complementsInflow,
			
			// Biomass
			"averageCroplandBiomass (kgDM)"::averageCroplandBiomass,
			"averageRangelandBiomass (kgDM)"::averageRangelandBiomass,
			
			// SOC
			"meanHomefieldsSOCS (kgC/ha)"::(meanHomefieldsSOC / hectarePerCell),
			"meanBushfieldsSOCS (kgC/ha)"::(meanBushfieldsSOC / hectarePerCell),
			"meanRangelandSOCS (kgC/ha)"::(meanRangelandSOC / hectarePerCell),
			"globalMeanSOC (kgC/ha)"::(globalMeanSOC / hectarePerCell),
			
			// Moran
			"homefieldsSOCMoran"::homefieldsSOCMoran,
			"bushfieldsSOCMoran"::bushfieldsSOCMoran,
			"croplandSOCMoran"::croplandSOCMoran,
			"rangelandSOCMoran"::rangelandSOCMoran,
			"globalSOCMoran"::globalSOCMoran
		];	
	}
}
