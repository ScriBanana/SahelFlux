/**
* In: SahelFlux
* Name: MonthlySavedRuns
* Simulations store output data in a CSV each month
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "GUIVariables.gaml"

global {
	init {
		generateMonthlySaves <- true;
		parallelHerds <- false;
	}
}

experiment LongRun parent: AnimalsAbstract {
	
	init {
		experimentType <- "LongRun";
		
		enableDebug <- true;
		
		endDate <- date([2030, 11, 1, eveningTime + 1, 0, 0]);
	}
	
	output {
		layout #split consoles: true editors: false navigator: false
			tray: false tabs: true toolbars: false controls: true;
		
		display "Biomass" parent: biomassChart {}
		display "SOC evolution" parent: SOCChart {}
		display "Animal density" parent: animalChart {}
		display "Animal digestion" parent: digestionChart {}
	}
}

experiment BatchLongRuns autorun: true type: batch repeat: 3 until: endSimu {
	
	parameter "Landscape layout" category: "Scenario - Spatial layout" var: villageName among: ["Sob", "Barry"];//villageNamesList;
	
	init {
		experimentType <- "BatchLongRuns";
		
		batchOn <- true;
		generateMonthlySaves <- true;
		
		endDate <- date([2030, 11, 1, eveningTime + 1, 0, 0]);
	}
}
