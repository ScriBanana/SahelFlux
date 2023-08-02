/**
* In: SahelFlux
* Name: Landscape
* Landscape grid
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Landscape

import "../../Main.gaml"
import "../../../Utilities/CnNFlowsParameters.gaml"
import "Parcel.gaml"
import "SOCStock.gaml"
import "SoilNProcesses.gaml"
import "../GlobalProcesses.gaml"

global {
	
	//// Global landscape parameters
	
	// Trees initialisation
	int nbTreesInitHomefields <- 6 const: true; // Grillot, 2018
	int nbTreesInitBushfields <- 10 const: true; // Grillot, 2018
	int nbTreesInitRangeland <- 15 const: true; // Grillot, 2018
	
	// Yield model parameters
	float milletMaxYw <- 3775.0 const: true; // Grillot, 2018
	float spontVegMaxYw <- 1498.0 const: true; // Grillot, 2018
	float groundnutBaseYield <- 450.0 const: true; // Grillot, 2018
	// See the rest in the code. Purely copied off Grillot anyway.
	
	// Roots production
	float milletRootProportion <- 0.11 const: true; // From Manlay 2000 tab 3.1 p.103
	float groundnutRootProportion <- 0.62 const: true; // From Manlay 2000 tab 3.1 p.103
	float spontVegRootProportion <- 0.57 const: true; // From Manlay 2000 tab 1.3 p.47
	float weedsRootProportion <- 0.57 const: true; // From Manlay 2000 tab 1.3 p.47
	
	// Harvest parameters
	float milletExportedAgriProductRatio <- 0.3 const: true; // Grillot et al, 2018
	float milletExportedStrawRatio <- 0.38 const: true; // Ratio of produced straw that gets exported. Grillot et al, 2018
	float groundnutExportedBiomassRatio <- 1.0 const: true;
	float fallowExportedBiomass <- 0.55 const: true; // Surveys
	
	// Cell biomass parameters
	float maxCroplandBiomass <-
		milletMaxYw * (1 - milletRootProportion) * (1 - milletExportedAgriProductRatio) * (1 - milletExportedStrawRatio)
	const: true;
	float maxRangelandBiomass <- spontVegMaxYw * (1 - spontVegRootProportion) const: true;
	float cropBiomassContentInitHa <-
		0.7 * 950 * (1.8608 * ln (meanRainfall) - 8.6756) *
		(1 - milletRootProportion) * (1 - milletExportedAgriProductRatio) * (1 - milletExportedStrawRatio)
	const: true; // See Biomass production model; NRF = 0.7
	float rangelandBiomassContentInitHa <-
		0.7 * 1000 * (0.4322 * ln (meanRainfall) - 1.195) * (1 - spontVegRootProportion) 
	const: true; // See Biomass production model; NRF = 0.7
	float cropBiomassContentInit <- cropBiomassContentInitHa * hectareToCell const: true;
	float rangelandBiomassContentInit <- rangelandBiomassContentInitHa * hectareToCell const: true;
	
	// Cells categories
	list<landscape> nonEmptyLandscape;
	list<landscape> grazableLandscape;
	list<landscape> targetableCellsForChangingSite;
	
	//// Global landscape functions
	
	action initGrid {
		write "Initialising landscape grid.";
		ask nonEmptyLandscape {
			 
			// Check LUList in GenerateSpatialInput for cellLUId
			if !(cellLUId in [1, 2, 3, 7, 9, 11]) {
				cellLU <- "NonGrazable";
			} else {
				grazableLandscape <+ self;
				
				if cellLUId in [2, 3, 9] {
					cellLU <- "Cropland";
					biomassContent <- gauss(cropBiomassContentInit, cropBiomassContentInit * 0.1);
					nbTrees <- nbTreesInitBushfields;
				} else {
					cellLU <- "Rangeland";
					targetableCellsForChangingSite <+ self;
					biomassContent <- gauss(rangelandBiomassContentInit, rangelandBiomassContentInit * 0.1);
					nbTrees <- nbTreesInitRangeland;
				}
				if enabledGUI {
					do updateColour;
				}
				
				// Create companion SOCStock and soilNProcesses agents
				create SOCStock with: [myCell::self, location::self.location] {
					myself.mySOCstock <- self;
				}
				create soilNProcesses with: [myCell::self, location::self.location] {
					myself.mySoilNProcesses <- self;
				}
			}
		}
		
		write "	Done. " + length(grazableLandscape where (each.cellLU = "Cropland")) + " ha cropland, "
			+ length(grazableLandscape where (each.cellLU = "Rangeland")) + " ha rangeland.";
	}
	
	// Aggregation of biomass content for herds to identify cells to move to and graze and household to decide to leave for transhumance
	float sumBiomassContent;
	float meanBiomassContent;
	float biomassContentSD;
	action updateGlobalBiomassMeanAndSD {
		list<float> allCellsBiomass;
		ask grazableLandscape {
			allCellsBiomass <+ self.biomassContent;
		}
		sumBiomassContent <- sum(allCellsBiomass);
		meanBiomassContent <- mean(allCellsBiomass);
		biomassContentSD <- standard_deviation(allCellsBiomass);
	}
	
	// Updates mobile herds changing site potential targets
	action updateTargetableCellsForChangingSiteInDS {
		targetableCellsForChangingSite <- grazableLandscape where (
			(each.biomassContent >= meanBiomassContent + biomassContentSD)
		);
		if empty(targetableCellsForChangingSite) {
			targetableCellsForChangingSite <- grazableLandscape where (
				(each.biomassContent >= meanBiomassContent)
			);
		}
		if enableDebug {
			if empty(targetableCellsForChangingSite) {
				write drySeason;
			}
			assert !empty(targetableCellsForChangingSite);
		}
	}
	
}

grid landscape 
	file: gridData parallel: true neighbors: 8
	optimizer: "JPS" schedules: [] use_regular_agents: false
{
	
	//// Parameters
	
	// Land unit
	int cellLUId;
	string cellLU;
	
	int nbTrees;
	
	// Part of a parcel
	int parcelID;
	parcel myParcel;
	bool homefieldCell;
	
	// Internal N and C stock and processes
	SOCStock mySOCstock;
	soilNProcesses mySoilNProcesses;
	
	// Grazable biomass
	float biomassContent min: 0.0; // kgDM aerial biomass (total in RS, crop residues in DS)
	float thisYearNAvailable;
	float thisYearBiomassCContent;
	string thisYearNFlowReceivingPool;
	string thisYearCFlowReceivingPool;
	float yearlyBiomassToBeProduced;
	float yearlyWeedsBiomassToBeProduced <- 0.0; // As of now, no weed in the simulation
	float weedProportionInBiomass <- 0.0; // As of now, no weed in the simulation
	
	//// Functions
	
	action computeYearlyBiomassProduction {
		// Computes plant biomass production at the start of the rainy season
		
		ask mySoilNProcesses {
			myself.thisYearNAvailable <- computeNAvailable();
		}
		
		float waterLimitedYieldHa;
		float nitrogenReductionFactor;
		float rootProportion;
		
		if cellLU = "Rangeland" {
			thisYearNFlowReceivingPool <- "TF-ToSpontVeg";
			thisYearCFlowReceivingPool <- "SpontVeg";
			thisYearBiomassCContent <- rangelandVegCContent;
			waterLimitedYieldHa <- max(0.0, min(spontVegMaxYw, 1000 * (0.4322 * ln (yearRainfall) - 1.195)));
			nitrogenReductionFactor <- max(0.25, min(1.0, 0.414 * ln (thisYearNAvailable / hectareToCell) - 0.7012));
			rootProportion <- spontVegRootProportion;
			
		} else if myParcel != nil {
			switch myParcel.nextRSCover {
				
				match "Millet" {
					thisYearNFlowReceivingPool <- "TF-ToMillet";
					thisYearCFlowReceivingPool <- "Millet";
					thisYearBiomassCContent <- wholeMilletCContent;
					waterLimitedYieldHa <- max(0.0, min(milletMaxYw, 950 * (1.8608 * ln (yearRainfall) - 8.6756)));
					nitrogenReductionFactor <- max(0.25, min(1.0, 0.501 * ln (thisYearNAvailable / hectareToCell) - 1.2179));
					rootProportion <- milletRootProportion;
				
				} match "Groundnut" {
					thisYearNFlowReceivingPool <- "TF-ToGroundnut";
					thisYearCFlowReceivingPool <- "Groundnut";
					thisYearBiomassCContent <- groundnutAerialPartCContent;
					waterLimitedYieldHa <- groundnutBaseYield + (groundnutBaseYield / 3) * yearMeteoQuality; // TODO confirmer
					nitrogenReductionFactor <- 1.0; // TODO Faute de mieux?
					rootProportion <- groundnutRootProportion;
					
				} match "Fallow" {
					thisYearNFlowReceivingPool <- "TF-ToFallowVeg";
					thisYearCFlowReceivingPool <- "FallowVeg";
					// Same as rangeland veg
					thisYearBiomassCContent <- fallowVegCContent;
					waterLimitedYieldHa <- max(0.0, min(spontVegMaxYw, 1000 * (0.4322 * ln (yearRainfall) - 1.195)));
					nitrogenReductionFactor <- max(0.25, min(1.0, 0.414 * ln (thisYearNAvailable / hectareToCell) - 0.7012));
					rootProportion <- spontVegRootProportion;
				
				}
			}
		} else {
			// TODO Manque un truc ici, du coup
			
			// All 0 as out of crop rotation; Weeds out now
			thisYearNFlowReceivingPool <- "TF-ToWeeds";
			thisYearCFlowReceivingPool <- "Weeds";
			thisYearBiomassCContent <- weedsCContent;
			rootProportion <- weedsRootProportion;
		}
		
		// Producing biomass
		yearlyBiomassToBeProduced <- waterLimitedYieldHa * hectareToCell * nitrogenReductionFactor;
		
		// Adding roots
		yearlyBiomassToBeProduced <- yearlyBiomassToBeProduced * (1 + rootProportion);
		
		assert yearlyBiomassToBeProduced >= 0;
//		yearlyWeedsBiomassToBeProduced <- cellLU = "Rangeland" ? weedProdRangeland : weedProdCropland; // kgDM/cell
//		weedProportionInBiomass <- yearlyWeedsBiomassToBeProduced / (yearlyBiomassToBeProduced + yearlyWeedsBiomassToBeProduced);
		
	}
	
	action growBiomass { // To be called nbBiophUpdatesDuringRainySeason times during the rainy season
	
		// Grow biomass
		biomassContent <- biomassContent + (yearlyBiomassToBeProduced + yearlyWeedsBiomassToBeProduced) / nbBiophUpdatesInRainySeason;
		
		// Registering N (uptake from soil) and C (photosynthesis) flows
		// Note : groundnut N2 fixation runs through SoilNProcess
		float NFlowsToSaveEachCall <- (1 - weedProportionInBiomass) * thisYearNAvailable / nbBiophUpdatesInRainySeason;
		if thisYearNFlowReceivingPool = "TF-ToWeeds" { // Weeds out
			NFlowsToSaveEachCall <- 0.0;
		}
		float cropCFlowsToSaveEachCall <- yearlyBiomassToBeProduced * thisYearBiomassCContent / nbBiophUpdatesInRainySeason;
		string emittingPool <- cellLU = "Rangeland" ? "Rangelands" : (homefieldCell ? "HomeFields" : "BushFields");
		ask world {	do saveFlowInMap("N", emittingPool, myself.thisYearNFlowReceivingPool, NFlowsToSaveEachCall);} // Assumes all N available is consumed.
		ask world {	do saveFlowInMap("C", myself.thisYearCFlowReceivingPool, "IF-FromAtmo", cropCFlowsToSaveEachCall);}
		
//		float weedsNFlowToSaveEachCall <- weedProportionInBiomass * thisYearNAvailable / nbBiophUpdatesDuringRainySeason;
//		float weedsCFlowToSaveEachCall <- yearlyWeedsBiomassToBeProduced * weedsCContent / nbBiophUpdatesDuringRainySeason;
//		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToWeeds", weedsNFlowToSaveEachCall);}
//		ask world {	do saveFlowInMap("C", "Weeds",  "IF-FromAtmo", weedsCFlowToSaveEachCall);}
		
		// TODO du coup, N flows ne dépend pas de la pousse effective, alors que C oui...
		
		if enabledGUI {
			do updateColour;
		}
	}
	
	action getHarvestedAndBurrowRoots {
		
		string emittingPool;
		string soilFlowReciever <- cellLU = "Rangeland" ?
			"TF-ToRangelands" :
			(homefieldCell ? "TF-ToHomeFields" : "TF-ToBushFields")
		;
		
		float incorporatedRootProportion;
		float incorporatedRootNContent; // kgN
		float incorporatedRootCContent; // kgC
		
		float exportedCropsProportion;
		float exportedCropsNContent; // kgN
		float exportedCropsCContent; // kgC
		
		float exportedStrawProportion;
		float residuesAndStrawNContent; // kgN
		float residuesAndStrawCContent; // kgC
		
		// Affect harvest ratios according to vegetation type
		if myParcel = nil {
			if cellLU = "Rangeland" {
				emittingPool <- "SpontVeg";
				
				incorporatedRootProportion <- spontVegRootProportion;
				incorporatedRootNContent <- fallowRootPartNContent; // kgN
				incorporatedRootCContent <- fallowRootPartCContent; // kgC
				
				exportedCropsProportion <- 0.0;
				exportedCropsNContent <- rangelandVegNContent; // kgN
				exportedCropsCContent <- rangelandVegCContent; // kgC
				
				exportedStrawProportion <- 0.0;
				residuesAndStrawNContent <- rangelandVegNContent; // kgN
				residuesAndStrawCContent <- rangelandVegCContent; // kgC
				
			} else {
				emittingPool <- "Weeds";
				
				incorporatedRootProportion <- weedsRootProportion;
//				incorporatedRootNContent <- weedsRootPartNContent; // kgN
//				incorporatedRootCContent <- weedsRootPartCContent; // kgC
				
				exportedCropsProportion <- 0.0;
//				exportedCropsNContent <- weedsNContent; // kgN
//				exportedCropsCContent <- weedsCContent; // kgC
				
				exportedStrawProportion <- 0.0;
//				residuesAndStrawNContent <- weedsNContent; // kgN
//				residuesAndStrawCContent <- weedsCContent; // kgC
				
			}
		} else {
			switch myParcel.nextRSCover {
				match "Millet" {
					emittingPool <- "Millet";
					
					incorporatedRootProportion <- milletRootProportion;
					incorporatedRootNContent <- milletRootPartNContent; // kgN
					incorporatedRootCContent <- milletRootPartCContent; // kgC
					
					exportedCropsProportion <- milletExportedAgriProductRatio;
					exportedCropsNContent <- milletEarNContent; // kgN
					exportedCropsCContent <- milletEarCContent; // kgC
					
					exportedStrawProportion <- milletExportedStrawRatio;
					residuesAndStrawNContent <- milletStrawNContent; // kgN
					residuesAndStrawCContent <- milletStrawCContent; // kgC
				}
				match "Groundnut" {
					emittingPool <- "Groundnut";
					
					incorporatedRootProportion <- groundnutRootProportion;
					incorporatedRootNContent <- groundnutRootPartNContent; // kgN
					incorporatedRootCContent <- groundnutRootPartCContent; // kgC
					
					exportedCropsProportion <- groundnutExportedBiomassRatio;
					exportedCropsNContent <- groundnutAerialPartNContent; // kgN
					exportedCropsCContent <- groundnutAerialPartCContent; // kgC
					
					exportedStrawProportion <- 0.0;
					residuesAndStrawNContent <- groundnutAerialPartNContent; // kgN
					residuesAndStrawCContent <- groundnutAerialPartCContent; // kgC
					
				}
				match "Fallow" {
					emittingPool <- "FallowVeg";
					
					incorporatedRootProportion <- spontVegRootProportion;
					incorporatedRootNContent <- fallowRootPartNContent; // kgN
					incorporatedRootCContent <- fallowRootPartCContent; // kgC
					
					exportedCropsProportion <- fallowExportedBiomass;
					exportedCropsNContent <- fallowVegNContent; // kgN
					exportedCropsCContent <- fallowVegCContent; // kgC
					
					exportedStrawProportion <- 0.0;
					residuesAndStrawNContent <- fallowVegNContent; // kgN
					residuesAndStrawCContent <- fallowVegCContent; // kgC
					
				}
			}
		}
		
		// Incorporate roots to soils and SOC model
		float incorporatedRoot <- biomassContent * incorporatedRootProportion; // kgDM
		ask world {	do saveFlowInMap("N", emittingPool, soilFlowReciever, incorporatedRoot * incorporatedRootNContent);}
		ask world {	do saveFlowInMap("C", emittingPool, soilFlowReciever, incorporatedRoot * incorporatedRootCContent);}
		mySOCstock.carbonInputsList <+ [emittingPool, 0.0, incorporatedRoot * incorporatedRootCContent];
		float aerialBiomass <- (biomassContent - incorporatedRoot) * (1 - weedProportionInBiomass);
		
		// Export crop products
		float exportedCropsBiomass <- exportedCropsProportion * aerialBiomass; // kgDM
		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToHouseholds", exportedCropsBiomass * exportedCropsNContent);}
		ask world {	do saveFlowInMap("C", emittingPool, "TF-ToHouseholds", exportedCropsBiomass * exportedCropsCContent);}
		float strawBiomass <- aerialBiomass - exportedCropsBiomass; // kgDM
		
		// Export millet straw
		float exportedStrawBiomass <- strawBiomass * exportedStrawProportion; // kgDM
		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToStrawPiles", exportedStrawBiomass * residuesAndStrawNContent);}
		ask world {	do saveFlowInMap("C", emittingPool, "TF-ToStrawPiles", exportedStrawBiomass * residuesAndStrawCContent);}
		if myParcel != nil and myParcel.myOwner != nil {
			myParcel.myOwner.myForagePileBiomassContent <-
				myParcel.myOwner.myForagePileBiomassContent + exportedStrawBiomass
			;
		}
		
		// Transfer residues to cell
		float remainingResiduesBiomass <- aerialBiomass - exportedCropsBiomass - exportedStrawBiomass;
		ask world {	do saveFlowInMap("N", emittingPool, soilFlowReciever, remainingResiduesBiomass * residuesAndStrawNContent);}
		ask world {	do saveFlowInMap("C", emittingPool, soilFlowReciever, remainingResiduesBiomass * residuesAndStrawCContent);}
		biomassContent <- remainingResiduesBiomass;
		
		if enabledGUI {
			do updateColour;
		}
	}
	
	action burnAndIncorporateResidualBiomass {
		if (self.cellLU = "Cropland" and self.myParcel != nil) {
			switch myParcel.lastRSCover {
				match "Millet" {
					string emittingPool <- myParcel.homeField ? "HomeFields" : "BushFields";
					ask world {	do saveFlowInMap("C", emittingPool, "OF-GHG",
						CO2FromBurning * coefCO2ToC + COFromBurning * coefCOToC + CH4FromBurning * coefCH4ToC // TODO CO as GHG?
					);}
					ask world {	do saveFlowInMap("N", emittingPool, "OF-GHG", N2OFromBurning * coefN2OToN);}
					ask world {	do saveFlowInMap("N", emittingPool, "OF-AtmoLosses", NOxFromBurning * coefNOxToN);}
					ask world {	do saveGHGFlow(emittingPool, "CO2", CO2FromBurning);}
					ask world {	do saveGHGFlow(emittingPool, "CH4", CH4FromBurning);}
					ask world {	do saveGHGFlow(emittingPool, "N2O", N2OFromBurning);}
					
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
		
		if enabledGUI {
			do updateColour;
		}
	}
	
	// Colouring (Resource heavy; only call when running GUI experiments, by enabling enabledGUI bool)
	action updateColour {
		if cellLU = "Cropland" { // Ternary possible, but if statement more secure and readable
			color <- rgb(
				255 + (216 - 255) / (maxCroplandBiomass * hectareToCell) * biomassContent,
				255 + (232 - 255) / (maxCroplandBiomass * hectareToCell) * biomassContent,
				180
			);
		} else if cellLU = "Rangeland" {
			color <- rgb(
				200 + (101 - 200) / (maxRangelandBiomass * hectareToCell) * biomassContent,
				230 + (198 - 230) / (maxRangelandBiomass * hectareToCell) * biomassContent,
				180 + (110 - 180) / (maxRangelandBiomass * hectareToCell) * biomassContent
			);
		}
		
//		if self in targetableCellsForChangingSite {
//			color <- #red;
//		}
		
	}

}

