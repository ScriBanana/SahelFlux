/**
* In: SahelFlux
* Name: SOCstock
* Soil organic carbon stock
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SOCstock

import "Landscape.gaml"
import "../../OutputProcesses/RecordFlows.gaml"

global {
	
	//// Global SOC parameters
	
	// Initial stocks parameters
	float croplandSOChaInit <- 8800.0; // kgC/ha; Moyenne chez Ndour 2020
	float rangelandSOChaInit <- 11100.0; // kgC/ha; Loum selon Ndour 2020
	float croplandSOCInit <- croplandSOChaInit * hectareToCell; // kgC/cell
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
	
	// C emissions parameters
	float dummyCEmittedAtDungDepositFactor <- 0.3; // TODO DUMMY (duh)
	
	// Display parameter
	float maxCColor <- 4000.0; // kgC/cell; Arbitrary max for color scale in displays
	
}

species SOCstock parallel: true schedules: [] {
	
	//// Parameters
	
	landscape myCell;
	map<string, float> periodCInputMap <- ["HerdsDung"::0.0, "Straw"::0.0, "ORP"::0.0]; // kg/cell
	float labileCPool; // kgC/cell
	float stableCPool; // kgC/cell
	float totalSOC; // kgC/cell
	float CToBeEmittedInRainySeason;
	
	//// Functions
	
	action updateCarbonPools {
		
		// Remove emitted gases // TODO very DUMMY
		CToBeEmittedInRainySeason <- periodCInputMap["HerdsDung"] * dummyCEmittedAtDungDepositFactor;
		periodCInputMap["HerdsDung"] <- periodCInputMap["HerdsDung"] - CToBeEmittedInRainySeason;
		// TODO add the rest
		
		// Aggregate input
		float periodCInput <- sum(periodCInputMap);
		periodCInputMap <- ["HerdsDung"::0.0, "Straw"::0.0, "ORP"::0.0];
		
		// Flows to and from the two pools
		float emissionsFromLabile;
		float emissionsFromStable;
		
		// Update pools SOC content using Euler method (semi-implicit for stableCPool)
		int solverIterations <- int(ceil(1 / boundaryNbStepForDiscretisation)); // Default 2
		float solverDeltaT <- boundaryNbStepForDiscretisation / solverIterations; // Default 0.5
		loop i from: 0 to: solverIterations {
			// Store emissions (could it be outside the loop? Maybe)
			emissionsFromLabile <- ((1 - humificationCoef) * kineticLabile * edaphicClimateFactor * labileCPool) * solverDeltaT;
			emissionsFromStable <- (kineticStable * edaphicClimateFactor * stableCPool) * solverDeltaT;
			
			// Solve for stocks variations
			labileCPool <- labileCPool + (periodCInput - kineticLabile * edaphicClimateFactor * labileCPool) * solverDeltaT;
			stableCPool <- stableCPool + (humificationCoef * kineticLabile * edaphicClimateFactor * labileCPool - kineticStable * edaphicClimateFactor * stableCPool) * solverDeltaT;
		}
		totalSOC <- labileCPool + stableCPool;
		
		// Return flows for output indicators computation and save in flows map
		// TODO scinder pertes et GHG
		string emittingPool <- myCell.cellLU = "Rangeland" ? "Rangelands" : (myCell.myParcel != nil and myCell.myParcel.homeField ? "HomeFields" : "BushFields");
		ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG" , emissionsFromStable + emissionsFromLabile);}
	}
	
	action rainSeasonEmit { // TODO
		//CToBeEmittedInRainySeason que herd pour le moment
	}
	
	aspect default {
		rgb carbonColourValue <- rgb(int(255 + (75 - 255) / maxCColor * totalSOC), int(255 + (52 - 255) / maxCColor * totalSOC), int(255 + (0 - 255) / maxCColor * totalSOC)); // TODO Not efficient, probably
		draw rectangle(cellWidth, cellHeight) color: carbonColourValue;
	}
	
}

