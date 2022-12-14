/**
* In: SahelFlux
* Name: MobileHerds
* Mobile herds.
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model MobileHerd

import "AnimalGroup.gaml"
import "../SpatialEntities/Landscape.gaml"

global {
	
	int nbHerds <- 10; // TODO DUMMY 84; // (Grillot et al, 2018)
	float meanHerdSize <- 3.7; // Tropical livestock unit (TLU) - cattle and small ruminants (Grillot et al, 2018) TODO DUMMY
	
	// Behaviour parameters
	int wakeUpTime <- 7; // Time of the day (24h) at which animals are released in the morning (Own accelerometer data)
	int eveningTime <- 19; // Time of the day (24h) at which animals come back to their sleeping spot (Own accelerometer data)
	float herdSpeed <- 0.833; // m/s = 3 km/h Does not account for grazing speed due to scale. (Own GPS data)
	float herdVisionRadius <- 20.0 #m; // (Gersie, 2020)
	
	// Zootechnical data
	float dailyIntakeRatePerTLU <- 6.25; // kgDM/TLU/day Maximum amount of biomass consumed daily. (Assouma et al., 2018)
	float IIRRangelandTLU <- 14.2; // instantaneous intake rate; g DM biomass eaten per minute (Chirat et al, 2014)
	float IIRCroplandTLU <- 10.9;// instantaneous intake rate; g DM biomass eaten per minute (Chirat et al, 2014)
	float digestionLength <- 20.0 #h; // Duration of the digestion of biomass in the animals (expert knowledge -> ref ou préciser?)
	// TODO peut être fonction de la ration, cf MC
	
	float ratioExcretionIngestion <- 0.55; // TODO DUMMY Dung excreted over ingested biomass (dry matter). Source : Wade (2016)
	
	// Aggregation of biomass content for herds to identify cells to move to and graze
	float meanBiomassContent;
	float biomassContentSD;
	reflex updateGlobalBiomassMeanAndSD when: every(biophysicalProcessesUpdateFreq) {
		list<float> allCellsBiomass;
		ask landscape where (each.grazable) {
			allCellsBiomass <+ self.biomassContent;
		}
		meanBiomassContent <- mean(allCellsBiomass);
		biomassContentSD <- standard_deviation(allCellsBiomass);
	}
	
	action instantiateMobileHerds {
		write "Instantiating mobile herds.";
		create mobileHerd number: nbHerds with: [herdSize::round(meanHerdSize), location::(one_of(landscape where (each.cellLU = "Cropland"))).location]; //TODO DUMMY
		
	}
}

species mobileHerd parent: animalGroup control: fsm skills: [moving] {
	rgb herdColour <- rnd_color(255);
	int herdSize min: 1; // TLU
	
	// FSM parameters and variables
	bool sleepTime <- true update: !(abs(current_date.hour - (eveningTime + wakeUpTime - 1) / 2) < (eveningTime - wakeUpTime - 1) / 2);
	landscape targetCell <- one_of(landscape where each.grazable);
	bool isInGoodSpot <- false;
	
	// Paddocking parameters and variables
	//nightPaddock myPaddock <- nil;
	landscape currentSleepSpot <- one_of(landscape where (each.cellLU = "Cropland")); //TODO DUMMY location
	
	// Grazing parameters and variables
	float dailyIntakeRatePerHerd <- dailyIntakeRatePerTLU * herdSize;
	float IIRRangelandHerd <- IIRRangelandTLU / 1000 * step / #minute * herdSize;
	float IIRCroplandHerd <- IIRCroplandTLU / 1000 * step / #minute * herdSize;
	//list chymeChunksMap;
	float satietyMeter <- 0.0;
	bool hungry <- true update: (satietyMeter <= dailyIntakeRatePerHerd);
	landscape currentCell update: one_of(landscape overlapping self);
	
	init {
		speed <- herdSpeed;
	}
	
	//// FSM behaviour ////
	state isGoingToSleepSpot {
		do goto target: currentSleepSpot;
		transition to: isSleepingInPaddock when: location overlaps currentSleepSpot.location;
	}

	state isSleepingInPaddock initial: true {
		enter {
			satietyMeter <- 0.0;
		}

		transition to: isChangingSite when: !sleepTime;
		exit {
			//do updatePaddock;
		}

	}

	state isChangingSite {
		enter {
			targetCell <- one_of(landscape where (each.cellLU = "Rangeland"));
		}

		do checkSpotQuality;
		do goto target: targetCell;
		
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isGrazing when: isInGoodSpot;
	}

	state isGrazing {
		enter {
			landscape currentGrazingCell <- one_of(landscape overlapping self);
		}

		list<landscape> cellsAround <- checkSpotQuality();
		if currentGrazingCell.biomassContent < cellsAround mean_of each.biomassContent { // TODO Bon, à voir...
			landscape juiciestCellAround <- one_of(cellsAround with_max_of (each.biomassContent));
			currentGrazingCell <- juiciestCellAround;
		}

		do goto target: currentGrazingCell;
		do graze(currentGrazingCell); // Add conditional if speed*step gets significantly reduced
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isResting when: !hungry;
		transition to: isChangingSite when: !isInGoodSpot;
	}

	state isResting {
		transition to: isGoingToSleepSpot when: sleepTime;
		transition to: isGrazing when: hungry;
	}
	
	//// Functions ////
	// Identify if current cell is suitable enough, in comparison to neighbouring cells.
	list<landscape> checkSpotQuality { // and return visible cells.
		list<landscape> cellsAround <- landscape at_distance herdVisionRadius; // TODO Seems to cause slow down
		float goodSpotThreshold <- meanBiomassContent - biomassContentSD; // Gersie, 2020
		isInGoodSpot <- cellsAround mean_of each.biomassContent > goodSpotThreshold;
		return cellsAround;
	}
	
	// Graze or browse biomass in cell
	action graze (landscape cellToGraze) {
		float eatenBiomass <- currentCell.cellLU = "Rangeland" ? IIRRangelandHerd : IIRCroplandHerd;
		ask cellToGraze {
			self.biomassContent <- self.biomassContent - eatenBiomass;
		}
		satietyMeter <- satietyMeter + eatenBiomass;
	}
}

