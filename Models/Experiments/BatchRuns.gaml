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

experiment BatchRun autorun: true type: batch repeat: 12 until: endSimu {
	
	init{ experimentType <- "SimpleBatch";}
		
	parameter "Simulation length (years)" var: lengthSimu <- 0.1;
	
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

experiment BatchLongRuns autorun: true type: batch repeat: 52 until: endSimu {
	
	parameter "Simulation length (years)" var: lengthSimu <- 50.0;
	
	init {
		generateMonthlySaves <- true;
		fallowEnabled <- true;
		experimentType <- "BatchLongRuns";
	}
}

experiment SOCxSON type: batch autorun: true repeat: 52 until: endSimu {
	
	init {
		SOCxSONOn <- false;
		lengthSimu <- 20.0;
		experimentType <- "SOCxSON";
	}
	
	reflex saveResults {
		
		list<float> listMeanHomefieldsSOCS;
		list<float> listMeanBushfieldsSOCS;
		list<float> listMeanRangelandSOCS;
		list<float> listMeanHomefieldsNFromSoils;
		list<float> listMeanBushfieldsNFromSoils;
		list<float> listMeanRangelandNFromSoils;
		
		ask simulations {
			list<float> meanSOCS <- getMeanSOCS();
			listMeanHomefieldsSOCS <+ meanSOCS[0];
			listMeanBushfieldsSOCS <+ meanSOCS[1];
			listMeanRangelandSOCS <+ meanSOCS[2];
			
			list<float> meanLastNFromSoils <- gatherNFromSoils();
			listMeanHomefieldsNFromSoils <+ meanLastNFromSoils[0];
			listMeanBushfieldsNFromSoils <+ meanLastNFromSoils[1];
			listMeanRangelandNFromSoils <+ meanLastNFromSoils[2];
			
			save [
				int(self),
				meanSOCS[0], meanSOCS[1], meanSOCS[2],
				meanLastNFromSoils[0], meanLastNFromSoils[1], meanLastNFromSoils[2]
			] to: outputDirectory + "SOCxSON/"+ universalPrefix + "SOCxSON_raw.csv" format:"csv" rewrite: (int(self) = 0) ? true : false header: true;
			
		}
		
		float meanMeanHomefieldsSOCS <- mean(listMeanHomefieldsSOCS);
		float meanMeanBushfieldsSOCS <- mean(listMeanBushfieldsSOCS);
		float meanMeanRangelandSOCS <- mean(listMeanRangelandSOCS);
		float meanMeanHomefieldsLastNFromSoil <- mean(listMeanHomefieldsNFromSoils);
		float meanMeanBushfieldsLastNFromSoil <- mean(listMeanBushfieldsNFromSoils);
		float meanMeanRangelandLastNFromSoil <- mean(listMeanRangelandNFromSoils);
		
//		meanMeanBushfieldsSOCS <- mean([meanMeanBushfieldsSOCS, meanMeanRangelandSOCS]);
//		meanMeanBushfieldsLastNFromSoil <- mean([meanMeanBushfieldsLastNFromSoil, meanMeanRangelandLastNFromSoil]);
		// TODO Remove if an Nsoil value for rangeland is found
		
		float SOCxSONAlphaOutput <- (
			meanMeanBushfieldsLastNFromSoil - meanMeanHomefieldsLastNFromSoil
		) / (meanMeanBushfieldsSOCS - meanMeanHomefieldsSOCS);
		float SOCxSONBetaOutput <- (
			meanMeanBushfieldsSOCS * meanMeanHomefieldsLastNFromSoil - meanMeanHomefieldsSOCS * meanMeanBushfieldsLastNFromSoil
		) / (meanMeanBushfieldsSOCS - meanMeanHomefieldsSOCS);
		
		write "Alpha : " + SOCxSONAlphaOutput;
		write "Beta : " + SOCxSONBetaOutput;
		
		save [
			meanMeanHomefieldsSOCS, meanMeanBushfieldsSOCS,
			meanMeanHomefieldsLastNFromSoil, meanMeanBushfieldsLastNFromSoil,
			SOCxSONAlphaOutput, SOCxSONBetaOutput
		] to: outputDirectory + "SOCxSON/"+ universalPrefix + "SOCxSON_AlphaBeta.csv" format:"csv" rewrite: true header: true;
		
	}
	
}

experiment MorrisBatch type: batch autorun: true until: endSimu {
	
	parameter "Number households and mobile herds" var: nbHousehold min: 20 max: 150;
	parameter "Number transhuming households" var: propTranshumantHh min: 0.0 max: 1.0;
	parameter "Number fattening households" var: propFatteningHh min: 0.0 max: 1.0;
	parameter "Fallow on" var: fallowEnabled <- false among: [true, false];
	parameter "HerdSize average" var: meanHerdSize min: 1.0 max: 10.0;
	parameter "FattenedGroupSize average" var: meanFattenedGroupSize min: 0.5 max: 5.0;
	parameter "maxNbNightsPerCellInPaddock" var: maxNbNightsPerCellInPaddock min: 1 max: 10;
	
	init {
		nbBushFieldsPerHh <- 8;
		nbHomeFieldsPerHh <- 1;
		lengthSimu <- 1.0;
		experimentType <- "Morris";
	}
	
	method morris
		levels: 4
		outputs: ["totalNFlows", "TT", "totalCFlows", "CThroughflow"]
		sample: 52
		report: outputDirectory + "Morris/"+ universalPrefix + "morris.txt"
		results: outputDirectory + "Morris/"+ universalPrefix + "morris_raw.csv"
	;
}
