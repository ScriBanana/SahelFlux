/**
* In: SahelFlux
* Name: BatchRuns
* Plain batches (replications only)
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model BatchRuns

import "../Main.gaml"

global {
	
	float lengthSimu <- 2.0;
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
	
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold min: 0;
	parameter "Number transhuming households" category: "Scenario - Population structure" var: nbTranshumantHh min: 0 max: nbHousehold;
	parameter "Number fattening households" category: "Scenario - Population structure" var: nbFatteningHh min: 0 max: nbHousehold;
	
	method morris
		levels: 4
		outputs: ["totalCFlows", "CThroughflow", "totalNFlows", "TT"]
		sample: 6
		report: outputDirectory + "/Morris/morris.txt"
		results: outputDirectory + "/Morris/morris_raw.csv"
	;
}
