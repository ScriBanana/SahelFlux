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
		moranOn <- false; // Tweak manually, this won't backfire
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

experiment SOCxSON type: batch autorun: true repeat: 10 until: endSimu {
	
	parameter "Landscape layout" category: "Scenario - Spatial layout" var: villageName among: villageNamesList;
	parameter "Square grid size (m)" category: "Scenario - Spatial layout" var: cellSize <- 50;
	
	init {
		experimentType <- "SOCxSON";
		
		SOCxSONOn <- true;
		
		endDate <- date([2030, 11, 1, eveningTime + 1, 0, 0]);
	}
	
	reflex saveResults {
		
		string SOCxSONOutputDirectory <- "../../OutputFiles/";
		list<float> listMeanHomefieldsSOCS;
		list<float> listMeanBushfieldsSOCS;
		list<float> listMeanRangelandSOCS;
		list<float> listMeanHomefieldsNFromSoils;
		list<float> listMeanBushfieldsNFromSoils;
		list<float> listMeanRangelandNFromSoils;
		list<float> listAlpha;
		list<float> listBeta;
		
		ask simulations {
			list<float> meanSOCS <- getMeanSOCS();
			listMeanHomefieldsSOCS <+ meanSOCS[0];
			listMeanBushfieldsSOCS <+ meanSOCS[1];
			listMeanRangelandSOCS <+ meanSOCS[2];
			
			list<float> meanLastNFromSoils <- gatherNFromSoils();
			listMeanHomefieldsNFromSoils <+ meanLastNFromSoils[0];
			listMeanBushfieldsNFromSoils <+ meanLastNFromSoils[1];
			listMeanRangelandNFromSoils <+ meanLastNFromSoils[2];
			
			float SOCxSONAlphaOutput <- (
					meanLastNFromSoils[1] - meanLastNFromSoils[0]
				) / (meanSOCS[1] - meanSOCS[0]);
			float SOCxSONBetaOutput <- (
					meanSOCS[1] * meanLastNFromSoils[0] - meanSOCS[0] * meanLastNFromSoils[1]
				) / (meanSOCS[1] - meanSOCS[0]);
				
			listAlpha <+ SOCxSONAlphaOutput;
			listBeta <+ SOCxSONBetaOutput;
			
			save [
				int(self),
				meanSOCS[0], meanSOCS[1], meanSOCS[2],
				meanLastNFromSoils[0], meanLastNFromSoils[1], meanLastNFromSoils[2],
				SOCxSONAlphaOutput, SOCxSONBetaOutput
			] to: outputDirectory + "SOCxSON/"+ runPrefix + "SOCxSON_raw.csv"
				format:"csv" rewrite: (int(self) = 0) ? true : false header: true;
			
		}
		
		float meanMeanHomefieldsSOCS <- mean(listMeanHomefieldsSOCS);
		float meanMeanBushfieldsSOCS <- mean(listMeanBushfieldsSOCS);
		float meanMeanRangelandSOCS <- mean(listMeanRangelandSOCS);
		float meanMeanHomefieldsLastNFromSoil <- mean(listMeanHomefieldsNFromSoils);
		float meanMeanBushfieldsLastNFromSoil <- mean(listMeanBushfieldsNFromSoils);
		float meanMeanRangelandLastNFromSoil <- mean(listMeanRangelandNFromSoils);
		float meanSOCxSONAlphaOutput <- mean(listAlpha);
		float meanSOCxSONBetaOutput <- mean(listBeta);
		
//		meanMeanBushfieldsSOCS <- mean([meanMeanBushfieldsSOCS, meanMeanRangelandSOCS]);
//		meanMeanBushfieldsLastNFromSoil <- mean([meanMeanBushfieldsLastNFromSoil, meanMeanRangelandLastNFromSoil]);
		// TODO Remove if an Nsoil value for rangeland is found
		
//		float meanSOCxSONAlphaOutput <- (
//			meanMeanBushfieldsLastNFromSoil - meanMeanHomefieldsLastNFromSoil
//		) / (meanMeanBushfieldsSOCS - meanMeanHomefieldsSOCS);
//		float meanSOCxSONBetaOutput <- (
//			meanMeanBushfieldsSOCS * meanMeanHomefieldsLastNFromSoil - meanMeanHomefieldsSOCS * meanMeanBushfieldsLastNFromSoil
//		) / (meanMeanBushfieldsSOCS - meanMeanHomefieldsSOCS);
		
		write "Alpha : " + meanSOCxSONAlphaOutput;
		write "Beta : " + meanSOCxSONBetaOutput;
		
		save [
			meanMeanHomefieldsSOCS, meanMeanBushfieldsSOCS,
			meanMeanHomefieldsLastNFromSoil, meanMeanBushfieldsLastNFromSoil,
			meanSOCxSONAlphaOutput, meanSOCxSONBetaOutput
		] to: outputDirectory + "SOCxSON/"+ runPrefix + "SOCxSON_AlphaBeta.csv" format:"csv" rewrite: true header: true;
		
	}
	
}

