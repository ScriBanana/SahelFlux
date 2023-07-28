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
	bool batchOn <- false;
	bool enabledGUI <- false;
	
	// Village choice
	list<string> villageNamesList <- ["Barry", "Sob", "Diohine"];
	string villageName <- "Sob" among: villageNamesList;
	
	// Time and calendar parameters
	float step <- 30.0 #minutes;
	int biophysicalProcessesUpdateFreq <- 15; // In days
	int drySeasonFirstMonth <- 11; // Tweaks have to be made to run with new year during the rainy season
	int rainySeasonFirstMonth <- 7;
	int lengthFatteningSeason <- 80; // Days. field survey. TODO Ndiaye says 120
	int ORPSpreadingPeriodLength <- 3; // Months Period of time before the start of the rainy season during which ORP is spread on homefields; Surveys
	int ORPSpreadingFrequency <- 3; // days between ORP Spreads during spreading period TODO DUMMY
	int startHour <- wakeUpTime - 1;
	date starting_date <- date([2020, 11, 1, startHour, 0, 0]); // First day of DS, before herds leave paddock. Change initial FSM state upon modification.
	date endDate <- date([2026, 11, 1, eveningTime + 1, 0, 0]);
	int lengthRainySeason <- int(milliseconds_between(
		date([2020, rainySeasonFirstMonth, 1, 0, 0]), date([2020, drySeasonFirstMonth, 1, 0, 0])
	) / 86400000.0); // days. Weird, but hard to find better
	int nbBiophUpdatesDuringRainySeason <- int(floor(lengthRainySeason / biophysicalProcessesUpdateFreq));
	
	// Time related variables
	bool updateTimeOfDay <- current_date.hour = startHour + 1 and current_date.minute = 0
		update: current_date.hour = startHour + 1 and current_date.minute = 0;
	bool drySeason;
	int dayInDS <- 0;
	bool spreadingSeason;
	int daysSinceSpread <- 0;
	
	////	--------------------------	////
	////			Global init			////
	////	--------------------------	////
	init {
		do inputUnitTests;
		
		write "=== RUN " + int(self) + " INITIALISATION ===";
		
		// Init variables
		drySeason <- !(
			starting_date.month < drySeasonFirstMonth and starting_date.month >= rainySeasonFirstMonth
		);
		spreadingSeason <- (
			starting_date.month >= rainySeasonFirstMonth - ORPSpreadingPeriodLength and
			starting_date.month < rainySeasonFirstMonth
		);
		nonEmptyLandscape <- list(landscape);
		
		// All init actions defined in related species files.
		do resetFlowsMaps;
		do readLandscapeInputData;
		do initGrazableCells;
		do placeParcels;
		do instantiateHouseholds; // Calls instantiation functions for several other species.
		do designateHomeFields;
		do createMobileHerds;
		create transhumance;
		do initiateRotations;
		write "Initialising meteorological conditions for year 1";
		do updateMeteo;
		do initSOCStocks;
		do getMeanSOCS;
		meanHomefieldsSOCSInit <- meanHomefieldsSOCS;
		meanBushfieldsSOCSInit <- meanBushfieldsSOCS;
		meanRangelandSOCSInit <- meanRangelandSOCS;
		totalMeanSOCSInit <- totalMeanSOCS;
		
		write "Start date : " + starting_date + ", end date : " + endDate;
		runTime <- (machine_time - startTimeReal) / 60000;
		write "=== MODEL INITIALISED (" + runTime * 60 + " s) ===";
	}
	
	////	--------------------------		////
	////	Global scheduler		////
	////	--------------------------		////
	
	reflex biophysicalProcessesStep when: mod(current_date.day, biophysicalProcessesUpdateFreq) = 0 and updateTimeOfDay { // Every 15 days default
		
		ask grazableLandscape {
			
			if enabledGUI { do updateColour;}
			// TODO faire gaffe au scheduling, notamment en début de saison
			if !drySeason { do growBiomass;}
		}
		
		if drySeason {
			// Regular check to see if transhumance conditions are reached yet.
			ask household where (each.isTranshumant and !dead(each.myMobileHerd)) {
				do checkTranshuCondition;
			}
		}
	}

	reflex monthStep when: current_date != (starting_date add_hours 1) and (current_date.day = 1 and updateTimeOfDay) {
		
		switch current_date.month { // Switch for annual processes, at the start of a specific month. See below for monthly processes
			
			match 1 {
			// New year processes
				do updateMeteo;
			}
			
			match rainySeasonFirstMonth {
				// Rainy season processes
				write "RAINY SEASON STARTS.";
				drySeason <- false;
				spreadingSeason <- false;
				
				do captureRemainingTranshumants;
				
				if fallowEnabled {
					write "	Restricting herd movement to fallows";
					do transitionToFallows;
				}
				
				ask SOCStock { do emitRSSoilCH4;}
				ask ORPHeap { do emitRSHeapsCH4;}
				write "	Incorporating and burning (millet) remaining biomass.";
				write "	Computing plant biomass production for the upcoming rainy season.";
				ask grazableLandscape {
					do burnAndIncorporateResidualBiomass;
					do computeYearlyBiomassProduction;
				}
				
			}
			
			match drySeasonFirstMonth {
				// Dry season processes
				write "DRY SEASON STARTS.";
				drySeason <- true;
				dayInDS <- 0;
				daysSinceSpread <- 0;
				
				ask grazableLandscape { do getHarvestedAndBurrowRoots;}
				do updateParcelsCovers; // Crop rotation
				
				// Retrieving herds
				ask transhumance {	do returnHerdsToLandscape;}
				if fallowEnabled { do transitionFromFallows;}
			}
			
			match rainySeasonFirstMonth - ORPSpreadingPeriodLength {
				write "	ORP spreading starts.";
				spreadingSeason <- true;
				daysSinceSpread <- 0;
			}
		}
		
		// Monthly processes all year round.
		write string(date(time), "M'/'y");
		// TODO do some of these come before what's above?
		do addWastesToHeaps;
		ask SOCStock { do updateCarbonPools;}
		ask ORPHeap where (each.myHousehold.myFattenedAnimals != nil) { do accumulateFattenedInputs;}
		
		if generateMonthlySaves { do saveOutputsDuringSim;}
		
	}
	
	reflex dailyStep when: updateTimeOfDay { // Has to come after monthStep for indentation reasons
		
		do updateGlobalBiomassMeanAndSD;
		// Mobile herds mechanisms
		ask mobileHerd {
			loop biomassType over: dailyIntakes.keys {
				do emitMetaboIntake(biomassType, dailyIntakes[biomassType]);
			}
			dailyIntakes <- ["Rangeland"::0.0, "HomeFields"::0.0, "BushFields"::0.0];
		}
		
		// ORP spreading mechanisms
		if spreadingSeason {
			if daysSinceSpread >= 3 {
				ask ORPHeap where (each.heapQuantity > 0.0) {
					do spreadORPOnParcels;
				}
				daysSinceSpread <- 0;
			} else {
				daysSinceSpread <- daysSinceSpread + 1;
			}
		}
		
		if drySeason {
			do updateTargetableCellsForChangingSiteInDS;
			
			// Fattening mechanisms
			if mod(dayInDS, lengthFatteningSeason) = 0 {
				if dayInDS > (365 - lengthRainySeason) * 1 / 4 { // IDK what I'm doing anymore
					ask household where each.doesFattening {
						do sellFattenedAnimals;
					}
				}
				
				if (current_date != (starting_date add_hours 1)) and (dayInDS < (365 - lengthRainySeason) * 3 / 4) {
					ask household where each.doesFattening {
						do renewFattenedAnimals;
					}
					write "	Renewed fattened animals. " +  fattenedAnimal sum_of each.groupSize + " new animals.";
				}
			}
		}
		
		ask fattenedAnimal { // Could be someting else than daily.
			do fattenedDigest;
			do eat;
		}
		
		dayInDS <- dayInDS + 1;
	}

	////	--------------------------		////
	////		End statements		////
	////	--------------------------		////
	
	bool endSimu <- false;
	float runTime; // seconds
	reflex endSim when: current_date = endDate {
		runTime <- (machine_time - startTimeReal) / 60000;
		
		write "=== END OF SIMULATION ===";
		
		do gatherFlows;
		do computeOutputs;
		do gatherOutputsAndParameters;
		do saveLogOutput;
		do exportStockFlowsOutputData;
		
		write "Simulation ended. Runtime : " + floor(runTime) + " min " + round((runTime - floor(runTime)) * 60 ) + " s";
		
		if batchOn {
			endSimu <- true;
		} else {
			write "GHG emissions :";
			write GHGFlowsMap;
			write "N flows :";
			write NFlowsMatrix;
			write "C flows :";
			write CFlowsMatrix;
			write "Flows balance and total GHG per pool :";
			write poolFlowsMap;
			write "		N throughflow : " + int(floor(totalNThroughflows)) + " kgN";
			write "		C throughflow : " + int(floor(totalCThroughflows)) + " kgC";
			
			do pause;
		}
	}
	
}