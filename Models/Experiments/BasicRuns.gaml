/**
* In: SahelFlux
* Name: BasicRuns
* Simplest experiments
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model BasicRuns

import "../Main.gaml"

experiment Run type: gui {
	// Parameters - Tests in UnitTests.gaml
	parameter "Start date" category: "Scenario - Time" var: starting_date;
	parameter "End date" category: "Scenario - Time" var: endDate min: starting_date;
	
	parameter "Landscape layout" category: "Scenario - Spatial layout" var: gridLayout;
	parameter "Enable fallow (3-years rotation)" category: "Scenario - Spatial layout" var: fallowEnabled <- false;
	parameter "Maximum numbre of parcels to place" category: "Scenario - Spatial layout" var: maxNbCroplandParcels min: 0;
	parameter "Parcels radius (m) : Mean :: SD" category: "Scenario - Spatial layout" var: parcelRadiusDistri;
	parameter "Home fields area radius (m)" category: "Scenario - Spatial layout" var: homeFieldsRadius min: 0.0;
	
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold <- 10 min: 0 updates: [nbTranshumantHh, nbFatteningHh];
	parameter "Number transhuming households" category: "Scenario - Population structure" var: nbTranshumantHh <- 10 min: 0 max: nbHousehold;
	parameter "Number fattening households" category: "Scenario - Population structure" var: nbFatteningHh <- 10 min: 0 max: nbHousehold;
	
	parameter "Mobile herds mean sizes (TLU)" category: "Scenario - Production means repartition" var: meanHerdSize min: 0.0;
	parameter "Mean number of fattened animals per season" category: "Scenario - Production means repartition" var: meanFattenedGroupSize min: 0.0;
	parameter "Bush fields parcels per household" category: "Scenario - Production means repartition" var: nbBushFieldsPerHh min: 0;
	parameter "Home fields parcels per household" category: "Scenario - Production means repartition" var: nbHomeFieldsPerHh min: 0;
	
	parameter "Number of night per paddock cell" category: "Scenario - Herds management" var: maxNbNightsPerCellInPaddock min: 0;
	
	parameter "Yearly meteorological quality (groundnut) and rainfall (millet and spontaneous vegetation) variarion means" category: "Scenario - ExternalFactors" var: meteoUpdateType;
	
	parameter "Digestion length (h)" category: "Calibration" var: digestionLengthParamAsInt <- 20 min: 0;
	parameter "Initial soil carbon stock in croplands (kgC/ha)" category: "Calibration" var: croplandSOChaInit min: 0.0;
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

experiment FastAutoRun autorun: true {
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold <- 60 min: 0;
	parameter "Short run start date" var: starting_date <- date([2020, 4, 10, eveningTime + 1, 0, 0]);
	parameter "Short run end date" var: endDate <- date([2020, 6, 1, eveningTime + 1, 0, 0]);
}

experiment FallowtoRun parent: Run autorun: true {
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold <- 20 min: 0;
	parameter "Number transhuming households" category: "Scenario - Population structure" var: nbTranshumantHh <- 10 min: 0 max: nbHousehold;
	parameter "Short run start date" var: starting_date <- date([2020, 6, 10, eveningTime + 1, 0, 0]);
	parameter "Short run end date" var: endDate <- date([2020, 12, 30, eveningTime + 1, 0, 0]);
	parameter "Parcels borders as" category: "Display options" var: parcelsAspect <- "Cover" among: ["Owner", "Cover"];
	parameter "Enable fallow (3-years rotation)" category: "Scenario - Spatial layout" var: fallowEnabled <- true;
}

experiment SOCDispRun parent: Run {
	output {
		display carbonDisplay type: java2D refresh: current_date.day = 1 and updateTimeOfDay {
			grid landscape;
			species SOCstock;
		}
		
		display SOCCompartiments refresh:  current_date.day = 1 and updateTimeOfDay {
			chart "Average SOC per compartment (kgC/ha)" type: series {
				data "Labile C cropland" value: (SOCstock where (each.myCell.cellLU = "Cropland") mean_of each.labileCPool) / hectareToCell color: #darkkhaki;
				data "Stable C cropland" value: (SOCstock where (each.myCell.cellLU = "Cropland")  mean_of each.stableCPool) / hectareToCell color: #olive;
				data "Labile C rangeland" value: (SOCstock where (each.myCell.cellLU = "Rangeland")  mean_of each.labileCPool) / hectareToCell color: #green;
				data "Stable C rangeland" value: (SOCstock where (each.myCell.cellLU = "Rangeland")  mean_of each.stableCPool) / hectareToCell color: #darkgreen;
				data "Total C cropland" value: (SOCstock where (each.myCell.cellLU = "Cropland")  mean_of each.totalSOC) / hectareToCell color: #grey;
				data "Total C rangeland" value: (SOCstock where (each.myCell.cellLU = "Rangeland")  mean_of each.totalSOC) / hectareToCell color: #black;
			}
		}
	}
}

