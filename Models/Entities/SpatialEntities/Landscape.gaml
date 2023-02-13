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

global {
	
	//// Global landscape parameters
	
	float maxCropBiomassContentHa <- 351.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; weeds and crop residues
	float maxRangelandBiomassContentHa <- 375.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; grass and shrubs
	float maxCropBiomassContent <- maxCropBiomassContentHa * hectareToCell;
	float maxRangelandBiomassContent <- maxRangelandBiomassContentHa * hectareToCell;
	
	
	//// Global landscape functions
	
	action initGrazableCells {
		ask landscape where (each.cellLU = "Cropland" or each.cellLU = "Rangeland") {
			grazable <- true;
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
		}
	}
	
	// Aggregation of biomass content for herds to identify cells to move to and graze
	float meanBiomassContent;
	float biomassContentSD;
	action updateGlobalBiomassMeanAndSD {
		list<float> allCellsBiomass;
		ask landscape where (each.grazable) {
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
	bool grazable <- false;
	int nbTrees <- int(floor(abs(gauss(3,2)))); // TODO DUMMY
	// Part of a parcel
	parcel myParcel;
	// Internal N and C stock and processes
	SOCstock mySOCstock;
	soilNProcesses mySoilNProcesses;
	
	// Grazable biomass
	float biomassContent min: 0.0 max: max(maxCropBiomassContent, maxRangelandBiomassContent); // TODO hmmmmm
	
	//// Functions
	
	action biomassProduction {
		// Computes plant biomass production at the end of the rain season
		float thisYearNAvailable;
		ask mySoilNProcesses {
			thisYearNAvailable <- computeNAvailable();
		}
		
		// Save flow in matrix
		string emittingPool <- cellLU = "Rangeland" ? "Rangelands" : (myParcel != nil and myParcel.homeField ? "HomeFields" : "BushFields");
		string receivingPool;
		if cellLU = "Rangeland" {
			receivingPool <- "TF-ToSpontVeget";
		} else if myParcel != nil {
			switch myParcel.currentYearCover {
				match "Millet" {
					receivingPool <- "TF-ToMillet";
				}
				match "Groundnut" {
					receivingPool <- "TF-ToGroundnut";
				}
				match "Fallow" {
					receivingPool <- "TF-ToFallowVeget";
				}
			}
		} else {
			receivingPool <- "TF-ToWeeds"; // TODO Gros bullshit
		}
		ask world {	do saveFlowInMap("N", emittingPool, receivingPool , thisYearNAvailable);} // TODO Assumes all N available is consumed...
		
		// Add photoshynthesis
	}
	
	action drySeasonStartUpdateGrazBiomassContent {
		// Updates biomass content in cells at the start of the dry season
		// TODO ajouter la weed en addition
		if cellLU = "Cropland" {
			//TODO
			biomassContent <- gauss(maxCropBiomassContent, maxCropBiomassContent * 0.1);
		} else if cellLU = "Rangeland" {
			//TODO
			biomassContent <- gauss(maxRangelandBiomassContent, maxRangelandBiomassContent * 0.1);
		}
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
