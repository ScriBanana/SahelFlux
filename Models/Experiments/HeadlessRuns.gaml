/**
* In: SahelFlux
* Name: HeadlessRuns
* Fast or long experiments for testing or specific DOE
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model SahelFlux

import "CoreExperiment.gaml"

experiment FastAutoRun parent: CoreWithParameters autorun: true {
	
	init {
		experimentType <- "FastAutoRun";
		
		enableDebug <- true;
		parallelHerds <- true;
		
		endDate <- date([2021, 2, 1, eveningTime + 1, 0, 0]);
		nbHousehold <- 10;
		propTranshumantHh <- 0.5;
		propFatteningHh <- 0.5;
	}
	
	output synchronized: false {
		layout tabs: false navigator: false;
	}
}

experiment BenchmarkRun parent: CoreWithParameters benchmark: true autorun: true {
	
	init {
		experimentType <- "BenchmarkRun";
		
		enableDebug <- false;
		parallelHerds <- false;
		
		endDate <- date([2022, 11, 1, eveningTime + 1, 0, 0]);
	}
}


