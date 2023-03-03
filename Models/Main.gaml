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

global {
	
	////	--------------------------	////
	////	Global parameters	////
	////	--------------------------	////
	
	// Simulation calendar
	int startHour <- wakeUpTime - 1;
	date starting_date <- date([2020, 11, 1, startHour, 0, 0]); // First day of DS, before herds leave paddock. Change initial FSM state upon modification.
	date endDate <- date([2022, 10, 31, eveningTime + 1, 0, 0]);
	int drySeasonFirstMonth <- 11; // Tweaks have to be made to run with new year during the rainy season
	int rainySeasonFirstMonth <- 7;
	
	// Time step parameters
	float step <- 30.0 #minutes;
	int biophysicalProcessesUpdateFreq <- 15; // In days
	
	// Time related variables
	bool drySeason;
	int lengthRainySeason <- int(milliseconds_between(date([2020, rainySeasonFirstMonth, 1, 0, 0]), date([2020, drySeasonFirstMonth, 1, 0, 0])) / 86400000.0); // days. Weird, but hard to find better
	int nbBiophUpdatesDuringRainySeason <- int(floor(lengthRainySeason / biophysicalProcessesUpdateFreq));
	bool updateTimeOfDay <- current_date.hour = startHour + 1 and current_date.minute = 0 update: current_date.hour = startHour + 1 and current_date.minute = 0;
	
	////	--------------------------	////
	////			Global init			////
	////	--------------------------	////
	init {
		do inputUnitTests;
		
		write "=== MODEL INITIALISATION ===";
		drySeason <- !(starting_date.month < drySeasonFirstMonth and starting_date.month >= rainySeasonFirstMonth);
		// All init actions defined in related species files.
		do assignLUFromRaster;
		do initGrazableCells;
		do placeParcels;
		do segregateBushFields;
		do instantiateHouseholds; // Calls instantiation functions for several other species.
		create transhumance;
		do initiateRotations;
		do updateMeteo;
		do resetFlowsMaps;
		
		write "	Start date : " + starting_date;
		write "=== MODEL INITIALISED ===";
	}

	////	--------------------------		////
	////	Global scheduler		////
	////	--------------------------		////
	
	reflex biophysicalProcessesStep when: (mod(current_date.day, biophysicalProcessesUpdateFreq) = 0 and updateTimeOfDay) { // Every 15 days default
		
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

	reflex monthStep when: (current_date != (starting_date add_hours 1) and (current_date.day = 1 and updateTimeOfDay)) {
		
		switch current_date.month {
			
			match rainySeasonFirstMonth {
			// Rainy season processes
				write "RAINY SEASON STARTS.";
				drySeason <- false;
				
				write "	Sending remaining transhuming herds to transhumance";
				ask transhumance {
					capture mobileHerd where (each.myHousehold.isTranshumant) as: transhumingHerd;
				}
				
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
				do updateParcelsCovers;
				drySeason <- true;
				ask transhumance {
					do returnHerdsToLandscape;
				}
				if fallowEnabled {
					do transitionFromFallows;
				}
			}
			
			match 1 {
			// New year processes
//				write string(current_date, "'	Y'y");
				do updateMeteo;
			}
		}
		
		// Monthly processes
		write string(date(time), "M'/'y");
		
		do addWastesToHeaps;
		ask SOCstock {
			do updateCarbonPools;
		}
		
	}

	////	--------------------------		////
	////		End statements		////
	////	--------------------------		////
	
	reflex endSim when: current_date = endDate {
		write "=== END OF SIMULATION ===";
		do gatherFlows;
		do exportOutputData;
		do pause;
	}
	
}