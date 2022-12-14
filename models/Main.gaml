/**
* In: SahelFlux
* Name: Main
* Model main file.
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "SpatialEntities/Landscape.gaml"
import "Agents/AnimalGroup.gaml"
import "ExpeRun.gaml"

global {
	
	// Simulation calendar
	date starting_date <- date([2020, 11, 1, 7, 0, 0]);
	int drySeasonFirstMonth <- 11;
	int rainySeasonFirstMonth <- 7;
	float endDate <- 2.0 #years;
	
	// Time step parameters
	float step <- 30.0 #minutes;
	float biophysicalProcessesUpdateFreq <- 1.0 #week;
	float outputsComputationFreq <- 1.0 #year;
	float visualUpdate <- 1.0 #week; // For all but the main display
	
	
	init {
		write "MODEL INITIALISATION";
		do importLURaster;
		do drySeasonStartUpdateBiomassContent;
	}
	
	// Time prints
	reflex regularPrompt when: (current_date.day = 1 and current_date.hour = 7 and current_date.minute = 0) {
		write string(date(time), "'		M'M");
		
		if (current_date.month = rainySeasonFirstMonth) {
			write "	Rain season starts.";
		} else if (current_date.month = drySeasonFirstMonth) {
			write "	Dry season starts.";
		}
	}
	
	// Break statement
	reflex endSim when: time > endDate {
		write "END OF SIMULATION";
		do pause;
	}
	
}