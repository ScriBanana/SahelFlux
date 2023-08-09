/**
* In: SahelFlux
* Name: MobileHerds
* Mobile herds processes and finite state machine
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "AnimalGroup.gaml"

global {
	
	//// Global mobile herds parameters
	
	bool parallelHerds <- false; // Needs to be false for parallel batch runs
	
	float meanHerdSize; // <- 3.7; // Tropical livestock unit (TLU) - cattle and small ruminants (Grillot et al, 2018)
	float SDHerdSize; // <- meanHerdSize * 0.4;
	
	// Behaviour parameters
	float herdSpeed <- 0.833; // m/s = 3 km/h Does not account for grazing speed due to scale. (Own GPS data)
	float herdVisionRadius <- 20.0 #m const: true; // (Gersie, 2020)
	int wakeUpTime <- 7 const: true; // Time of the day (24h) at which animals are released in the morning (Own accelerometer data)
	int eveningTime <- 19 const: true; // Time of the day (24h) at which animals come back to their sleeping spot (Own accelerometer data)
	int dailyRestStartTime <- 13 const: true; // Time of the day (24h) at which animals start resting to avoid heat, if satiety is close to reached (Own accelerometer data)
	int dailyRestEndTime <- 15 const: true; // Time of the day (24h) at which animals stop resting to avoid heat, if satiety is close to reached (Own accelerometer data)
	int maxNbNightsPerCellInPaddock <- 4; // Field data TODO Doit être un UBT/cell demandé à Jonathan
	int maxNbFallowPaddock <- 2; // TODO Confirm
	
	// Zootechnical data
	float IIRRangelandTLU <- 14.2; // instantaneous intake rate; g DM biomass eaten per minute (Chirat et al, 2014)
	float IIRCroplandTLU <- 10.9; // instantaneous intake rate; g DM biomass eaten per minute (Chirat et al, 2014)
	
	// Variables
	bool sleepTime;
	bool restTime;
	float herdsIntakeFlow;
	float herdsExcretionsFlow;
	float totalHerdsIntakeFlow;
	float totalHerdsExcretionsFlow;
	
	reflex herdsInternalClock { // Unsure if time is gained over updates.
		sleepTime <- !(
			abs(current_date.hour - (eveningTime + wakeUpTime - 1) / 2) <
			(eveningTime - wakeUpTime - 1) / 2
		) ? true : false;
		restTime <-
			abs(current_date.hour - (dailyRestEndTime + dailyRestStartTime - 1/2 ) / 2) <
			(dailyRestEndTime - dailyRestStartTime + 1/2 ) / 2
		? true : false;
	}
	
	action createMobileHerds{
		write "Creating mobile herds.";
		ask household {
			create mobileHerd with: [
				myHousehold::self,
				herdSize::round(abs(gauss(meanHerdSize - 1, SDHerdSize) + 1)),
				herdColour::self.householdColour
			] {	
				myHousehold.myMobileHerd <- self;
				// Paddocking initialisation
				myPaddockList <- copy(myHousehold.myHomeParcelsList);
				do resetSleepSpot;
				location <- currentSleepSpot.location;
				currentCell <- first(landscape overlapping self);
			}
		}
		if enableDebug {assert mobileHerd min_of each.herdSize > 0;}
		write "	Done. " + length(mobileHerd) + " mobile herds. Total cheptel : " + mobileHerd sum_of each.herdSize + " TLU.";
	}
		
}

species mobileHerd parent: animalGroup control: fsm skills: [moving] parallel: parallelHerds {
	// Use parallel: true for normal runs (saves a lot of computation time), false for batches (messes up with Java array handling).
	
	//// Parameters
	
	// General
	rgb herdColour;
	int herdSize min: 1; // TLU
	
	// Paddocking parameters and variables
	parcel currentPaddock;
	landscape currentSleepSpot;
	int nbNightInCurrentSleepSpot;
	list<landscape> remainingSleepSpots;
	list<parcel> myPaddockList;
	list<parcel> remainingPaddocks;
	
	// Variables to store the latter during the rainy season, meant for scenarios where fallow is enabled
	parcel lastDSPaddock;
	landscape lastDSSleepSpot;
	int lastDSNbNightInCurrentSleepSpot;
	list<landscape> lastDSRemainingSleepSpots;
	list<parcel> lastDSPaddockList;
	list<parcel> lastDSRemainingPaddocks;
	
	// Grazing local parameters and variables
	float dailyIntakeRatePerHerd <- dailyIntakeRatePerMobileTLU * herdSize; // kgDM/herd/day
	float IIRRangelandHerd <- IIRRangelandTLU / 1000 * step / #minute * herdSize; // kgDM/herd/timestep
	float IIRCroplandHerd <- IIRCroplandTLU / 1000 * step / #minute * herdSize; // kgDM/herd/timestep
	float satietyMeter <- 0.0;
	bool hungry update: satietyMeter <= dailyIntakeRatePerHerd;
	landscape currentCell update: first(landscape overlapping self);
	map<string, float> dailyIntakes <- ["Rangeland"::0.0, "HomeFields"::0.0, "BushFields"::0.0];
	
	//// FSM behaviour
	
	// FSM variables
	landscape targetCell;
	bool isInGoodSpot <- false;
	
	// States
	state isGoingToSleepSpot {
		if !(location overlaps currentSleepSpot.location) {
			do goto on: walkableLandscape speed: herdSpeed target: currentSleepSpot recompute_path: false;
		}
		
		transition to: isSleepingInPaddock when: location overlaps currentSleepSpot.location;
	}
	
	state isSleepingInPaddock initial: true {
		enter {
			satietyMeter <- 0.0;
			hungry <- true;
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
			targetCell <- one_of(targetableCellsForChangingSite);
		}

		do checkSpotQuality;
		if !isInGoodSpot and !sleepTime {
			do goto on: walkableLandscape target: targetCell speed: herdSpeed recompute_path: false;
		}
		
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isGrazing when: isInGoodSpot or currentCell = targetCell;
	}
	
	state isGrazing {
		enter {
			landscape currentGrazingCell <- currentCell;
			list<landscape> cellsAround <- checkSpotQuality();
		}

		if currentGrazingCell.biomassContent < cellsAround mean_of each.biomassContent {
			landscape juiciestCellAround <- one_of(cellsAround with_max_of (each.biomassContent));
			currentGrazingCell <- juiciestCellAround;
			if isInGoodSpot {//and !sleepTime and hungry and !restTime {
				do goto on: walkableLandscape target: currentGrazingCell speed: herdSpeed recompute_path: false;
			}
			cellsAround <- checkSpotQuality();
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
	
	// Identify if current cell is suitable enough, in comparison to neighbouring cells.
	list<landscape> checkSpotQuality { // and return visible cells.
		list<landscape> cellsAround <- landscape at_distance herdVisionRadius;
		float goodSpotThreshold <- meanBiomassContent;// + biomassContentSD; // Gersie, 2020
		isInGoodSpot <- cellsAround mean_of each.biomassContent > goodSpotThreshold;
		return cellsAround;
	}
	
	// Cjhanges sleepspot (and paddock) whenever the number of nights is depleted
	action resetSleepSpot {
		if length(remainingSleepSpots) <= 1 {
			if length(remainingPaddocks) <= 1 {
				remainingPaddocks <- copy(myPaddockList);
				currentPaddock <- first(remainingPaddocks);
				remainingSleepSpots <- copy(currentPaddock.myCells) sort_by each;
				currentSleepSpot <- first(remainingSleepSpots);
			} else {
				remainingPaddocks >- currentPaddock;
				currentPaddock <- first(remainingPaddocks);
				remainingSleepSpots <- copy(currentPaddock.myCells) sort_by each;
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
		float eatenQuantity <- eatenBiomassType = "Rangeland" ? IIRRangelandHerd : IIRCroplandHerd; // kgDM/herd/timestep
		if enableDebug {	assert cellToGraze.biomassContent >= 0.0;} // Grazing attempt on a depleted cell
		
		eatenQuantity <-  cellToGraze.biomassContent > eatenQuantity ? eatenQuantity : cellToGraze.biomassContent;
		ask cellToGraze {
			self.biomassContent <- self.biomassContent - eatenQuantity;
		}
		satietyMeter <- satietyMeter + eatenQuantity;
		chymeChunksList <+ [time, eatenBiomassType::eatenQuantity];
		dailyIntakes[eatenBiomassType] <- dailyIntakes[eatenBiomassType] + eatenQuantity;
		
		// emitMetaboIntake is called in main.gaml
		
		// Follows global grazing rate
		herdsIntakeFlow <- herdsIntakeFlow + eatenQuantity;
		
		string emittingPool;
		float eatenBiomassNContent;
		float eatenBiomassCContent;
		
		if eatenBiomassType = "Rangeland" {
			emittingPool <- "Rangelands";
			if drySeason {
				eatenBiomassNContent <- forageDSNContent;
				eatenBiomassCContent <- forageDSCContent;
			} else {
				eatenBiomassNContent <- forageRSNContent;
				eatenBiomassCContent <- forageRSCContent;
			}
		} else {
			emittingPool <- currentCell.homefieldCell ? "HomeFields" : "BushFields";
			eatenBiomassNContent <- milletResiduesNContent;
			eatenBiomassCContent <- milletResiduesCContent;
		}
		
		ask world {	do saveFlowInMap("C", emittingPool, "TF-ToMobileHerds", eatenQuantity * eatenBiomassCContent);}
		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToMobileHerds", eatenQuantity * eatenBiomassNContent);}
	}
	
	// Excretion after digestionLength (Temporality differs with fattened)
	reflex herdDigest when: !empty(chymeChunksList) and (time - float(first(chymeChunksList)[0]) > digestionLength) {
		// Compute excreted OM
		map excretaOutputs <- excrete(first(chymeChunksList)[1]);
		chymeChunksList >- first(chymeChunksList);
		
		// Emit N gases
		// N2O direct
		float mobileHerdNDirectFaecesN2OEmissions <- float(excretaOutputs["faecesNitrogen"]) * emissionFactorN2ODungUrine; // kgN
		float mobileHerdNDirectUrineN2OEmissions <- float(excretaOutputs["urineNitrogen"]) * emissionFactorN2ODungUrine; // kgN
		
		// Indirect RS
		float mobileHerdFaecesNGasLoss <- float(excretaOutputs["faecesNitrogen"]) * fractionGasLossOrganicFerti; // kgN
		float mobileHerdUrineNGasLoss <- float(excretaOutputs["urineNitrogen"]) * fractionGasLossOrganicFerti; // kgN
		
		// The rest gets incorporated
		float mobileHerdIncorporatedFaecesN <-
			float(excretaOutputs["faecesNitrogen"]) - (mobileHerdNDirectFaecesN2OEmissions + mobileHerdFaecesNGasLoss)
		;
		float mobileHerdIncorporatedUrineN <-
			float(excretaOutputs["urineNitrogen"]) - (mobileHerdNDirectUrineN2OEmissions + mobileHerdUrineNGasLoss)
		;
		
		// Save N and C in cell
		float currentVSE <- float(excretaOutputs["volatileSolidExcreted"]);
		float currentCFlow <- float(excretaOutputs["excretedCarbon"]);
		currentCell.mySOCstock.carbonInputsList <+ ["HerdsDung", currentVSE, currentCFlow];
		currentCell.mySoilNProcesses.NInflows["HerdsDung"] <-
			currentCell.mySoilNProcesses.NInflows["HerdsDung"] + mobileHerdIncorporatedFaecesN
		;
		currentCell.mySoilNProcesses.NInflows["HerdsUrine"] <-
			currentCell.mySoilNProcesses.NInflows["HerdsUrine"] + mobileHerdIncorporatedUrineN
		;
		
		// Follows global excretion rate
		herdsExcretionsFlow <- herdsExcretionsFlow + currentVSE;
		
		// Save flows to flows map
		string receivingPool <- currentCell.cellLU = "Rangeland" ? "TF-ToRangelands" : (
			currentCell.homefieldCell ? "TF-ToHomeFields" : "TF-ToBushFields"
		);
		string emissionsEmittingPool <- currentCell.cellLU = "Rangeland" ? "Rangelands" : (
			currentCell.homefieldCell ? "HomeFields" : "BushFields"
		);
		ask world {	do saveFlowInMap("C", "MobileHerds", receivingPool,
			float(excretaOutputs["excretedCarbon"])
		);}
		ask world {	do saveFlowInMap("N", emissionsEmittingPool, "OF-GHG" ,
			mobileHerdNDirectFaecesN2OEmissions + mobileHerdNDirectUrineN2OEmissions
		);}
		ask world { do saveGHGFlow(emissionsEmittingPool, "N2O",
			(mobileHerdNDirectFaecesN2OEmissions + mobileHerdNDirectUrineN2OEmissions) / coefN2OToN
		);}
		ask world {	do saveFlowInMap("N", emissionsEmittingPool, "OF-AtmoLosses" ,
			mobileHerdFaecesNGasLoss + mobileHerdUrineNGasLoss
		);}
		ask world {	do saveFlowInMap("N", "MobileHerds", receivingPool,
			float(excretaOutputs["faecesNitrogen"]) + float(excretaOutputs["urineNitrogen"])
		);}
		
	}
	
	//// Aspect
	
	aspect default {
		draw square(sqrt(cellWidth ^ 2 / 2) * 0.8) rotated_by 45.0 color: herdColour border: #black;
	}
}
