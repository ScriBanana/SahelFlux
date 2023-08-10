/**
* In: SahelFlux
* Name: GUIRuns
* Experiments with GUI on
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "GUIVariables.gaml"

global {
	init {
		parallelHerds <- true;
		enableDebug <- true;
		enabledGUI <- true;
	}
}

experiment Run type: gui parent: CoreWithParameters {
	
	init {experimentType <- "GUIRun";}
	
	output {
		layout tabs: false navigator: false;
		display "Main" parent: SpatialMainDisplay {}
	}
}

experiment SOC type: gui parent: CoreExperiment {
	
	init { experimentType <- "SOCDispRun";}
	
	output {
		layout vertical([horizontal([0::1, 1::1])::1, 2::1]) navigator: false;
		display "Main" parent: SpatialMainDisplay {}
		display "CarbonRepartition" parent: SpatialCarbonDisplay {}
		display "SOCEvolution" parent: SOCChart {}
	}
}

experiment States parent: StatesAbstract {
	
	init { experimentType <- "stateObserver";}
	
	output {
		layout vertical([horizontal([0::1, 1::1])::1, 2::1])  tabs: true navigator: false;
		
		display "Main" parent: SpatialMainDisplay {}
		display "Whole simulation" parent: stateMeter {}
		display "Real time" parent: stateFollower {}
	}
}

experiment Dashboard parent: AnimalsAbstract {
	
	init { experimentType <- "Dashboard";}
	
	output {
		layout horizontal([
				vertical([0::1, 1::1])::1,
				vertical([2::2500, 3::2500])::2,
				vertical([4::2500, 5::2500])::2
			])
			consoles: true editors: false navigator: false tray: false
			tabs: true toolbars: false controls: true
		;
		
		display "Main" parent: SpatialMainDisplay {}
		display "CarbonRepartition" parent: SpatialCarbonDisplay {}
//		display "Whole simulation" parent: stateMeter {}
		display "Biomass" parent: biomassChart {}
		display "SOCEvolution" parent: SOCChart {}
		display "AnimalDensity" parent: animalChart {}
		display "AnimalDigestion" parent: digestionChart {}
	}
}
