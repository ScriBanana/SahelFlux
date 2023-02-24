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

experiment BatchRun autorun: true type: batch repeat: nbThreads * nbRunsPerThread until: stopCondition {
	
	reflex saveResults {
		ask simulations {
			
		}
	}
	
	permanent {
		
	}
	
}