experiment MorrisBatch type: batch autorun: true until: endSimu {
	
	string batchId <- "MorrisOut"; // !!! machine_time doesn't work; NO INDIVIDUAL BATCH ID; BACKUP RESULTS
	
	parameter "Landscape layout" category: "Scenario - Spatial layout" var: villageName among: ["Sob", "Barry"]; //villageNamesList;
	
	parameter "Proportion transhuming households" var: propTranshumantHhExplo min: 0.0 max: 1.0;
	parameter "Proportion fattening households" var: propFatteningHhExplo min: 0.0 max: 1.0;
	parameter "HerdSize average" var: meanHerdSizeExplo min: 1.0 max: 15.0;
	parameter "FattenedGroupSize average" var: meanFattenedGroupSizeExplo min: 0.01 max: 3.0;
	parameter "Home fields proportion" var: homeFieldsProportionExplo min: 0.1 max: 0.9;
	
	init {
		experimentType <- "Morris";
		isExplo <- true;
		moranOn <- false;
		
		endDate <- date([2025, 11, 1, eveningTime + 1, 0, 0]);
	}
	
	method morris
		levels: 4
		outputs: ["ecosystemGHGBalance", "totalGHG", "ecosystemCBalance", "ecosystemNBalance", "totalMeanSOCS", "ICRN", "ICRC", "totalNFlows", "totalCFlows"]
		sample: 100
		report: outputDirectory + "Morris/"+ batchId + ".txt"
		results: outputDirectory + "Morris/"+ batchId + "_raw.csv"
	;
}

experiment sobolBatch type: batch autorun: true until: endSimu {
	string batchId <- "SobolOut";

	parameter "Landscape layout" category: "Scenario - Spatial layout" var: villageName among: ["Sob", "Barry"]; //villageNamesList;
	
	parameter "Proportion transhuming households" var: propTranshumantHhExplo min: 0.0 max: 1.0;
	parameter "Proportion fattening households" var: propFatteningHhExplo min: 0.0 max: 1.0;
	parameter "HerdSize average" var: meanHerdSizeExplo min: 1.0 max: 15.0;
	parameter "FattenedGroupSize average" var: meanFattenedGroupSizeExplo min: 0.01 max: 3.0;
	parameter "Home fields proportion" var: homeFieldsProportionExplo min: 0.1 max: 0.9;
	
	init {
		experimentType <- "Sobol";
		isExplo <- true;
		moranOn <- false;
		
		endDate <- date([2025, 11, 1, eveningTime + 1, 0, 0]);
	}
	
	method sobol
		outputs: ["ecosystemGHGBalance", "totalGHG", "ecosystemCBalance", "ecosystemNBalance", "totalMeanSOCS", "ICRN", "ICRC", "totalNFlows", "totalCFlows"]
		sample: 100
		report: outputDirectory + "Sobol/"+ batchId + ".txt"
		results: outputDirectory + "Sobol/"+ batchId + "_raw.csv"
	;
}
