/**
* In: SahelFlux
* Name: GUIRuns
* Experiments with GUI on
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model GUIRuns

import "../Main.gaml"

global {
	init {
		parallelHerds <- true;
		enableDebug <- true;
		enabledGUI <- true;
	}
}

experiment Run type: gui parent: ParamGatherer {
	
	init { experimentType <- "GUIRun";}
	
	// Parameters - Tests in UnitTests.gaml
	parameter "Start date" category: "Scenario - Time" var: starting_date;
	parameter "End date" category: "Scenario - Time" var: endDate min: starting_date;
	
	parameter "Landscape layout" category: "Scenario - Spatial layout" var: villageName;
	parameter "Enable fallow (3-years rotation)" category: "Scenario - Spatial layout" var: fallowEnabled <- false;
	
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold min: 0;
	parameter "Number transhuming households" category: "Scenario - Population structure" var: propTranshumantHh min: 0.0 max: 1.0;
	parameter "Number fattening households" category: "Scenario - Population structure" var: propFatteningHh min: 0.0 max: 1.0;
	
	parameter "Mobile herds mean sizes (TLU)" category: "Scenario - Production means repartition" var: meanHerdSize min: 0.0;
	parameter "Mean number of fattened animals per season" category: "Scenario - Production means repartition" var: meanFattenedGroupSize min: 0.0;
	parameter "Proportion of Home fields among each household parcels" category: "Scenario - Production means repartition" var: homeFieldsProportion min: 0.0;
	
	parameter "Number of night per paddock cell" category: "Scenario - Herds management" var: maxNbNightsPerCellInPaddock min: 0;
	
	parameter "Yearly meteorological quality (groundnut) and rainfall (millet and spontaneous vegetation) variarion means" category: "Scenario - ExternalFactors" var: meteoUpdateType;
	
	parameter "Digestion length (h)" category: "Calibration" var: digestionLengthParamAsInt min: 0;
	parameter "Initial soil carbon stock in homefields (kgC/ha)" category: "Calibration" var: homefieldsSOChaInit min: 0.0;
	parameter "Initial soil carbon stock in bushfields (kgC/ha)" category: "Calibration" var: bushfieldsSOChaInit min: 0.0;
	parameter "Initial soil carbon stock in rangelands (kgC/ha)" category: "Calibration" var: rangelandSOChaInit min: 0.0;
	
	parameter "Parcels borders as" category: "Display options" var: parcelsAspect <- "Owner" among: ["Owner", "Cover"];
	
	output {
		display mainDisplay type: java2D {
			grid landscape;
			species parcel;
			species mobileHerd;
		}
	}
}

experiment FallowtoRun parent: Run autorun: true {
	
	init { experimentType <- "FallowtoRun";}
	
	// Auto run for the fallow period only
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold <- 20 min: 0;
	parameter "Number transhuming households" category: "Scenario - Population structure" var: propTranshumantHh <- 0.5 min: 0.0 max: 1.0;
	parameter "Short run start date" var: starting_date <- date([2020, 6, 10, eveningTime + 1, 0, 0]);
	parameter "Short run end date" var: endDate <- date([2020, 12, 30, eveningTime + 1, 0, 0]);
	parameter "Parcels borders as" category: "Display options" var: parcelsAspect <- "Cover" among: ["Owner", "Cover"];
	parameter "Enable fallow (3-years rotation)" category: "Scenario - Spatial layout" var: fallowEnabled <- true;
}

experiment SOCDispRun parent: Run {
	
	init { experimentType <- "SOCDispRun";}
	
	output {
		display carbonDisplay type: java2D refresh: current_date.day = 1 and updateTimeOfDay {
			grid landscape;
			species SOCStock;
		}
		
		display SOCCompartiments type: java2D refresh:  current_date.day = 1 and updateTimeOfDay {
			chart "Average SOC per compartment (kgC/ha)" type: series {
				data "Labile C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland") mean_of each.labileCPool) / hectareToCell color: #darkkhaki;
				data "Stable C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland")  mean_of each.stableCPool) / hectareToCell color: #olive;
				data "Labile C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.labileCPool) / hectareToCell color: #green;
				data "Stable C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.stableCPool) / hectareToCell color: #darkgreen;
				data "Total C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland")  mean_of each.totalSOC) / hectareToCell color: #grey;
				data "Total C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.totalSOC) / hectareToCell color: #black;
			}
		}
	}
}

experiment BMDispRun parent: Run {
	
	init { experimentType <- "BMDispRun";}
	
	output {
		display biomassDisplay type: java2D refresh:  current_date.day = 1 and updateTimeOfDay {
			chart "Average grazable biomass per compartment (kgDM/ha)" type: series {
				data "Biomass cropland" value: (grazableLandscape where (each.cellLU = "Cropland") mean_of each.biomassContent) / hectareToCell color: #olive;
				data "Biomass rangeland" value: (grazableLandscape where (each.cellLU = "Rangeland")  mean_of each.biomassContent) / hectareToCell color: #green;
				data "Mean available biomass" value: meanBiomassContent / hectareToCell color: #brown;
				data "Available standard deviation" value: biomassContentSD / hectareToCell color: #sienna;
			}
		}
		
		display animalDisplay type: java2D refresh:  current_date.day = 1 and updateTimeOfDay {
			chart "Animals in the simulated area" type: series {
				data "Mobile herds (TLU)" value: mobileHerd sum_of each.herdSize color: #blue;
				data "Fattened animals (TLU)" value: fattenedAnimal sum_of each.groupSize color: #orange;
			}
		}
	}
}

experiment StateObserver parent: Run {
	
	init { experimentType <- "stateObserver";}
	
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
		
		chartWindow <- {cycle - 96, cycle};
	}
	
	output {
		display stateMeter type: java2D refresh: current_date.day = 1 and updateTimeOfDay {
			chart "State meter" type: pie {
				data "isGoingToSleepSpot" value: totalSleepGoers color: #blue;
				data "isSleepingInPaddock" value: totalSleepers color: #darkblue;
				data "isChangingSite" value: totalSpotChangers color: #red;
				data "isGrazing" value: totalGrazers color: #green;
				data "isResting" value: totalResters color: #yellow;
			}
		}
		display stateFollower type: java2D {
			chart "State follower" type: series x_range: chartWindow {
				data "isGoingToSleepSpot" value: nbSleepGoers color: #blue;
				data "isSleepingInPaddock" value: nbSleepers color: #darkblue;
				data "isChangingSite" value: nbSpotChangers color: #red;
				data "isGrazing" value: nbGrazers color: #green;
				data "isResting" value: nbResters color: #yellow;
			}
		}
	}
}

experiment Dashboard parent: BMDispRun {
	
	init { experimentType <- "Dashboard";}
	
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
	
	output {
		layout vertical([0::2500, 1::2500, 2::2500, horizontal([3::5000,4::5000])::2500]);
		
		display biomassDisplay type: java2D refresh:  current_date.day = 1 and updateTimeOfDay {
			chart "Average grazable biomass per compartment (kgDM/ha)" type: series {
				data "Biomass cropland" value: (grazableLandscape where (each.cellLU = "Cropland") mean_of each.biomassContent) / hectareToCell color: #olive;
				data "Biomass rangeland" value: (grazableLandscape where (each.cellLU = "Rangeland")  mean_of each.biomassContent) / hectareToCell color: #green;
			}
		}
		
		display SOCCompartiments type: java2D refresh:  current_date.day = 1 and updateTimeOfDay {
			chart "Average SOC per compartment (kgC/ha)" type: series {
				data "Labile C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland") mean_of each.labileCPool) / hectareToCell color: #darkkhaki;
				data "Stable C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland")  mean_of each.stableCPool) / hectareToCell color: #olive;
				data "Labile C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.labileCPool) / hectareToCell color: #green;
				data "Stable C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.stableCPool) / hectareToCell color: #darkgreen;
				data "Total C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland")  mean_of each.totalSOC) / hectareToCell color: #grey;
				data "Total C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.totalSOC) / hectareToCell color: #black;
			}
		}
		
		display animalDisplay type: java2D refresh:  current_date.day = 1 and updateTimeOfDay {
			chart "Animals in the simulated area" type: series {
				data "Mobile herds (TLU)" value: mobileHerd sum_of each.herdSize color: #blue;
				data "Fattened animals (TLU)" value: fattenedAnimal sum_of each.groupSize color: #orange;
			}
		}
		
		display carbonDisplay type: java2D refresh: current_date.day = 1 and updateTimeOfDay {
			grid landscape;
			species SOCStock;
		}
		
		display stateMeter type: java2D refresh: current_date.day = 1 and updateTimeOfDay {
			chart "State meter" type: pie {
				data "isGoingToSleepSpot" value: totalSleepGoers color: #blue;
				data "isSleepingInPaddock" value: totalSleepers color: #darkblue;
				data "isChangingSite" value: totalSpotChangers color: #red;
				data "isGrazing" value: totalGrazers color: #green;
				data "isResting" value: totalResters color: #yellow;
			}
		}
		
		
	}
}

