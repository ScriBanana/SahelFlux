/**
* In: SahelFlux
* Name: Landscape
* Landscape grid
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Landscape

import "../../../Utilities/ImportZoning.gaml"
import "Parcel.gaml"
import "SOCstock.gaml"
import "SoilNProcesses.gaml"
import "../GlobalProcesses.gaml"

global {
	
	//// Global landscape parameters
	
	float maxCropBiomassContentHa <- 351.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; weeds and crop residues
	float maxRangelandBiomassContentHa <- 375.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; grass and shrubs
	float maxCropBiomassContent <- maxCropBiomassContentHa * hectareToCell;
	float maxRangelandBiomassContent <- maxRangelandBiomassContentHa * hectareToCell;
	
	int minimumRainfallYieldInflexion <- 317; // mm
	int maximumRainfallYieldInflexion <- 805; // mm
	int minimumNAvailableNRFInflexion <- 18; // kgN/ha
	int maximumNAvailableNRFInflexion <- 83; // kgN/ha
	
	
	//// Global landscape functions
	
	action initGrazableCells {
		ask landscape where (each.cellLU = "Cropland" or each.cellLU = "Rangeland") {
			crossableByHerds <- true;
			biomassProducer <- true;
			
			biomassContent <- cellLU = "Cropland" ? gauss(maxCropBiomassContent, maxCropBiomassContent * 0.1) : gauss(maxRangelandBiomassContent, maxRangelandBiomassContent * 0.1);
			
			create SOCstock with: [myCell::self] {
				myself.mySOCstock <- self;
				location <- myself.location;
				
				labileCPool <- myself.cellLU = "Cropland" ?
					gauss(croplandSOCInit * labileCPoolProportionInit, croplandSOCInit * labileCPoolProportionInit * 0.1) : 
					gauss(rangelandSOCInit * labileCPoolProportionInit, rangelandSOCInit * labileCPoolProportionInit * 0.1)
				; // TODO DUMMY
				stableCPool <- myself.cellLU = "Cropland" ?
					gauss(croplandSOCInit * stableCPoolProportionInit, croplandSOCInit * stableCPoolProportionInit * 0.1) : 
					gauss(rangelandSOCInit * stableCPoolProportionInit, rangelandSOCInit * stableCPoolProportionInit * 0.1)
				; // TODO DUMMY
				totalSOC <- labileCPool + stableCPool;
			}
			create soilNProcesses with: [myCell::self] {
				myself.mySoilNProcesses <- self;
				location <- myself.location;
			}
			
			do updateColour;
		}	
	}
	
	// Aggregation of biomass content for herds to identify cells to move to and graze
	float meanBiomassContent;
	float biomassContentSD;
	action updateGlobalBiomassMeanAndSD {
		list<float> allCellsBiomass;
		ask landscape where each.biomassProducer {
			allCellsBiomass <+ self.biomassContent;
		}
		meanBiomassContent <- mean(allCellsBiomass);
		biomassContentSD <- standard_deviation(allCellsBiomass);
	}
	
}

grid landscape width: gridWidth height: gridHeight parallel: true neighbors: 8 schedules: [] use_regular_agents: false {
	
	//// Parameters
	
	// Land unit
	string cellLU;
	bool biomassProducer <- false;
	bool crossableByHerds <- false;
	int nbTrees <- int(floor(abs(gauss(3,2)))); // TODO DUMMY
	// Part of a parcel
	parcel myParcel;
	// Internal N and C stock and processes
	SOCstock mySOCstock;
	soilNProcesses mySoilNProcesses;
	
	// Grazable biomass
	float biomassContent min: 0.0 max: max(maxCropBiomassContent, maxRangelandBiomassContent); // TODO hmmmmm
	float yearlyBiomassToBeProduced;
	
	//// Functions
	
	action growBiomass {
		// To be called regularly during the rainy season
		
	}
	
	action computeYearlyBiomassProduction {
		// Computes plant biomass production at the start of the rainy season
		
		string emittingPool <- cellLU = "Rangeland" ? "Rangelands" : (myParcel != nil and myParcel.homeField ? "HomeFields" : "BushFields");
		string receivingPool;
		
		float thisYearNAvailable;
		ask mySoilNProcesses {
			thisYearNAvailable <- computeNAvailable();
		}
		
		float waterLimitedYieldHa;
		float nitrogenReductionFactor;
		
		if cellLU = "Rangeland" {
			receivingPool <- "TF-ToSpontVeget";
			
			switch yearRainfall {
				match_between [-#infinity, minimumRainfallYieldInflexion - 1] {
					waterLimitedYieldHa <- 0.0;
				} match_between [minimumRainfallYieldInflexion, maximumRainfallYieldInflexion] {
					waterLimitedYieldHa <- 1000 * (0.4322 * ln (yearRainfall) - 1.195);
				} match_between [maximumRainfallYieldInflexion + 1, #infinity] {
					waterLimitedYieldHa <- 3775.0;
				}
			}
			
			switch thisYearNAvailable {
				match_between [-#infinity, minimumNAvailableNRFInflexion - 1] {
					nitrogenReductionFactor <- 0.25;
				} match_between [minimumNAvailableNRFInflexion, maximumNAvailableNRFInflexion] {
					nitrogenReductionFactor <- 0.414 * ln (thisYearNAvailable / hectareToCell) - 0.7012;
				} match_between [maximumNAvailableNRFInflexion + 1, #infinity] {
					nitrogenReductionFactor <- 1.0;
				}
			}
			
		} else if myParcel != nil {
			switch myParcel.currentYearCover {
				
				match "Millet" {
					receivingPool <- "TF-ToMillet";
					switch yearRainfall {
						match_between [-#infinity, minimumRainfallYieldInflexion - 1] {
							waterLimitedYieldHa <- 0.0;
						} match_between [minimumRainfallYieldInflexion, maximumRainfallYieldInflexion] {
							waterLimitedYieldHa <- 950 * (1.8608 * ln (yearRainfall) - 8.6756);
						} match_between [maximumRainfallYieldInflexion + 1, #infinity] {
							waterLimitedYieldHa <- 3775.0;
						}
					}
					
					switch thisYearNAvailable {
						match_between [-#infinity, minimumNAvailableNRFInflexion - 1] {
							nitrogenReductionFactor <- 0.25;
						} match_between [minimumNAvailableNRFInflexion, maximumNAvailableNRFInflexion] {
							nitrogenReductionFactor <- 0.501 * ln (thisYearNAvailable / hectareToCell) - 1.2179;
						} match_between [maximumNAvailableNRFInflexion + 1, #infinity] {
							nitrogenReductionFactor <- 1.0;
						}
					}
					
				} match "Groundnut" {
					receivingPool <- "TF-ToGroundnut";
					waterLimitedYieldHa <- 450.0 + 150 * yearMeteoQuality; // TODO confirmer
					nitrogenReductionFactor <- 1.0; // TODO Faute de mieux?
					
				} match "Fallow" {
					receivingPool <- "TF-ToFallowVeget";
					// Same as rangeland veg
					switch yearRainfall {
						match_between [-#infinity, minimumRainfallYieldInflexion - 1] {
							waterLimitedYieldHa <- 0.0;
						} match_between [minimumRainfallYieldInflexion, maximumRainfallYieldInflexion] {
							waterLimitedYieldHa <- 1000 * (0.4322 * ln (yearRainfall) - 1.195);
						} match_between [maximumRainfallYieldInflexion + 1, #infinity] {
							waterLimitedYieldHa <- 3775.0;
						}
					}
					
					switch thisYearNAvailable {
						match_between [-#infinity, minimumNAvailableNRFInflexion - 1] {
							nitrogenReductionFactor <- 0.25;
						} match_between [minimumNAvailableNRFInflexion, maximumNAvailableNRFInflexion] {
							nitrogenReductionFactor <- 0.414 * ln (thisYearNAvailable / hectareToCell) - 0.7012;
						} match_between [maximumNAvailableNRFInflexion + 1, #infinity] {
							nitrogenReductionFactor <- 1.0;
						}
					}
					
				}
			}
		} else {
			receivingPool <- "TF-ToWeeds"; // TODO Gros bullshit
		}
		
		// Registering N flows
		ask world {	do saveFlowInMap("N", emittingPool, receivingPool , thisYearNAvailable);} // Assumes all N available is consumed.
		
		// TODO Add photoshynthesis
		
		// Producing biomass
		yearlyBiomassToBeProduced <- waterLimitedYieldHa * hectareToCell * nitrogenReductionFactor;
		assert yearlyBiomassToBeProduced >= 0;
	}
	
	// Colouring
	action updateColour {
		if cellLU = "Cropland" { // Ternary possible, but if statement more secure and readable
			color <- rgb(255 + (216 - 255) / maxCropBiomassContent * biomassContent, 255 + (232 - 255) / maxCropBiomassContent * biomassContent, 180);
		} else if cellLU = "Rangeland" {
			color <-
			rgb(200 + (101 - 200) / maxRangelandBiomassContent * biomassContent, 230 + (198 - 230) / maxRangelandBiomassContent * biomassContent, 180 + (110 - 180) / maxRangelandBiomassContent * biomassContent);
		}
	}

}

