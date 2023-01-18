/**
* In: SahelFlux
* Name: SOCstock
* Soil organic carbon stock
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SOCstock

import "../Main.gaml"

global {
	// SOC model (ICBM) parameters
	float edaphicClimateFactor <- 3.0; // Dimensionless; own regression
	float kineticLabile <- 0.8; // Dimensionless; own regression
	float kineticStable <- 0.01; // Dimensionless; own regression
	float humificationCoef <- 0.05; // Dimensionless; own regression
	
	float labileCPoolInit <- 0.2; // kgC; own regression
	float stableCPoolInit <- 0.8; // kgC; own regression
}

species SOCstock {
	
	float labileCPool <- labileCPoolInit;
	float stableCPool <- stableCPoolInit;
	
	reflex updateSOCStockFlows when: every(biophysicalProcessesUpdateFreq) { // TODO A intégrer au scheduler?
		// Induce and store flows and stock variations
		map<string, float> soilCFlows <- updateCarbonPools();
	}
	
	action updateCarbonPools {
		// Flows to and from the two pools
		float periodCinput <- computeCarbonInput();
		float humifiedC <- humificationCoef * kineticLabile * edaphicClimateFactor * labileCPool;
		float emissionsFromLabile <- (1 - humificationCoef) * kineticLabile * edaphicClimateFactor * labileCPool;
		float emissionsFromStable <- kineticStable * edaphicClimateFactor * stableCPool;
		
		// Update pools SOC content
		labileCPool <- labileCPool + periodCinput - humifiedC - emissionsFromLabile;
		stableCPool <- stableCPool + humifiedC - emissionsFromStable;
		
		// Return flows for output indicators computation
		return ["periodCinput"::periodCinput, "humifiedC"::humifiedC, "emissionsFromStable"::emissionsFromStable, "emissionsFromLabile"::emissionsFromLabile, "periodStableCVar"::(humifiedC - emissionsFromStable), "periodLabileCVar"::(periodCinput - humifiedC - emissionsFromLabile), "periodSOCVar"::periodCinput - emissionsFromLabile - emissionsFromStable]; // TODO periodSOCVar a modifier selon le modèle de SCS?
	}
	
	float computeCarbonInput {
		// Carbon that enters the soil
		float periodCinput <- 0.0;
		periodCinput <- periodCinput + 1.0; //TODO dummy
		periodCinput <- periodCinput + 1.0; //TODO dummy
		return periodCinput;
	}
	
}

