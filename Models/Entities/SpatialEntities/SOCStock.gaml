/**
* In: SahelFlux
* Name: SOCStock
* Soil organic carbon stock
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SOCStock

import "Landscape.gaml"
import "../../OutputProcesses/RecordFlows.gaml"

global {
	
	//// Global SOC parameters
	
	// Initial stocks parameters
	float homefieldsSOChaInit <- 8800.0; // kgC/ha; Moyenne chez Ndour 2020
	float bushfieldsSOChaInit <- 8800.0; // kgC/ha; Moyenne chez Ndour 2020
	float rangelandSOChaInit <- 11100.0; // kgC/ha; Loum selon Ndour 2020
	float homefieldsSOCInit <- homefieldsSOChaInit * hectareToCell; // kgC/cell
	float bushfieldsSOCInit <- bushfieldsSOChaInit * hectareToCell; // kgC/cell
	float rangelandSOCInit <- rangelandSOChaInit * hectareToCell; // kgC/cell
	
	// SOC model (ICBM) parameters
	float labileCPoolProportionInit <- 0.2; // own regression
	float stableCPoolProportionInit <- 0.8; // own regression
	
	float edaphicClimateFactor <- 3.0; // Dimensionless; own regression
	float kineticLabile <- 0.8; // Dimensionless; own regression
	float kineticStable <- 0.01; // Dimensionless; own regression
	float humificationCoef <- 0.05; // Dimensionless; own regression
	
	// Setting Euler discretisation solver parameter
	float criticalNbStepLabileForDiscretisation <- 2 / (kineticLabile * edaphicClimateFactor); // Computed for Euler method.
	float criticalNbStepStableForDiscretisation <- 2 / (kineticStable * edaphicClimateFactor);
	float criticalNbStepForDiscretisation <- min(criticalNbStepLabileForDiscretisation, criticalNbStepStableForDiscretisation); // Stable is way higher with default parameters
	float boundaryNbStepForDiscretisation <- 0.8 * criticalNbStepForDiscretisation; // 0.8 factor for safety
	int solverIterations <- int(ceil(1 / boundaryNbStepForDiscretisation)); // Default 2
	float solverDeltaT <- boundaryNbStepForDiscretisation / solverIterations; // Default 0.5
	
	// Display parameter
	float maxCColor <- 4000.0; // kgC/cell; Arbitrary max for color scale in displays
	
	list<float> getMeanSOCS {
		float meanHomefieldsSOCS;
		float meanBushfieldsSOCS;
		float meanRangelandSOCS;
		
		meanHomefieldsSOCS <- (
			SOCStock where (each.myCell.cellLU = "Cropland" and each.myCell.myParcel != nil and each.myCell.myParcel.homeField)
		) mean_of each.stableCPool;
		meanBushfieldsSOCS <- (
			SOCStock where (each.myCell.cellLU = "Cropland" and (each.myCell.myParcel = nil or !each.myCell.myParcel.homeField))
		) mean_of each.stableCPool;
		meanRangelandSOCS <- (
			SOCStock where (each.myCell.cellLU = "Rangeland")
		) mean_of each.stableCPool;
		
		return [meanHomefieldsSOCS, meanBushfieldsSOCS, meanRangelandSOCS];
	}
	
}

species SOCStock parallel: true schedules: [] {
	
	//// Parameters
	
	landscape myCell;
	list carbonInputsList; // [[string::type, float::VSE, float::CAmount]]
	float labileCPool; // kgC/cell
	float stableCPool; // kgC/cell
	float totalSOC; // kgC/cell
	float CH4ToBeEmittedInRainySeason; // kgCH4/cell
	
	//// Functions
	
	action updateCarbonPools {
		
		// Aggregate input
		float periodCInput; // kgC
		
		// Mobile herds and ORP
		periodCInput <- periodCInput + aggregateRSDungCH4Emissions();
		// Could have been yearly, but eases memory load if monthly.
		
		// Flows to and from the two pools
		float emissionsFromLabile; // kgC
		float emissionsFromStable; // kgC
		
		// Update pools SOC content using Euler method (semi-implicit for stableCPool)
		loop i from: 0 to: solverIterations {
			// Store emissions (could it be outside the loop? Maybe)
			emissionsFromLabile <- ((1 - humificationCoef) * kineticLabile * edaphicClimateFactor * labileCPool) * solverDeltaT;
			emissionsFromStable <- (kineticStable * edaphicClimateFactor * stableCPool) * solverDeltaT;
			
			// Solve for stocks variations
			labileCPool <- labileCPool + (periodCInput - kineticLabile * edaphicClimateFactor * labileCPool) * solverDeltaT;
			stableCPool <- stableCPool + (
				humificationCoef * kineticLabile * edaphicClimateFactor * labileCPool - kineticStable * edaphicClimateFactor * stableCPool
			) * solverDeltaT;
		}
		totalSOC <- labileCPool + stableCPool;
		
		// Return flows for output indicators computation and save in flows map
		// TODO scinder pertes et GHG
		string emittingPool <- myCell.cellLU = "Rangeland" ? "Rangelands" : (myCell.myParcel != nil and myCell.myParcel.homeField ? "HomeFields" : "BushFields");
		ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG" , emissionsFromStable + emissionsFromLabile);}
	}
	
	float aggregateRSDungCH4Emissions {
		
		float soilCarbonInput; // kgC
		loop dungDeposit over: carbonInputsList {
			
			float methaneConversionFactor <- dungDeposit[0] = "HerdDung" ? methaneConversionFactorHerd : methaneConversionFactorORPSpread;
			float futureCH4Emission <- methaneProdFromManure * methaneConversionFactor * float(dungDeposit[1]); // kgCH4
			CH4ToBeEmittedInRainySeason <- CH4ToBeEmittedInRainySeason + futureCH4Emission;
			soilCarbonInput <- soilCarbonInput + float(dungDeposit[2]) - futureCH4Emission * coefCH4ToC;
		}
		
		carbonInputsList <- [];
		return soilCarbonInput;
	}
	
	action emitRSSoilCH4 {
		string emittingPool <- myCell.cellLU = "Rangeland" ? "Rangelands" : (myCell.myParcel != nil and myCell.myParcel.homeField ? "HomeFields" : "BushFields");
		ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG" , myself.CH4ToBeEmittedInRainySeason * coefCH4ToC);}
		CH4ToBeEmittedInRainySeason <- 0.0;
	}
	
	aspect default {
		rgb carbonColourValue <- rgb(int(255 + (75 - 255) / maxCColor * totalSOC), int(255 + (52 - 255) / maxCColor * totalSOC), int(255 + (0 - 255) / maxCColor * totalSOC)); // TODO Not efficient, probably
		draw rectangle(cellWidth, cellHeight) color: carbonColourValue;
	}
	
}

