/**
* In: SahelFlux
* Name: CoreExperiment
* Abstract base experiments to be called by ran experiments
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "../Main.gaml"

experiment CoreExperiment virtual: true {
	
	output synchronized: false {
		display SpatialMainDisplay type: java2D virtual: true {
			grid landscape;
			species parcel;
			species mobileHerd;
		}
		
		display SpatialCarbonDisplay type: java2D virtual: true refresh: current_date.day = 1 and updateTimeOfDay {
			grid landscape;
			species SOCStock;
		}
		
		display SOCChart type: java2D virtual: true refresh: current_date.day = 1 and updateTimeOfDay {
			chart "Average SOC per compartment (kgC/ha)" type: series {
				data "Labile C homefields" value: (SOCStock where (each.myCell.homefieldCell) mean_of each.labileCPool) / hectareToCell color: #sienna;
				data "Stable C homefields" value: (SOCStock where (each.myCell.homefieldCell)  mean_of each.stableCPool) / hectareToCell color: #brown;
				data "Labile C bushfields" value: (SOCStock where (each.myCell.cellLU = "Cropland" and !each.myCell.homefieldCell) mean_of each.labileCPool) / hectareToCell color: #darkkhaki;
				data "Stable C bushfields" value: (SOCStock where (each.myCell.cellLU = "Cropland" and !each.myCell.homefieldCell)  mean_of each.stableCPool) / hectareToCell color: #olive;
				data "Labile C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.labileCPool) / hectareToCell color: #green;
				data "Stable C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.stableCPool) / hectareToCell color: #darkgreen;
				data "Total C cropland" value: (SOCStock where (each.myCell.cellLU = "Cropland")  mean_of each.totalSOC) / hectareToCell color: #grey;
				data "Total C rangeland" value: (SOCStock where (each.myCell.cellLU = "Rangeland")  mean_of each.totalSOC) / hectareToCell color: #black;
			}
		}
		
		display biomassChart type: java2D virtual: true refresh: current_date.day = 1 and updateTimeOfDay {
			chart "Average grazable biomass per compartment (kgDM/ha)" type: series {
				data "Biomass homefields" value: (grazableLandscape where (each.homefieldCell) mean_of each.biomassContent) / hectareToCell color: #brown;
				data "Biomass bushfields" value: (grazableLandscape where (each.cellLU = "Cropland" and !each.homefieldCell) mean_of each.biomassContent) / hectareToCell color: #olive;
				data "Biomass rangeland" value: (grazableLandscape where (each.cellLU = "Rangeland")  mean_of each.biomassContent) / hectareToCell color: #green;
			}
		}
		
	}
}

experiment CoreWithParameters parent: CoreExperiment virtual: true {
	
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
	
}