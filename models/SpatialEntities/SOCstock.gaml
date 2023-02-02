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

species SOCstock parallel: true { // TODO parent/ mirror/ intégrer à Landscape???
	
	landscape myCell;
	map<string, float> periodCInputMap <- ["HerdsDung"::0.0, "Straw"::0.0, "ORP"::0.0];
	float labileCPool <- labileCPoolInit;
	float stableCPool <- stableCPoolInit;
	
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
		float periodCinput;
		// TODO virer les émissions
		loop input over: periodCInputMap {
			periodCinput <- periodCinput + input;
		}
		return periodCinput;
		periodCinput <- 0.0;
	}
	
}

