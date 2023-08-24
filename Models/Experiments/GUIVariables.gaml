/**
* In: SahelFlux
* Name: GUIVariables
* Variable computers for GUI displays
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "CoreExperiment.gaml"

experiment AnimalsAbstract parent: CoreExperiment virtual: true {
	
	output synchronized: false {
		display animalChart type: java2D virtual: true refresh: current_date.day = 1 and updateTimeOfDay {
			chart "Animals in the simulated area" type: series {
				data "Mobile herds (TLU/ha cropland)" value: (mobileHerd sum_of each.herdSize) color: #blue;// / ((grazableLandscape count (each.cellLU = "Cropland")) / hectareToCell) color: #blue;
				data "Fattened animals (TLU/fattening household)" value: (fattenedAnimal sum_of each.groupSize) color: #orange;// / nbFatteningHh color: #orange;
			}
		}
		
		display digestionChart type: java2D virtual: true refresh: current_date.day = 1 and updateTimeOfDay {
			chart "Intake and excretion flows" type: series {
				float nbFattened <- fattenedAnimal sum_of each.groupSize;
				data "Mobile herds intake (kgDM/TLU_MH)" value: herdsIntakeFlow / mobileHerd sum_of each.herdSize color: #forestgreen;
				data "Mobile herds excretions (kgDM VSE/TLU_MH)" value: herdsExcretionsFlow / mobileHerd sum_of each.herdSize color: #darkslategrey;
				data "Fattened animals intake (kgDM/TLU_FA)" value: nbFattened = 0 ? 0 : (fattenedIntakeFlow / nbFattened) color: #lightsalmon;
				data "Fattened animals excretions (kgDM VSE/TLU_FA)" value: nbFattened = 0 ? 0 : (fattenedExcretionsFlow / nbFattened) color: #darkgoldenrod;
				data "Complements inflows (kgDM/TLU_FA)" value: nbFattened = 0 ? 0 : (complementsInflow / nbFattened) color: #gamablue;
			}
		}
	}
}

experiment StatesAbstract parent: CoreExperiment virtual: true {
	
	point chartWindow;
	
	int nbSleepGoers;
	int nbSleepers;
	int nbSpotChangers;
	int nbGrazers;
	int nbResters;
	int totalSleepGoers;
	int totalSleepers;
	int totalSpotChangers;
	int totalGrazers;
	int totalResters;
	reflex {
		chartWindow <- {cycle - 96, cycle};
		
		nbSleepGoers <- mobileHerd count (each.state = "isGoingToSleepSpot");
		nbSleepers <- mobileHerd count (each.state = "isSleepingInPaddock");
		nbSpotChangers <- mobileHerd count (each.state = "isChangingSite");
		nbGrazers <- mobileHerd count (each.state = "isGrazing");
		nbResters <- mobileHerd count (each.state = "isResting");
		totalSleepGoers <- totalSleepGoers + nbSleepGoers;
		totalSleepers <- totalSleepers + nbSleepers;
		totalSpotChangers <- totalSpotChangers + nbSpotChangers;
		totalGrazers <- totalGrazers + nbGrazers;
		totalResters <- totalResters + nbResters;
	}
	
	output synchronized: false {
		display stateMeter type: java2D virtual: true refresh: every(#week) {
			chart "Repartition of herds between states - overall simulation" type: pie {
				data "isGoingToSleepSpot" value: totalSleepGoers color: #blue;
				data "isSleepingInPaddock" value: totalSleepers color: #darkblue;
				data "isChangingSite" value: totalSpotChangers color: #red;
				data "isGrazing" value: totalGrazers color: #green;
				data "isResting" value: totalResters color: #yellow;
			}
		}
		
		display stateFollower type: java2D virtual: true {
			chart "Repartition of herds between states - real time" type: series x_range: chartWindow {
				data "isGoingToSleepSpot" value: nbSleepGoers color: #blue;
				data "isSleepingInPaddock" value: nbSleepers color: #darkblue;
				data "isChangingSite" value: nbSpotChangers color: #red;
				data "isGrazing" value: nbGrazers color: #green;
				data "isResting" value: nbResters color: #yellow;
			}
		}
	}
}
