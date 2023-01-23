/**
* In: SahelFlux
* Name: Main
* Model main file.
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "SpatialEntities/Landscape.gaml"
import "Agents/AnimalGroup.gaml"
import "Agents/Household.gaml"
import "ExpeRun.gaml"
import "ComputeOutputs.gaml"

global {
	
	// Simulation calendar
	date starting_date <- date([2020, 11, 1, wakeUpTime - 1, 0, 0]); // First day of DS, before herds leave paddock. Change initial FSM state upon modification.
	int drySeasonFirstMonth <- 11;
	int rainySeasonFirstMonth <- 7;
	date endDate <- date([2022, 10, 31, eveningTime + 1, 0, 0]); // After 
	
	// Time step parameters
	float step <- 30.0 #minutes;
	int biophysicalProcessesUpdateFreq <- 14; // In days
	float visualUpdate <- 7.0 #week;
	bool drySeason <- true; // If first day during dry season
	
	// Global init
	init {
		write "=== MODEL INITIALISATION ===";
		
		// All actions defined in related species files.
		do assignLUFromRaster;
		write "Computing grazable biomass contents.";
		ask landscape where each.grazable {
			do drySeasonStartUpdateGrazBiomassContent; // Redundant with first month, but allows clean init
			do updateColour;
		}
		do placeParcels;
		do segregateBushFields;
		//do instantiateMobileHerds;
		do instantiateHouseholds;
		
		write "=== MODEL INITIALISED ===";
	}
	
	reflex week when: mod(current_date.day, biophysicalProcessesUpdateFreq) = 0 {
		do updateGlobalBiomassMeanAndSD;
	}

	// Global scheduler
	reflex monthStep when: (current_date.day = 1 and current_date.hour = 7 and current_date.minute = 0) {
		
		// Year print
		if current_date.month = 1 {
			write string(current_date, "'	Y'y");
		}
		
		// Season print
		if (current_date.month = drySeasonFirstMonth) {
			write "	Dry season starts.";
			drySeason <- true;
			
			// Compute grazable biomass contents
			write "Computing plant biomass production.";
			ask landscape where (each.cellLU = "Rangeland" or "Cropland") {
				do biomassProduction;
			}
			
			// Compute grazable biomass contents
			write "Computing grazable biomass contents.";
			ask landscape where each.grazable {
				do drySeasonStartUpdateGrazBiomassContent;
			}

		} else if (current_date.month = rainySeasonFirstMonth) {
			write "	Rain season starts.";
			drySeason <- false;
		}
		
		// Month print
		write string(date(time), "'		M'M");
		
		ask landscape where each.grazable {
			//biomassContent <- biomassContent * ( 1 - rnd(0.125)); //TODO DUMMY
			do updateColour;
		}
	}

	
	// Break statement
	reflex endSim when: current_date = endDate {
		write "=== END OF SIMULATION ===";
		do pause;
	}
	
}