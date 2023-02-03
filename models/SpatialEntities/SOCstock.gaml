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
	
	float croplandSOChaInit <- 8.9; // kgC/ha; Loum selon Ndour TODO sourcer + à assigner aux LU
	float rangelandSOChaInit <- 11.1; // kgC/ha; Loum selon Ndour TODO sourcer + à assigner aux LU
	float croplandSOCInit <- croplandSOChaInit * hectareToCell;
	float rangelandSOCInit <- rangelandSOChaInit * hectareToCell;
	float labileCPoolProportionInit <- 0.2; // own regression
	float stableCPoolProportionInit <- 0.8; // own regression
	
	float dummyCEmittedAtDungDepositFactor <- 0.3; // TODO DUMMY (duh)
	
	float maxCColor <- 15.0 * hectareToCell; // kgC/cell; Arbitrary max for color scale in displays
}

species SOCstock parallel: true { // TODO parent/ mirror/ intégrer à Landscape???
	
	landscape myCell;
	map<string, float> periodCInputMap <- ["HerdsDung"::0.0, "Straw"::0.0, "ORP"::0.0]; // kg/ha
	float labileCPool;
	float stableCPool;
	float CToBeEmittedInRainySeason;
	
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
		
		// TODO very DUMMY
		CToBeEmittedInRainySeason <- periodCInputMap["HerdsDung"] * dummyCEmittedAtDungDepositFactor;
		periodCInputMap["HerdsDung"] <- periodCInputMap["HerdsDung"] - CToBeEmittedInRainySeason;
		
		periodCinput <- sum(periodCInputMap);
		periodCInputMap <- ["HerdsDung"::0.0, "Straw"::0.0, "ORP"::0.0];
		return periodCinput;
	}
	
	aspect default {
		location <- myCell.location;
		
		rgb carbonColourValue <- rgb(int(255 + (75 - 255) / maxCColor * (labileCPool + stableCPool)), int(255 + (52 - 255) / maxCColor * (labileCPool + stableCPool)), int(255 + (0 - 255) / maxCColor * (labileCPool + stableCPool))); // TODO Not efficient, probably
		draw rectangle(cellWidth, cellHeight) color: carbonColourValue;
		
	}
	
}

