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
	
	float croplandSOChaInit <- 8900.0; // kgC/ha; Loum selon Ndour TODO sourcer + à assigner aux LU
	float rangelandSOChaInit <- 11100.0; // kgC/ha; Loum selon Ndour TODO sourcer + à assigner aux LU
	float croplandSOCInit <- croplandSOChaInit * hectareToCell; // kgC/cell
	float rangelandSOCInit <- rangelandSOChaInit * hectareToCell; // kgC/cell
	float labileCPoolProportionInit <- 0.2; // own regression
	float stableCPoolProportionInit <- 0.8; // own regression
	
	float dummyCEmittedAtDungDepositFactor <- 0.3; // TODO DUMMY (duh)
	
	float maxCColor <- 4000.0; // kgC/cell; Arbitrary max for color scale in displays
	
	date lastSOCComputation <- starting_date;
	action updateSOCStocks {
		write "Updating C pools";
		ask SOCstock {
			do updateCarbonPools;
		}
		lastSOCComputation <- current_date;
	}
}

species SOCstock parallel: true { // TODO parent/ mirror/ intégrer à Landscape???
	
	landscape myCell;
	map<string, float> periodCInputMap <- ["HerdsDung"::0.0, "Straw"::0.0, "ORP"::0.0]; // kg/ha
	float periodCinput;
	float labileCPool; // kgC/cell
	float stableCPool; // kgC/cell
	float totalSOC; // kgC/cell
	float CToBeEmittedInRainySeason;
	float SOCProcessesPeriodLength;
	
//	// ICBM model (Andrén & Kätterer, 1997)
//	equation ICBM {
//		diff(labileCPool, SOCProcessesPeriodLength) = periodCinput - kineticLabile * edaphicClimateFactor * labileCPool;
//		diff(stableCPool, SOCProcessesPeriodLength) = humificationCoef * kineticLabile * edaphicClimateFactor * labileCPool - kineticStable * edaphicClimateFactor * stableCPool;
//	}
	
	action updateCarbonPools {
		SOCProcessesPeriodLength <- (current_date - lastSOCComputation);
		// Compute input
		// TODO very DUMMY
		CToBeEmittedInRainySeason <- periodCInputMap["HerdsDung"] * dummyCEmittedAtDungDepositFactor;
		periodCInputMap["HerdsDung"] <- periodCInputMap["HerdsDung"] - CToBeEmittedInRainySeason;
		periodCinput <- sum(periodCInputMap);
		
		// Flows to and from the two pools
		float humifiedC <- (humificationCoef * kineticLabile * edaphicClimateFactor * labileCPool) / SOCProcessesPeriodLength;
		float emissionsFromLabile <- ((1 - humificationCoef) * kineticLabile * edaphicClimateFactor * labileCPool) / SOCProcessesPeriodLength;
		float emissionsFromStable <- (kineticStable * edaphicClimateFactor * stableCPool) / SOCProcessesPeriodLength;

		// Update pools SOC content
		labileCPool <- labileCPool + periodCinput - humifiedC - emissionsFromLabile;
		stableCPool <- stableCPool + humifiedC - emissionsFromStable;
		totalSOC <- labileCPool + stableCPool;
		
		// Return flows for output indicators computation
		return ["periodCinput"::periodCinput, "humifiedC"::humifiedC, "emissionsFromStable"::emissionsFromStable, "emissionsFromLabile"::emissionsFromLabile, "periodStableCVar"::(humifiedC - emissionsFromStable), "periodLabileCVar"::(periodCinput - humifiedC - emissionsFromLabile), "periodSOCVar"::periodCinput - emissionsFromLabile - emissionsFromStable]; // TODO periodSOCVar a modifier selon le modèle de SCS?
		
		// Reset input
		periodCInputMap <- ["HerdsDung"::0.0, "Straw"::0.0, "ORP"::0.0];
		periodCinput <- 0.0;
	}

	
	aspect default {
		location <- myCell.location;
		
		rgb carbonColourValue <- rgb(int(255 + (75 - 255) / maxCColor * totalSOC), int(255 + (52 - 255) / maxCColor * totalSOC), int(255 + (0 - 255) / maxCColor * totalSOC)); // TODO Not efficient, probably
		draw rectangle(cellWidth, cellHeight) color: carbonColourValue;
		
	}
	
}

