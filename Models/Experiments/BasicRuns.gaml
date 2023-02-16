/**
* In: SahelFlux
* Name: BasicRuns
* Simplest experiments
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model BasicRuns

import "../Main.gaml"

global {
	
	//// Global parameters
	
	bool secondaryDisplayRefresh <- false update: false;
}

experiment Run type: gui {
	// Parameters - Tests in UnitTests.gaml
	parameter "Start date" category: "Scenario - Time" var: starting_date;
	parameter "End date" category: "Scenario - Time" var: endDate min: starting_date;
	
	parameter "Landscape layout" category: "Scenario - Spatial layout" var: gridLayout;
	parameter "Enable fallow (3-years rotation)" category: "Scenario - Spatial layout" var: fallowEnabled <- false;
	parameter "Maximum numbre of parcels to place" category: "Scenario - Spatial layout" var: maxNbCroplandParcels min: 0;
	parameter "Parcels radius (m) : Mean :: SD" category: "Scenario - Spatial layout" var: parcelRadiusDistri;
	parameter "Home fields area radius (m)" category: "Scenario - Spatial layout" var: homeFieldsRadius min: 0.0;
	
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold <- 10 min: 0;
	parameter "Mobile herds mean sizes (TLU)" category: "Scenario - Production means repartition" var: meanHerdSize min: 0.0;
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

experiment FastAutoRun parent: Run autorun: true {
	parameter "Short run end date" var: endDate <- date([2020, 12, 2, eveningTime + 1, 0, 0]);
}

experiment SOCDispRun parent: Run {
	output {
		display carbonDisplay type: java2D refresh: secondaryDisplayRefresh {
			grid landscape;
			species SOCstock;
		}
		
		display SOCCompartiments refresh: secondaryDisplayRefresh {
			chart "Average SOC per compartment (kgC/ha)" type: series {
				data "Labile C cropland" value: (SOCstock where (each.myCell.cellLU = "Cropland") mean_of each.labileCPool) / hectareToCell color: #darkkhaki;
				data "Stable C cropland" value: (SOCstock where (each.myCell.cellLU = "Cropland")  mean_of each.stableCPool) / hectareToCell color: #olive;
				data "Labile C rangeland" value: (SOCstock where (each.myCell.cellLU = "Rangeland")  mean_of each.labileCPool) / hectareToCell color: #green;
				data "Stable C rangeland" value: (SOCstock where (each.myCell.cellLU = "Rangeland")  mean_of each.stableCPool) / hectareToCell color: #darkgreen;
			}
		}
	}
}

