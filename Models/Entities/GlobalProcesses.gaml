/**
* In: SahelFlux
* Name: ORPHeap
* Rainfall controller
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model GlobalProcesses

global {
	
	//// Global external processes parameters
	
	string meteoUpdateType <- "Random" among: ["Random", "Fixed", "Input data"];
	int meanRainfall <- 590; // mm/year Thibaudeau et al 2015
	int SDRainfall <- 170; // mm/year Thibaudeau et al 2015
	
	// Variables
	int yearRainfall min: 0; // mm
	float yearMeteoQuality min: 0.0 max: 1.0; // adimensionnal, used for groundnut growth
	
	//// Global external processes functions
	
	action updateMeteo {
		write "Setting meteorological conditions for the year to come.";
		switch meteoUpdateType {
			match "Fixed" {
				yearRainfall <- meanRainfall;
				yearMeteoQuality <- 0.5;
			}
			match "Random" {
				yearRainfall <- int(gauss(meanRainfall, SDRainfall));
				yearMeteoQuality <- gauss(1.0, 0.5);
				
			}
			match "Input data" {
				assert false; // TODO Not implemented yet
			}
		}
		
	}
	
}

