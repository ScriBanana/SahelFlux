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
import "OutputProcesses/ComputeOutputs.gaml"
import "Entities/GlobalProcesses.gaml"
import "Entities/SpatialEntities/Landscape.gaml"
import "Entities/AnimalGroup.gaml"
import "Entities/Household.gaml"
import "Entities/FattenedAnimal.gaml"

global {
	
	////	--------------------------	////
	////	Global parameters	////
	////	--------------------------	////
	
	float startTimeReal <- machine_time;
	
	// Simulation calendar
	int startHour <- wakeUpTime - 1;
	date starting_date <- date([2020, 11, 1, startHour, 0, 0]); // First day of DS, before herds leave paddock. Change initial FSM state upon modification.
	date endDate <- date([2022, 10, 31, eveningTime + 1, 0, 0]);
	int drySeasonFirstMonth <- 11; // Tweaks have to be made to run with new year during the rainy season
	int rainySeasonFirstMonth <- 7;
	
	// Time step parameters
	float step <- 30.0 #minutes;
	int biophysicalProcessesUpdateFreq <- 15; // In days
	int lengthRainySeason <- int(milliseconds_between(date([2020, rainySeasonFirstMonth, 1, 0, 0]), date([2020, drySeasonFirstMonth, 1, 0, 0])) / 86400000.0); // days. Weird, but hard to find better
	int nbBiophUpdatesDuringRainySeason <- int(floor(lengthRainySeason / biophysicalProcessesUpdateFreq));
	bool updateTimeOfDay <- current_date.hour = startHour + 1 and current_date.minute = 0 update: current_date.hour = startHour + 1 and current_date.minute = 0;
	int lengthFatteningSeason <- 80; // Days. field survey.
	
	// Time related variables
	bool drySeason;
	int dayInDS <- 0;
	
	////	--------------------------	////
	////			Global init			////
	////	--------------------------	////
	init {
		do inputUnitTests;
		
		write "=== MODEL INITIALISATION ===";
		drySeason <- !(starting_date.month < drySeasonFirstMonth and starting_date.month >= rainySeasonFirstMonth);
		// All init actions defined in related species files.
		do resetFlowsMaps;
		do assignLUFromRaster;
		do initGrazableCells;
		do placeParcels;
		do segregateBushFields;
		do instantiateHouseholds; // Calls instantiation functions for several other species.
		create transhumance;
		do initiateRotations;
		do updateMeteo;
		
		write "	Start date : " + starting_date;
		write "=== MODEL INITIALISED ===";
	}

	////	--------------------------		////
	////	Global scheduler		////
	////	--------------------------		////
	
	reflex biophysicalProcessesStep when: mod(current_date.day, biophysicalProcessesUpdateFreq) = 0 and updateTimeOfDay { // Every 15 days default
		
		do updateGlobalBiomassMeanAndSD;
		ask landscape where each.biomassProducer {
			do updateColour;
		}
		
		if drySeason {
			// Regular check to see if transhumance conditions are reached yet.
			ask household where (each.isTranshumant and !dead(each.myMobileHerd)) {
				do checkTranshuCondition;
			}
		} else { // TODO faire gaffe au scheduling, notamment en début de saison
			ask landscape where each.biomassProducer {
				do growBiomass;
			}
		}
		
	}

	reflex monthStep when: current_date != (starting_date add_hours 1) and (current_date.day = 1 and updateTimeOfDay) {
		
		switch current_date.month { // Switch for annual processes, at the start of a specific month. See below for monthly processes
			
			match 1 {
			// New year processes
//				write string(current_date, "'	Y'y");
				do updateMeteo;
			}
			
			match rainySeasonFirstMonth {
				// Rainy season processes
				write "RAINY SEASON STARTS.";
				drySeason <- false;
				
				do captureRemainingTranshumants;
				
				if fallowEnabled {
					write "	Restricting herd movement to fallows";
					do transitionToFallows;
				}
				
				write "	Computing plant biomass production for the upcoming rainy season.";
				ask landscape where each.biomassProducer {
					do computeYearlyBiomassProduction;
				}
			}
			
			match drySeasonFirstMonth {
				// Dry season processes
				write "DRY SEASON STARTS.";
				drySeason <- true;
				dayInDS <- 0;
				
				ask landscape where (each.myParcel != nil) {
					do getHarvested;
				}
				ask landscape where each.biomassProducer {
					do updateColour;
				}
				do updateParcelsCovers; // Crop rotation
				
				// Retrieving herds
				ask transhumance {
					do returnHerdsToLandscape;
				}
				if fallowEnabled {
					do transitionFromFallows;
				}
			}
		}
		
		switch current_date.month { // Monthly processes only in a specific season
			match_between [rainySeasonFirstMonth, drySeasonFirstMonth - 1] {
				// Necessary to use default.
			}
			default {
				do updateTargetableCellsForChangingSiteInDS;
			}
		}
		
		// Monthly processes all year round.
		write string(date(time), "M'/'y");
		
		do addWastesToHeaps;
		ask SOCstock {
			do updateCarbonPools;
		}
		
	}
	
	reflex dailyStep when: updateTimeOfDay { // Has to come after monthStep for indentation reasons
		if mod(dayInDS, lengthFatteningSeason) = 0 and drySeason {
			if dayInDS > (365 - lengthRainySeason) * 1 / 4 { // IDK what I'm doing anymore
				write "	Selling fattenend animals.";
				ask household where each.doesFattening {
					do sellFattenedAnimals;
				}
				
			}
			
			if dayInDS < (365 - lengthRainySeason) * 3 / 4 {
				write "	Renewing fattenend animals.";
				ask household where each.doesFattening {
					do renewFattenedAnimals;
				}
				
			}
		}
		dayInDS <- dayInDS + 1;
	}

	////	--------------------------		////
	////		End statements		////
	////	--------------------------		////
	
	bool endSimu <- false;
	reflex endSim when: current_date = endDate {
		write "=== END OF SIMULATION ===";
		do gatherFlows;
		do computeENAIndicators;
		do exportStockFlowsOutputData;
		endSimu <- true; // Stops batch experiments
		write "Simulation ended. Runtime : " + (machine_time - startTimeReal)/1000 + " s";
		do pause;
	}
	
}