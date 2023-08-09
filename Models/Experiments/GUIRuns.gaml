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
		display "Main" parent: mainDisplay {}
	}
}

experiment SOC parent: CoreExperiment {
	
	init { experimentType <- "SOCDispRun";}
	
	output {
		layout vertical([horizontal([0::1, 1::1])::1, 2::1]) navigator: false;
		display "Main" parent: mainDisplay {}
		display "Carbon repartition" parent: carbonDisplay {}
		display "SOC evolution" parent: SOCCompartiments {}
	}
}

experiment States parent: StatesAbstract {
	
	init { experimentType <- "stateObserver";}
	
	output {
		layout vertical([horizontal([0::1, 1::1])::1, 2::1])  tabs: true navigator: false;
		
		display "Main" parent: mainDisplay {}
		display "Whole simulation" parent: stateMeter {}
		display "Real time" parent: stateFollower {}
	}
}

experiment Dashboard parent: AnimalsAbstract {
	
	init { experimentType <- "Dashboard";}
	
	output {
		layout horizontal([
				vertical([0::1667, 1::1667, 2::1667])::1000,
				vertical([3::2500, 4::2500])::2000,
				vertical([5::2500, 6::2500])::2000
			])
			consoles: true editors: false navigator: false tray: false
			tabs: true toolbars: false controls: true
		;
		
		display "Main" parent: mainDisplay {}
		display "Carbon repartition" parent: carbonDisplay {}
//		display "Whole simulation" parent: stateMeter {}
		display "Biomass" parent: biomassDisplay {}
		display "SOC evolution" parent: SOCCompartiments {}
		display "Animal density" parent: animalDisplay {}
		display "Animal digestion" parent: digestionDisplay {}
	}
}
