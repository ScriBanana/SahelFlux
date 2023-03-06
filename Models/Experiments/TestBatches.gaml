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
	
	float lengthSimu <- 10 #years;
	bool stopCondition <- cycle > lengthSimu;
}

experiment BatchRun autorun: true type: batch repeat: nbThreads * nbRunsPerThread until: (endSimu or stopCondition) {
	
	reflex saveResults {
		ask simulations {
			save [int(self), self.nbHousehold, self.fallowEnabled, self.TT, self.cycle, self.machine_time] to: outputDirectory + "TestBatch.csv" type: "csv" rewrite: (int(self) = 0) ? true : false header: true;
		}
	}
	
	permanent {
		display Troughflow {
			chart "Throughflow kgN" type: series {
				data "Total simulation throughflow" value: simulations mean_of TT;
			}
		}
	}
	
}

