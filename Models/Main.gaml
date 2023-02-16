/**
* In: SahelFlux
* Name: Main
* SahelFlux model main file.
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
* Find readme and up to date code at https://github.com/ScriBanana/SahelFlux.
*/


model SahelFlux

import "../Utilities/UnitTests.gaml"
import "../Utilities/GenerateExportFiles.gaml"
import "Entities/GlobalProcesses.gaml"
import "Entities/SpatialEntities/Landscape.gaml"
import "Entities/AnimalGroup.gaml"
import "Entities/Household.gaml"
import "Experiments/BasicRuns.gaml"

global {
	
	////	--------------------------	////
	////	Global parameters	////
	////	--------------------------	////
	
	// Simulation calendar
	date starting_date <- date([2020, 11, 1, wakeUpTime - 1, 0, 0]); // First day of DS, before herds leave paddock. Change initial FSM state upon modification.
	date endDate <- date([2022, 10, 31, eveningTime + 1, 0, 0]);
	int drySeasonFirstMonth <- 11;
	int rainySeasonFirstMonth <- 7;
	int lengthRainySeason <- drySeasonFirstMonth - rainySeasonFirstMonth;
	
	// Time step parameters
	float step <- 30.0 #minutes;
	int biophysicalProcessesUpdateFreq <- 14; // In days
	float visualUpdate <- 7.0 #week;
	bool drySeason <- true; // If first day during dry season
	
	////	--------------------------	////
	////			Global init			////
	////	--------------------------	////
	init {
		do inputUnitTests;
		
		write "=== MODEL INITIALISATION ===";
		// All actions defined in related species files.
		do assignLUFromRaster;
		do initGrazableCells;
		do placeParcels;
		do segregateBushFields;
		do instantiateHouseholds; // Calls instantiation functions for several other species.
		do initiateRotations;
		do resetFlowsMaps;
		
		write "=== MODEL INITIALISED ===";
		write "Start date : " + starting_date;
	}

	////	--------------------------	////
	////	Global scheduler	////
	////	--------------------------	////
	
	reflex biophysicalProcessesStep when: (mod(current_date.day, biophysicalProcessesUpdateFreq) = 0 and current_date.hour = wakeUpTime and current_date.minute = 0){
		do updateGlobalBiomassMeanAndSD;
		
		if !drySeason { // TODO faire gaffe au scheduling, notamment en début de saison
			ask landscape where each.biomassProducer {
					do growBiomass;
			}
		}
	}

	reflex monthStep when: (current_date != (starting_date add_hours 1) and (current_date.day = 1 and current_date.hour = wakeUpTime and current_date.minute = 0)) {
		
		switch current_date.month {
			match 1 {
			// New year processes
				write string(current_date, "'	Y'y");
			}

			match drySeasonFirstMonth {
			// Dry season processes
				write "	Dry season starts.";
				do updateParcelsCovers;
				drySeason <- true;
				
			}
			
			match rainySeasonFirstMonth {
			// Rainy season processes
				write "	Rainy season starts.";
				drySeason <- false;
				
				write "Computing plant biomass production for the upcoming rainy season.";
				ask landscape where each.biomassProducer {
					do computeYearlyBiomassProduction;
				}
				
			}
		}
		
		// Monthly processes
		write string(date(time), "'		'M'/'y");
		
		do addWastesToHeaps;
		do updateSOCStocks;
		ask landscape where each.biomassProducer {
			do updateColour;
		}
		
		// Refresh display
		secondaryDisplayRefresh <- true;
		
	}

	////	--------------------------	////
	////		End statements		////
	////	--------------------------	////
	
	reflex endSim when: current_date = endDate {
		write "=== END OF SIMULATION ===";
		do gatherFlows;
		do exportOutputData;
		do pause;
	}
	
}