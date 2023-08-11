/**
* In: SahelFlux
* Name: BatchRuns
* Plain batches
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model SahelFlux

import "CoreExperiment.gaml"

global {
	init {
		batchOn <- true;
	}
}

experiment BatchRun autorun: true type: batch repeat: 6 until: endSimu {
	
	init{
		experimentType <- "SimpleBatch";
		
		endDate <- date([2030, 11, 1, eveningTime + 1, 0, 0]);
	}
	
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

experiment SOCxSON type: batch autorun: true repeat: 52 until: endSimu {
	
	init {
		experimentType <- "SOCxSON";
		
		SOCxSONOn <- false;
		
		endDate <- date([2030, 11, 1, eveningTime + 1, 0, 0]);
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
			] to: outputDirectory + "SOCxSON/"+ runPrefix + "SOCxSON_raw.csv"
				format:"csv" rewrite: (int(self) = 0) ? true : false header: true;
			
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
		] to: outputDirectory + "SOCxSON/"+ runPrefix + "SOCxSON_AlphaBeta.csv" format:"csv" rewrite: true header: true;
		
	}
	
}

experiment MorrisBatch type: batch autorun: true until: endSimu {
	
	parameter "Village" var: villageName among: villageNamesList;
	parameter "Number households and mobile herds" var: nbHousehold min: 20 max: 150;
	parameter "Number transhuming households" var: propTranshumantHh min: 0.0 max: 1.0;
	parameter "Number fattening households" var: propFatteningHh min: 0.0 max: 1.0;
	parameter "HerdSize average" var: meanHerdSize min: 1.0 max: 20.0;
	parameter "FattenedGroupSize average" var: meanFattenedGroupSize min: 0.5 max: 5.0;
	
	init {
		write villageName;
		experimentType <- "Morris";
		
		endDate <- date([2020, 12, 1, eveningTime + 1, 0, 0]);
	}
	
	method morris
		levels: 4
		outputs: ["TSTN", "TSTC", "ecosystemCBalance", "ecosystemGHGBalance"]
		sample: 1
		report: outputDirectory + "Morris/"+ runPrefix + "morris.txt"
		results: outputDirectory + "Morris/"+ runPrefix + "morris_raw.csv"
	;
}
