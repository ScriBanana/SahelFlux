/**
* In: SahelFlux
* Name: Landscape
* Landscape grid
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Landscape

import "../../Main.gaml"
import "../../../Utilities/ImportZoning.gaml"
import "../../../Utilities/CnNFlowsParameters.gaml"
import "Parcel.gaml"
import "SOCStock.gaml"
import "SoilNProcesses.gaml"
import "../GlobalProcesses.gaml"

global {
	
	//// Global landscape parameters
	
	float maxCropBiomassContentHa <- 351.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; weeds and crop residues
	float maxRangelandBiomassContentHa <- 375.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; grass and shrubs
	float maxCropBiomassContent <- maxCropBiomassContentHa * hectareToCell;
	float maxRangelandBiomassContent <- maxRangelandBiomassContentHa * hectareToCell;
	
	// Weeds biomass production parameters
	float weedProdRangelandHa <- 475.0; // kgDM/ha Grillot 2018
	float weedProdCroplandHa <- 100.0; // kgDM/ha Grillot 2018
	float weedProdRangeland <- weedProdRangelandHa * hectareToCell;
	float weedProdCropland <- weedProdCroplandHa * hectareToCell;
	
	// Harvest parameters
	float milletExportedAgriProductRatio <- 0.3; // Grillot et al, 2018
	float milletExportedStrawRatio <- 0.38; // Ratio of produced straw that gets exported. Grillot et al, 2018
	float groundnutExportedBiomassRatio <- 1.0;
	float fallowExportedBiomass <- 0.55; // Surveys
		
	// Variables
	list<landscape> grazableLandscape;
	list<landscape> targetableCellsForChangingSite;
	
	//// Global landscape functions
	
	action initGrazableCells {
		ask landscape where (each.cellLU = "Cropland" or each.cellLU = "Rangeland") {
			biomassProducer <- true;
			grazableLandscape <+ self;
			
			biomassContent <- cellLU = "Cropland" ?
				gauss(maxCropBiomassContent, maxCropBiomassContent * 0.1) :
				gauss(maxRangelandBiomassContent, maxRangelandBiomassContent * 0.1)
			;
			
			create SOCStock with: [myCell::self] {
				myself.mySOCstock <- self;
				location <- myself.location;
				
				labileCPool <- myself.cellLU = "Cropland" ?
					gauss(croplandSOCInit * labileCPoolProportionInit, croplandSOCInit * labileCPoolProportionInit * 0.1) : 
					gauss(rangelandSOCInit * labileCPoolProportionInit, rangelandSOCInit * labileCPoolProportionInit * 0.1); // TODO DUMMY
				stableCPool <- myself.cellLU = "Cropland" ?
					gauss(croplandSOCInit * stableCPoolProportionInit, croplandSOCInit * stableCPoolProportionInit * 0.1) : 
					gauss(rangelandSOCInit * stableCPoolProportionInit, rangelandSOCInit * stableCPoolProportionInit * 0.1); // TODO DUMMY
				totalSOC <- labileCPool + stableCPool;
			}
			create soilNProcesses with: [myCell::self] {
				myself.mySoilNProcesses <- self;
				location <- myself.location;
			}
			if enabledGUI {
				do updateColour;
			}
		}
		targetableCellsForChangingSite <- grazableLandscape where (each.cellLU = "Rangeland");
	}
	
	// Aggregation of biomass content for herds to identify cells to move to and graze and household to decide to leave for transhumance
	float sumBiomassContent;
	float meanBiomassContent;
	float biomassContentSD;
	action updateGlobalBiomassMeanAndSD {
		list<float> allCellsBiomass;
		ask landscape where each.biomassProducer {
			allCellsBiomass <+ self.biomassContent;
		}
		sumBiomassContent <- sum(allCellsBiomass);
		meanBiomassContent <- mean(allCellsBiomass);
		biomassContentSD <- standard_deviation(allCellsBiomass);
	}
	
	// Updates mobile herds changing site potential targets
	action updateTargetableCellsForChangingSiteInDS {
//		write "Updating available targets";
		targetableCellsForChangingSite <- grazableLandscape where (
			(each.biomassContent > meanBiomassContent + biomassContentSD)
		);
	}
	
}

grid landscape width: gridWidth height: gridHeight parallel: true neighbors: 8 optimizer: "JPS" schedules: [] use_regular_agents: false {
	
	//// Parameters
	
	// Land unit
	string cellLU;
	bool biomassProducer <- false;
	int nbTrees <- int(floor(abs(gauss(3,2)))); // TODO DUMMY
	// Part of a parcel
	parcel myParcel;
	// Internal N and C stock and processes
	SOCStock mySOCstock;
	soilNProcesses mySoilNProcesses;
	
	// Grazable biomass
	float biomassContent min: 0.0; // kgDM
	float thisYearNAvailable;
	float thisYearBiomassCContent;
	string thisYearNFlowReceivingPool;
	string thisYearCFlowReceivingPool;
	float yearlyBiomassToBeProduced;
	float yearlyWeedsBiomassToBeProduced;
	float weedProportionInBiomass <- 0.0; // As of now, no weed in the simulation
	
	//// Functions
	
	action growBiomass { // To be called regularly during the rainy season
	
		// Grow biomass
		biomassContent <- biomassContent + (yearlyBiomassToBeProduced + yearlyWeedsBiomassToBeProduced) / nbBiophUpdatesDuringRainySeason;
		
		// Registering N and C flows
		float NFlowsToSaveEachCall <- (1 - weedProportionInBiomass) * thisYearNAvailable / nbBiophUpdatesDuringRainySeason;
		float weedsNFlowToSaveEachCall <- weedProportionInBiomass * thisYearNAvailable / nbBiophUpdatesDuringRainySeason;
		float cropCFlowsToSaveEachCall <- yearlyBiomassToBeProduced * thisYearBiomassCContent / nbBiophUpdatesDuringRainySeason;
		float weedsCFlowToSaveEachCall <- yearlyWeedsBiomassToBeProduced * weedsCContent / nbBiophUpdatesDuringRainySeason;
		string emittingPool <- cellLU = "Rangeland" ? "Rangelands" : (myParcel != nil and myParcel.homeField ? "HomeFields" : "BushFields");
		ask world {	do saveFlowInMap("N", emittingPool, myself.thisYearNFlowReceivingPool, NFlowsToSaveEachCall);} // Assumes all N available is consumed.
		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToWeeds", weedsNFlowToSaveEachCall);}
		ask world {	do saveFlowInMap("C", myself.thisYearCFlowReceivingPool, "IF-FromAtmo", cropCFlowsToSaveEachCall);}
		ask world {	do saveFlowInMap("C", "Weeds",  "IF-FromAtmo", weedsCFlowToSaveEachCall);}
		
		// TODO du coup, N flows ne dépend pas de la pousse effective, alors que C oui...
	}
	
	action computeYearlyBiomassProduction {
		// Computes plant biomass production at the start of the rainy season
		
		ask mySoilNProcesses {
			myself.thisYearNAvailable <- computeNAvailable();
		}
		
		float waterLimitedYieldHa;
		float nitrogenReductionFactor;
		
		if cellLU = "Rangeland" {
			thisYearNFlowReceivingPool <- "TF-ToSpontVeget";
			thisYearCFlowReceivingPool <- "SpontVeg";
			thisYearBiomassCContent <- rangelandVegCContent;
			waterLimitedYieldHa <- max(0.0, min(1498.0, 1000 * (0.4322 * ln (yearRainfall) - 1.195)));
			nitrogenReductionFactor <- max(0.25, min(1.0, 0.414 * ln (thisYearNAvailable / hectareToCell) - 0.7012));
			
		} else if myParcel != nil {
			switch myParcel.nextRSCover {
				
				match "Millet" {
					thisYearNFlowReceivingPool <- "TF-ToMillet";
					thisYearCFlowReceivingPool <- "Millet";
					thisYearBiomassCContent <- wholeMilletCContent;
					waterLimitedYieldHa <- max(0.0, min(3775.0, 950 * (1.8608 * ln (yearRainfall) - 8.6756)));
					nitrogenReductionFactor <- max(0.25, min(1.0, 0.501 * ln (thisYearNAvailable / hectareToCell) - 1.2179));
				
				} match "Groundnut" {
					thisYearNFlowReceivingPool <- "TF-ToGroundnut";
					thisYearCFlowReceivingPool <- "Groundnut";
					thisYearBiomassCContent <- groundnutAerialPartCContent;
					waterLimitedYieldHa <- 450.0 + 150 * yearMeteoQuality; // TODO confirmer
					nitrogenReductionFactor <- 1.0; // TODO Faute de mieux?
					
				} match "Fallow" {
					thisYearNFlowReceivingPool <- "TF-ToFallowVeget";
					thisYearCFlowReceivingPool <- "FallowVeg";
					// Same as rangeland veg
					thisYearBiomassCContent <- fallowVegCContent;
					waterLimitedYieldHa <- max(0.0, min(1498.0, 1000 * (0.4322 * ln (yearRainfall) - 1.195)));
					nitrogenReductionFactor <- max(0.25, min(1.0, 0.414 * ln (thisYearNAvailable / hectareToCell) - 0.7012));
				
				}
			}
		} else {
			// TODO Manque un truc ici, du coup
			
			// TODO Gros bullshit
			// Tout à 0 car hors rotation
			thisYearNFlowReceivingPool <- "TF-ToWeeds";
			thisYearCFlowReceivingPool <- "Weeds";
			thisYearBiomassCContent <- fallowVegCContent;
		}
		
		// Producing biomass
		yearlyBiomassToBeProduced <- waterLimitedYieldHa * hectareToCell * nitrogenReductionFactor;
		assert yearlyBiomassToBeProduced >= 0;
		yearlyWeedsBiomassToBeProduced <- cellLU = "Rangeland" ? weedProdRangeland : weedProdCropland; // kgDM/cell
		weedProportionInBiomass <- yearlyWeedsBiomassToBeProduced / (yearlyBiomassToBeProduced + yearlyWeedsBiomassToBeProduced);
		
	}
	
	action getHarvested {
		float exportedCropsBiomass; // kgDM
		float exportedStrawBiomass; // kgDM
		float exportedCropsNFlow; // kgN
		float exportedCropsCFlow; // kgC
		float exportedStrawNFlow; // kgN
		float exportedStrawCFlow; // kgC
		string emittingPool;
		
		// Compute exported flows
		switch myParcel.nextRSCover {
			match "Millet" {
				emittingPool <- "Millet";
				exportedCropsBiomass <- milletExportedAgriProductRatio * (1 - weedProportionInBiomass) * self.biomassContent;
				exportedStrawBiomass <- milletExportedStrawRatio * (self.biomassContent - exportedCropsBiomass);
				
				exportedCropsNFlow <- exportedCropsBiomass * milletEarNContent; // kgN
				exportedCropsCFlow <- exportedCropsBiomass * milletEarCContent; // kgC
				exportedStrawNFlow <- exportedStrawBiomass * milletStrawNContent; // kgN
				exportedStrawCFlow <- exportedStrawBiomass * milletStrawCContent; // kgC
			}
			match "Groundnut" {
				emittingPool <- "Groundnut";
				exportedCropsBiomass <- groundnutExportedBiomassRatio * (1 - weedProportionInBiomass) * self.biomassContent;
				
				exportedCropsNFlow <- exportedCropsBiomass * groundnutAerialPartNContent; // kgN
				exportedCropsCFlow <- exportedCropsBiomass * groundnutAerialPartCContent; // kgC
			}
			match "Fallow" {
				emittingPool <- "FallowVeg";
				exportedStrawBiomass <- fallowExportedBiomass * (1 - weedProportionInBiomass) * self.biomassContent;
				
				exportedStrawNFlow <- exportedStrawBiomass * fallowVegNContent; // kgN
				exportedStrawCFlow <- exportedStrawBiomass * fallowVegCContent; // kgC
			}
		}
		
		// Remove harvested biomass from self
		self.biomassContent <- self.biomassContent - exportedCropsBiomass - exportedStrawBiomass;
		
		// Credit straw pile with harvested straw
		if myParcel.myOwner != nil {
			myParcel.myOwner.myForagePileBiomassContent <- myParcel.myOwner.myForagePileBiomassContent + exportedStrawBiomass;
		}
		
		// Save flows
		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToHouseholds", exportedCropsNFlow);}
		ask world {	do saveFlowInMap("C", emittingPool, "TF-ToHouseholds", exportedCropsCFlow);}
		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToStrawPiles", exportedStrawNFlow);}
		ask world {	do saveFlowInMap("C", emittingPool, "TF-ToStrawPiles", exportedStrawCFlow);}
	}
	
	action burnAndIncorporateBiomass {
		if (self.cellLU = "Cropland" and self.myParcel != nil) {
			switch myParcel.lastRSCover {
				match "Millet" {
					string emittingPool <- myParcel.homeField ? "HomeFields" : "BushFields";
					ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG",
						CO2FromBurning * coefCO2ToC + COFromBurning * coefCOToC + CH4FromBurning * coefCH4ToC
					);}
					ask world {	do saveFlowInMap("N", emittingPool, "OF-GHG", N2OFromBurning * coefN2OToN);}
					ask world {	do saveFlowInMap("N", emittingPool, "OF-AtmoLosses", NOxFromBurning * coefNOxToN);}
					
					biomassContent <- 0.0;
				}
				match "Groundnut" {
					mySOCstock.carbonInputsList <+ ["Groundnut", 0.0, biomassContent * groundnutAerialPartCContent];
					biomassContent <- 0.0;
				}
				match "Fallow" {
					mySOCstock.carbonInputsList <+ ["Fallow", 0.0, biomassContent * fallowVegCContent];
					biomassContent <- 0.0;
				}
			}
		} else { // Rangelands + interstitial vegetation
			mySOCstock.carbonInputsList <+ ["Rangeland", 0.0, biomassContent * forageDSCContent];
			biomassContent <- 0.0;
		}
	}
	
	// Colouring (Resource heavy; only call when running GUI experiments, by enabling enabledGUI bool)
	action updateColour {
		if cellLU = "Cropland" { // Ternary possible, but if statement more secure and readable
			color <- rgb(
				255 + (216 - 255) / maxCropBiomassContent * biomassContent,
				255 + (232 - 255) / maxCropBiomassContent * biomassContent,
				180
			);
		} else if cellLU = "Rangeland" {
			color <- rgb(
				200 + (101 - 200) / maxRangelandBiomassContent * biomassContent,
				230 + (198 - 230) / maxRangelandBiomassContent * biomassContent,
				180 + (110 - 180) / maxRangelandBiomassContent * biomassContent
			);
		}
		
//		if self in targetableCellsForChangingSite {
//			color <- #red;
//		}
		
	}

}

