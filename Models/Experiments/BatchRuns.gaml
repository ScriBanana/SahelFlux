/**
* In: SahelFlux
* Name: BatchRuns
* Plain batches (replications only)
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model BatchRuns

import "../Main.gaml"

global {
	
	float lengthSimu <- 4.0;
	float simuDuration;
	float lengthYear <- 31536000.0; // seconds in a year
	
	init {
		batchOn <- true;
		simuDuration <- lengthYear * lengthSimu;
		endDate <- starting_date + simuDuration;
	}
}

experiment BatchRun autorun: true type: batch repeat: 1014 until: endSimu {
	
	parameter "Simulation length (years)" var: lengthSimu <- 2.0;
	
//	reflex saveResults { // Redundant with saveBatchRunOutput, but backuping is good
//		write "End of batch, backing up outputs.";
//		ask simulations {
//			write "Saving output for simulation " + int(self);
//			save [
//				int(self), self.nbHousehold, self.nbTranshumantHh, self.nbFatteningHh, self.fallowEnabled,
//				self.cycle, self.machine_time, self.runTime,
//				self.totalNFlows, self.totalCFlows, self.TT, self.CThroughflow
//			] to: outputDirectory + "BatchSamplesBackup/SamplingRun-" + floor(rnd(1.0) * 100000) + ".csv" format: "csv" rewrite: false header: true;
//		}
//	}
	
//	permanent {
//		display Troughflow type: java2D {
//			chart "Throughflow kgN" type: series {
//				data "Total simulation throughflow" value: simulations mean_of TT;
//			}
//		}
//	}
}

experiment BatchLongRuns autorun: true type: batch repeat: 48 until: endSimu {
	
	parameter "Simulation length (years)" var: lengthSimu <- 50.0;
	
	init {
		generateMonthlySaves <- true;
		fallowEnabled <- true;
	}
}

experiment MorrisBatch type: batch autorun: true until: endSimu {
	
	parameter "Number households and mobile herds" var: nbHousehold min: 20 max: 150;
//	parameter "Number transhuming households" var: propTranshumantHh min: 0.0 max: 1.0;
//	parameter "Number fattening households" var: propFatteningHh min: 0.0 max: 1.0;
//	parameter "Fallow on" var: fallowEnabled <- false among: [true, false];
//	parameter "HerdSize average" var: meanHerdSize min: 1.0 max: 10.0;
//	parameter "FattenedGroupSize average" var: meanFattenedGroupSize min: 0.5 max: 5.0;
//	parameter "maxNbNightsPerCellInPaddock" var: maxNbNightsPerCellInPaddock min: 1 max: 10;
	
	init {
		nbBushFieldsPerHh <- 8;
		nbHomeFieldsPerHh <- 1;
		lengthSimu <- 0.1;
	}
	
	method morris
		levels: 4
		outputs: ["totalCFlows"]
		sample: 24
		report: "Morris/morris.txt"
		results: "Morris/morris_raw.csv"
	;
}
