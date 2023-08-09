/**
* In: SahelFlux
* Name: GUIVariables
* Variable computers for GUI displays
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "CoreExperiment.gaml"

experiment AnimalsAbstract parent: CoreExperiment virtual: true {
	
	float meanTLU <- 1.0;
	list<float> TLUList;
	
	reflex when: updateTimeOfDay {
	
		TLUList <+ float(mobileHerd sum_of each.herdSize);
		
		if current_date != (starting_date add_hours 1) and current_date.day = 1 {
			meanTLU <- mean(TLUList);
			write TLUList;
			write meanTLU;
			write herdsIntakeFlow;
			write herdsExcretionsFlow;
			TLUList <- [];
			herdsIntakeFlow <- 0.0;
			herdsExcretionsFlow <- 0.0;
		}
	}
	
	output synchronized: false {
		display animalDisplay type: java2D virtual: true refresh: current_date != (starting_date add_hours 1) and current_date.day = 1 and updateTimeOfDay {
			chart "Animals in the simulated area" type: series {
				data "Mobile herds (TLU)" value: meanTLU color: #blue;
				data "Fattened animals (TLU)" value: fattenedAnimal sum_of each.groupSize color: #orange;
			}
		}
		
		display digestionDisplay type: java2D virtual: true refresh: current_date != (starting_date add_hours 1) and current_date.day = 1 and updateTimeOfDay {
			chart "Intake and excretion flows" type: series {
				data "Mobile herds intake (kgDM/TLU)" value: herdsIntakeFlow / meanTLU color: #greenyellow;
				data "Mobile herds excretions (kgDM VSE/TLU)" value: herdsExcretionsFlow / meanTLU color: #darkgoldenrod;
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
