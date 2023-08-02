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
	float homefieldsSOChaInit; // kgC/ha
	float bushfieldsSOChaInit; // kgC/ha
	float rangelandSOChaInit; // kgC/ha
	float homefieldsSOCInit; // kgC/cell
	float bushfieldsSOCInit; // kgC/cell
	float rangelandSOCInit; // kgC/cell
	
	// SOC model (ICBM) parameters
	float labileCPoolProportionInit <- 0.2; // own regression
	float stableCPoolProportionInit <- 0.8; // own regression
	
	float edaphicClimateFactor <- 3.0 const: true; // Dimensionless; own regression
	float kineticLabile <- 0.8; // Dimensionless; own regression
	float kineticStable <- 0.01; // Dimensionless; own regression
	float humificationCoef <- 0.05 const: true; // Dimensionless; own regression
	init { // Conversion to get the SOC process to work with kgC/cell insteat of tC/ha
		kineticLabile <- kineticLabile / 1000 / hectareToCell;
		kineticStable <- kineticStable / 1000 / hectareToCell;
	}
	
	// Setting Euler discretisation solver parameter
	float criticalNbStepLabileForDiscretisation <- 2 / (kineticLabile * edaphicClimateFactor); // Computed for Euler method.
	float criticalNbStepStableForDiscretisation <- 2 / (kineticStable * edaphicClimateFactor);
	float criticalNbStepForDiscretisation <- min(
		criticalNbStepLabileForDiscretisation, criticalNbStepStableForDiscretisation
	); // Stable is way higher with default parameters
	float boundaryNbStepForDiscretisation <- 0.8 * criticalNbStepForDiscretisation; // 0.8 factor for safety
	int solverIterations <- int(ceil(1 / boundaryNbStepForDiscretisation)); // Default 2
	float solverDeltaT <- boundaryNbStepForDiscretisation / solverIterations; // Default 0.5
	
	// Display parameter
	float maxCColor <- 4000.0; // kgC/cell; Arbitrary max for color scale in displays
	
	//// Global SOC functions
	
	action initSOCStocks {
		ask SOCStock {
			float initSOC <- myCell.cellLU = "Rangeland" ?
				rangelandSOCInit :
				(myCell.homefieldCell ? homefieldsSOCInit : bushfieldsSOCInit)
			;
			float initSOCLabile <- initSOC * labileCPoolProportionInit;
			labileCPool <- gauss(initSOCLabile, initSOCLabile * 0.1);
			float initSOCStable <- initSOC * stableCPoolProportionInit;
			stableCPool <- gauss(initSOCStable, initSOCLabile * 0.1);
			totalSOC <- labileCPool + stableCPool;
		}
	}
	
	// Mean SOCS computation
	float meanHomefieldsSOCS; // kgC
	float meanBushfieldsSOCS; // kgC
	float meanRangelandSOCS; // kgC
	float totalMeanSOCS; // kgC
	float meanHomefieldsSOCSInit; // kgC
	float meanBushfieldsSOCSInit; // kgC
	float meanRangelandSOCSInit; // kgC
	float totalMeanSOCSInit; // kgC
	
	action getMeanSOCS {
		meanHomefieldsSOCS <- (SOCStock where (each.myCell.homefieldCell)) mean_of each.stableCPool;
		meanBushfieldsSOCS <- (
			SOCStock where (each.myCell.cellLU = "Cropland" and !each.myCell.homefieldCell)
		) mean_of each.stableCPool;
		meanRangelandSOCS <- (
			SOCStock where (each.myCell.cellLU = "Rangeland")
		) mean_of each.stableCPool;
		// TODO Unoptimised triple loop
		totalMeanSOCS <- meanHomefieldsSOCS + meanBushfieldsSOCS + meanRangelandSOCS;
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
	
	action updateCarbonPools { // Monthly default
		
		// Aggregate input
		float periodCInput; // kgC
		
		// Mobile herds and ORP
		periodCInput <- periodCInput + aggregateCIntputsComputeRSCH4();
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
		string emittingPool <- myCell.cellLU = "Rangeland" ? "Rangelands" : (myCell.homefieldCell ? "HomeFields" : "BushFields");
		ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG" , emissionsFromStable + emissionsFromLabile);}
		ask world { do saveGHGFlow(emittingPool, "CO2", (emissionsFromStable + emissionsFromLabile) / coefCO2ToC);}
	}
	
	float aggregateCIntputsComputeRSCH4 {
		
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
		string emittingPool <- myCell.cellLU = "Rangeland" ? "Rangelands" : (myCell.homefieldCell ? "HomeFields" : "BushFields");
		ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG" , myself.CH4ToBeEmittedInRainySeason * coefCH4ToC);}
		ask world { do saveGHGFlow(emittingPool, "CH4", myself.CH4ToBeEmittedInRainySeason);}
		CH4ToBeEmittedInRainySeason <- 0.0;
	}
	
	aspect default {
		rgb carbonColourValue <- rgb(int(255 + (75 - 255) / maxCColor * totalSOC), int(255 + (52 - 255) / maxCColor * totalSOC), int(255 + (0 - 255) / maxCColor * totalSOC)); // TODO Not efficient, probably
		draw rectangle(cellWidth, cellHeight) color: carbonColourValue;
	}
	
}

