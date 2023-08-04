/**
* In: SahelFlux
* Name: HeadlessRuns
* Fast or long experiments for testing or specific DOE
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model HeadlessRuns

import "../Main.gaml"

global {
	init {
		generateMonthlySaves <- true; // TODO Shitty workaround
		parallelHerds <- true;
	}
}

experiment FastAutoRun autorun: true {
	
	init {
		experimentType <- "FastAutoRun";
		enableDebug <- true;
		generateMonthlySaves <- false; // TODO Shitty workaround
	}
	
	// 3 month short auto run 
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold <- 10 min: 0;
	parameter "Number transhuming households" category: "Scenario - Population structure" var: propTranshumantHh <- 0.5 min: 0.0 max: 1.0;
	parameter "Number fattening households" category: "Scenario - Population structure" var: propFatteningHh <- 0.5 min: 0.0 max: 1.0;
	
	parameter "Short run start date" var: starting_date <- date([2020, 4, 10, eveningTime + 1, 0, 0]);
	parameter "Short run end date" var: endDate <- date([2020, 7, 1, eveningTime + 1, 0, 0]);
}

experiment LongRun {
	
	init {
		experimentType <- "LongRun";
		enableDebug <- true;
	}
	
	// 20 year run that records output matrixes each month
	parameter "Long run start date" category: "Scenario - Time" var: starting_date;
	parameter "Long run end date" category: "Scenario - Time" var: endDate <- date([2022, 11, 1, eveningTime + 1, 0, 0]);
	
	parameter "Enable fallow (3-years rotation)" category: "Scenario - Spatial layout" var: fallowEnabled <- true;
//	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold <- 50 min: 0;// updates: [nbTranshumantHh, nbFatteningHh];
//	parameter "Number transhuming households" category: "Scenario - Population structure" var: nbTranshumantHh <- 10 min: 0 max: nbHousehold;
//	parameter "Number fattening households" category: "Scenario - Population structure" var: nbFatteningHh <- 10 min: 0 max: nbHousehold;
	
	
	
	output {
		display SOCCompartiments type: java2D refresh:  current_date.day = 1 and updateTimeOfDay {
			chart "Average SOC per compartment (kgC/ha)" type: series {
				data "Labile C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland") mean_of each.labileCPool) / hectareToCell color: #darkkhaki;
				data "Stable C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland")  mean_of each.stableCPool) / hectareToCell color: #olive;
				data "Labile C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.labileCPool) / hectareToCell color: #green;
				data "Stable C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.stableCPool) / hectareToCell color: #darkgreen;
				data "Total C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland")  mean_of each.totalSOC) / hectareToCell color: #grey;
				data "Total C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.totalSOC) / hectareToCell color: #black;
			}
		}
	}
	
}

experiment BenchmarkRun benchmark: true autorun: true {
	
	init {
		experimentType <- "BenchmarkRun";
		generateMonthlySaves <- false; // TODO Shitty workaround
		parallelHerds <- false;
		enableDebug <- false;
		endDate <- date([2022, 11, 1, eveningTime + 1, 0, 0]);
	}
}


