/**
* In: SahelFlux
* Name: Landscape
* Landscape grid
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Landscape

import "../../Main.gaml"
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
	
	// C and N contents of crops TODO unify
	float milletEarNContent <- 0.5; // TODO DUMMY
	float milletEarCContent <- 0.5; // TODO DUMMY
	float milletStrawNContent <- 0.5; // TODO DUMMY
	float milletStrawCContent <- 0.5; // TODO DUMMY
	float groundnutPlantNContent <- 0.5; // TODO DUMMY
	float groundnutPlantCContent <- 0.5; // TODO DUMMY
	float fallowVegNContent <- 0.5; // TODO DUMMY
	float fallowVegCContent <- 0.5; // TODO DUMMY
	
	// Variables
	list<landscape> grazableLandscape;
	list<landscape> targetableCellsForChangingSite;
	
	//// Global landscape functions
	
	action initGrazableCells {
		ask landscape where (each.cellLU = "Cropland" or each.cellLU = "Rangeland") {
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
		grazableLandscape <- landscape where (each.cellLU = "Cropland" or each.cellLU = "Rangeland");
		targetableCellsForChangingSite <- landscape where (each.cellLU = "Rangeland");
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
	SOCstock mySOCstock;
	soilNProcesses mySoilNProcesses;
	
	// Grazable biomass
	float biomassContent min: 0.0; // kgDM
	float thisYearNAvailable;
	string thisYearReceivingPool;
	float yearlyBiomassToBeProduced;
	float yearlyWeedsBiomassToBeProduced;
	
	//// Functions
	
	action growBiomass { // To be called regularly during the rainy season
	
		// Grow biomass
		biomassContent <- biomassContent + (yearlyBiomassToBeProduced + yearlyWeedsBiomassToBeProduced) / nbBiophUpdatesDuringRainySeason;
		
		// Registering N flows
		float NFlowsToSaveEachCall <- thisYearNAvailable / nbBiophUpdatesDuringRainySeason;
		string emittingPool <- cellLU = "Rangeland" ? "Rangelands" : (myParcel != nil and myParcel.homeField ? "HomeFields" : "BushFields");
		ask world {	do saveFlowInMap("N", emittingPool, myself.thisYearReceivingPool , NFlowsToSaveEachCall);} // Assumes all N available is consumed.
		
		// TODO Add photoshynthesis
	}
	
	action computeYearlyBiomassProduction {
		// Computes plant biomass production at the start of the rainy season
		
		ask mySoilNProcesses {
			myself.thisYearNAvailable <- computeNAvailable();
		}
		
		float waterLimitedYieldHa;
		float nitrogenReductionFactor;
		
		if cellLU = "Rangeland" {
			thisYearReceivingPool <- "TF-ToSpontVeget";
			waterLimitedYieldHa <- max(0.0, min(1498.0, 1000 * (0.4322 * ln (yearRainfall) - 1.195)));
			nitrogenReductionFactor <- max(0.25, min(1.0, 0.414 * ln (thisYearNAvailable / hectareToCell) - 0.7012));
			
		} else if myParcel != nil {
			switch myParcel.currentYearCover {
				
				match "Millet" {
					thisYearReceivingPool <- "TF-ToMillet";
					waterLimitedYieldHa <- max(0.0, min(3775.0, 950 * (1.8608 * ln (yearRainfall) - 8.6756)));
					nitrogenReductionFactor <- max(0.25, min(1.0, 0.501 * ln (thisYearNAvailable / hectareToCell) - 1.2179));
				
				} match "Groundnut" {
					thisYearReceivingPool <- "TF-ToGroundnut";
					waterLimitedYieldHa <- 450.0 + 150 * yearMeteoQuality; // TODO confirmer
					nitrogenReductionFactor <- 1.0; // TODO Faute de mieux?
					
				} match "Fallow" {
					thisYearReceivingPool <- "TF-ToFallowVeget";
					// Same as rangeland veg
					waterLimitedYieldHa <- max(0.0, min(1498.0, 1000 * (0.4322 * ln (yearRainfall) - 1.195)));
					nitrogenReductionFactor <- max(0.25, min(1.0, 0.414 * ln (thisYearNAvailable / hectareToCell) - 0.7012));
				
				}
			}
		} else {
			thisYearReceivingPool <- "TF-ToWeeds"; // TODO Gros bullshit
		}
		
		// Producing biomass
		yearlyBiomassToBeProduced <- waterLimitedYieldHa * hectareToCell * nitrogenReductionFactor;
		assert yearlyBiomassToBeProduced >= 0;
		yearlyWeedsBiomassToBeProduced <- cellLU = "Rangeland" ? weedProdRangeland : weedProdCropland; // kgDM/cell
		
	}
	
	action getHarvested {
		float exportedCropsBiomass; // kgDM
		float exportedStrawBiomass; // kgDM
		float exportedCropsNFlow; // kgN
		float exportedCropsCFlow; // kgC
		float exportedStrawNFlow; // kgN
		float exportedStrawCFlow; // kgC
		string emittingPool;
		
		switch myParcel.currentYearCover {
			match "Millet" {
				emittingPool <- "Millet";
				exportedCropsBiomass <- milletExportedAgriProductRatio * self.biomassContent;
				exportedStrawBiomass <- milletExportedStrawRatio * exportedCropsBiomass;
				
				exportedCropsNFlow <- exportedCropsBiomass * milletEarNContent; // kgN
				exportedCropsCFlow <- exportedCropsBiomass * milletEarCContent; // kgC
				exportedStrawNFlow <- exportedStrawBiomass * milletStrawNContent; // kgN
				exportedStrawCFlow <- exportedStrawBiomass * milletStrawCContent; // kgC
			}
			match "Groundnut" {
				emittingPool <- "Groundnut";
				exportedCropsBiomass <- groundnutExportedBiomassRatio * self.biomassContent;
				
				exportedCropsNFlow <- exportedCropsBiomass * groundnutPlantNContent; // kgN
				exportedCropsCFlow <- exportedCropsBiomass * groundnutPlantCContent; // kgC
			}
			match "Fallow" {
				emittingPool <- "FallowVeg";
				exportedStrawBiomass <- fallowExportedBiomass * self.biomassContent;
				
				exportedStrawNFlow <- exportedStrawBiomass * fallowVegNContent; // kgN
				exportedStrawCFlow <- exportedStrawBiomass * fallowVegCContent; // kgC
			}
		}
		
		self.biomassContent <- self.biomassContent - exportedCropsBiomass - exportedStrawBiomass;
		
		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToHomeFields", exportedCropsNFlow);}
		ask world {	do saveFlowInMap("C", emittingPool, "TF-ToHomeFields", exportedCropsCFlow);}
		ask world {	do saveFlowInMap("N", emittingPool, "TF-ToStrawPiles", exportedStrawNFlow);}
		ask world {	do saveFlowInMap("C", emittingPool, "TF-ToStrawPiles", exportedStrawCFlow);}
	}
	
	// Colouring
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
	}

}

