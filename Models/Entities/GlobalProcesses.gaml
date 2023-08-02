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
	int meanRainfall <- 590 const: true; // mm/year Thibaudeau et al 2015
	int SDRainfall <- 170 const: true; // mm/year Thibaudeau et al 2015
	
	// Variables
	int yearRainfall min: 1; // mm; min 1 to apease the ln
	float yearMeteoQuality min: 0.0 max: 1.0; // adimensionnal, used for groundnut growth
	
	//// Global external processes functions
	
	action updateMeteo {
		switch meteoUpdateType {
			match "Fixed" {
				yearRainfall <- meanRainfall;
				yearMeteoQuality <- 0.5;
			}
			match "Random" {
				yearRainfall <- int(gauss(meanRainfall, SDRainfall) with_precision 3);
				yearMeteoQuality <- gauss(0.5, 0.3) with_precision 1;
			}
			match "Input data" {
				assert false; // TODO Not implemented yet
			}
		}
		write "	Meteo for the year to come : " + yearRainfall + " mm, " + int(yearMeteoQuality * 10) + "/10 groundnut quality.";
		
	}
	
}

