/**
* In: SahelFlux
* Name: MobileHerds
* Mobile herds processes and finite state machine
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model MobileHerd

import "AnimalGroup.gaml"
import "SpatialEntities/Landscape.gaml"

global {
	
	//// Global mobile herds parameters
	
	//int nbHerds <- 10; // TODO DUMMY 84; // (Grillot et al, 2018)
	float meanHerdSize <- 3.7; // Tropical livestock unit (TLU) - cattle and small ruminants (Grillot et al, 2018) TODO DUMMY
	float SDHerdSize <- 3.7 * 0.4; // TODO DUMMY
	
	// Behaviour parameters
	float herdSpeed <- 0.833; // m/s = 3 km/h Does not account for grazing speed due to scale. (Own GPS data)
	float herdVisionRadius <- 20.0 #m; // (Gersie, 2020)
	int wakeUpTime <- 7; // Time of the day (24h) at which animals are released in the morning (Own accelerometer data)
	int eveningTime <- 19; // Time of the day (24h) at which animals come back to their sleeping spot (Own accelerometer data)
	bool sleepTime <- true update: !(abs(current_date.hour - (eveningTime + wakeUpTime - 1) / 2) < (eveningTime - wakeUpTime - 1) / 2);
	int dailyRestStartTime <- 12; // Time of the day (24h) at which animals start resting to avoid heat, if satiety is close to reached (Own accelerometer data)
	int dailyRestEndTime <- 15; // Time of the day (24h) at which animals stop resting to avoid heat, if satiety is close to reached (Own accelerometer data)
	bool restTime <- false update: abs(current_date.hour - (dailyRestEndTime + dailyRestStartTime - 1/2 ) / 2) < (dailyRestEndTime - dailyRestStartTime + 1/2 ) / 2;
	int maxNbNightsPerCellInPaddock <- 4; // Field data TODO Doit être un UBT/cell demandé à Jonathan
	
	// Zootechnical data
	float dailyIntakeRatePerTLU <- 6.25; // kgDM/TLU/day Maximum amount of biomass consumed daily. (Assouma et al., 2018)
	float IIRRangelandTLU <- 14.2; // instantaneous intake rate; g DM biomass eaten per minute (Chirat et al, 2014)
	float IIRCroplandTLU <- 10.9;// instantaneous intake rate; g DM biomass eaten per minute (Chirat et al, 2014)
	
	float ratioExcretionIngestion <- 0.55; // TODO DUMMY Dung excreted over ingested biomass (dry matter). Source : Wade (2016)
	
}

species mobileHerd parent: animalGroup control: fsm skills: [moving] {
	
	//// Parameters
	
	rgb herdColour;
	int herdSize min: 1; // TLU
	
	// FSM parameters and variables
	landscape targetCell;
	bool isInGoodSpot <- false;
	
	// Paddocking parameters and variables
	parcel myPaddock;
	landscape currentSleepSpot;
	int nbNightInCurrentSleepSpot;
	list<landscape> remainingSleepSpots;
	list<parcel> remainingPaddocks;
	
	// Grazing parameters and variables
	float dailyIntakeRatePerHerd <- dailyIntakeRatePerTLU * herdSize; // kgDM/herd/day
	float IIRRangelandHerd <- IIRRangelandTLU / 1000 * step / #minute * herdSize; // kgDM/herd/timestep
	float IIRCroplandHerd <- IIRCroplandTLU / 1000 * step / #minute * herdSize; // kgDM/herd/timestep
	float satietyMeter <- 0.0;
	bool hungry <- true update: (satietyMeter <= dailyIntakeRatePerHerd);
	landscape currentCell update: first(landscape overlapping self);
	
	init {
		speed <- herdSpeed;
	}
	
	//// FSM behaviour ////
	
	state isGoingToSleepSpot {
		do goto on:(landscape where each.grazable) target: currentSleepSpot;
		transition to: isSleepingInPaddock when: location overlaps currentSleepSpot.location;
	}

	state isSleepingInPaddock initial: true {
		enter {
			satietyMeter <- 0.0;
		}

		transition to: isChangingSite when: !sleepTime;
		exit {
			nbNightInCurrentSleepSpot <- nbNightInCurrentSleepSpot + 1;
			if nbNightInCurrentSleepSpot > maxNbNightsPerCellInPaddock {
				do resetSleepSpot;
				nbNightInCurrentSleepSpot <- 0;
			}
		}

	}

	state isChangingSite {
		enter {
			targetCell <- shuffle(landscape) first_with (each.cellLU = "Rangeland");
		}

		do checkSpotQuality;
		do goto on:(landscape where each.grazable) target: targetCell;
		
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isGrazing when: isInGoodSpot;
	}

	state isGrazing {
		enter {
			landscape currentGrazingCell <- first(landscape overlapping self);
		}

		list<landscape> cellsAround <- checkSpotQuality();
		if currentGrazingCell.biomassContent < cellsAround mean_of each.biomassContent { // TODO Bon, à voir...
			landscape juiciestCellAround <- one_of(cellsAround with_max_of (each.biomassContent));
			currentGrazingCell <- juiciestCellAround;
			do goto on:(landscape where each.grazable) target: currentGrazingCell;
		}

		do graze(currentGrazingCell); // Add conditional if speed*step gets significantly reduced
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isResting when: restTime or !hungry;
		transition to: isChangingSite when: !isInGoodSpot;
	}

	state isResting {
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isGrazing when: !restTime and hungry;
	}
	
	//// Functions
	
	// TODO Utiliser capture, release, migrate ?
	// species transhumance {
	// 	species transhumingHerd parent: mobileHerd {}
	// }
	
	// Identify if current cell is suitable enough, in comparison to neighbouring cells.
	list<landscape> checkSpotQuality { // and return visible cells.
		list<landscape> cellsAround <- landscape at_distance herdVisionRadius; // TODO Seems to cause slow down
		float goodSpotThreshold <- meanBiomassContent - biomassContentSD; // Gersie, 2020
		isInGoodSpot <- cellsAround mean_of each.biomassContent > goodSpotThreshold;
		return cellsAround;
	}
	
	action resetSleepSpot {
		if length(remainingSleepSpots) <= 1 {
			if length(remainingPaddocks) <= 1 {
				remainingPaddocks <- copy(myHousehold.myHomeParcelsList);
				myPaddock <- first(remainingPaddocks);
				remainingSleepSpots <- copy(myPaddock.myCells) sort_by each;
				currentSleepSpot <- first(remainingSleepSpots);
			} else {
				remainingPaddocks >- myPaddock;
				myPaddock <- first(remainingPaddocks);
				remainingSleepSpots <- copy(myPaddock.myCells) sort_by each;
				currentSleepSpot <- first(remainingSleepSpots);
			}
		} else {
			remainingSleepSpots >- currentSleepSpot;
			currentSleepSpot <- first(remainingSleepSpots);
		}
	}
	
	// Graze or browse biomass in cell
	action graze (landscape cellToGraze) {
		string eatenBiomassType <- currentCell.cellLU;
		float eatenQuantity <- eatenBiomassType = "Rangeland" ? IIRRangelandHerd : IIRCroplandHerd;
		ask cellToGraze {
			self.biomassContent <- self.biomassContent - eatenQuantity;
		}
		satietyMeter <- satietyMeter + eatenQuantity;
		chymeChunksList <+ [time, eatenBiomassType::eatenQuantity];
		
		// Save flows to flows map
		float biomassDummyCContent <- 0.8; //TODO DUMMY mettre dans input qqpart
		float biomassDummyNContent <- 0.1; //TODO DUMMY mettre dans input qqpart
		string emittingPool <- eatenBiomassType = "Rangeland" ? "Rangelands" : (currentCell.myParcel != nil and currentCell.myParcel.homeField ? "HomeFields" : "BushFields");
		ask world {	do saveFlowInMap("C", emittingPool, "TF-ToMobileHerds", eatenQuantity * biomassDummyCContent);}
		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToMobileHerds", eatenQuantity * biomassDummyNContent);}
	}
	
	// Excretion after digestionLength (Temporality differs with fattened)
	reflex herdDigest when: !empty(chymeChunksList) and (time - float(first(chymeChunksList)[0]) > digestionLength) {
		// Compute excreted OM
		map excretaOutputs <- excrete(first(chymeChunksList)[1]);
		chymeChunksList >- first(chymeChunksList);
		
		// Save N and C in cell
		currentCell.mySOCstock.periodCInputMap["HerdsDung"] <- currentCell.mySOCstock.periodCInputMap["HerdsDung"] + float(excretaOutputs["excretedCarbon"]);
		// TODO complexifier pour fitter à l'équation d'émissions de CH4
		currentCell.mySoilNProcesses.NInflows["HerdsDung"] <- currentCell.mySoilNProcesses.NInflows["HerdsDung"] + float(excretaOutputs["faecesNitrogen"]);
		currentCell.mySoilNProcesses.NInflows["HerdsUrine"] <- currentCell.mySoilNProcesses.NInflows["HerdsUrine"] + float(excretaOutputs["urineNitrogen"]);
		
		// Save flows to flows map
		string receivingPool <- currentCell.cellLU = "Rangeland" ? "TF-ToRangelands" : (currentCell.myParcel != nil and currentCell.myParcel.homeField ? "TF-ToHomeFields" : "TF-ToBushFields");
		ask world {	do saveFlowInMap("C", "MobileHerds", receivingPool , float(excretaOutputs["excretedCarbon"]));}
		ask world {	do saveFlowInMap("N", "MobileHerds", receivingPool, float(excretaOutputs["faecesNitrogen"]) + float(excretaOutputs["urineNitrogen"]));}
		
	}
	
	aspect default {
		draw square(sqrt(cellWidth ^ 2 / 2) * 0.8) rotated_by 45.0 color: herdColour border: #black;
	}
}
