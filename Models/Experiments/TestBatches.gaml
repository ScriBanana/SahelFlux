/**
* In: SahelFlux
* Name: TestBatches
* Simple batches to test out specific processes
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model TestBatches

import "../Main.gaml"

global {
	
	int nbThreads <- 8;
	int nbRunsPerThread <- 10;
	// repeat facet has to be set directly to allow parallelism, somehow
	
	float lengthSimu <- 4 #years;
	bool stopCondition <- cycle > lengthSimu;
	
	init {
		batchOn <- true;
		endDate <- starting_date + lengthSimu;
	}
}

experiment BatchRun autorun: true type: batch repeat: 12 until: (endSimu or stopCondition) {
	
	reflex saveResults {
		write "End of batch, backing up outputs.";
		ask simulations {
			write "Saving output for simulation " + int(self);
			save [
				int(self), self.nbHousehold, self.nbTranshumantHh, self.nbFatteningHh, self.fallowEnabled,
				self.cycle, self.machine_time,
				self.totalNFlows, self.totalCFlows, self.TT, self.CThroughflow
			] to: outputDirectory + "BatchSamplesBackup/SamplingRun-" + floor(rnd(1.0) * 100000) + ".csv" format: "csv" rewrite: false header: true;
		}
	}
	
//	permanent {
//		display Troughflow type: java2D {
//			chart "Throughflow kgN" type: series {
//				data "Total simulation throughflow" value: simulations mean_of TT;
//			}
//		}
//	}
	
}

