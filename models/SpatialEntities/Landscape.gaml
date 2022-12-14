/**
* In: SahelFlux
* Name: Landscape
* Based on the internal empty template. 
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Landscape

import "../Main.gaml"
import "../InitProcesses/ImportZoning.gaml"
import "Parcel.gaml"
import "SOCstock.gaml"
import "SNstock.gaml"

global {
	
	// landscape parameters
	float maxCropBiomassContentHa <- 351.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; weeds and crop residues
	float maxRangelandBiomassContentHa <- 375.0; // kgDM/ha Achard & Banoin (2003) - palatable BM; grass and shrubs
	float maxCropBiomassContent <- maxCropBiomassContentHa * hectareToCell;
	float maxRangelandBiomassContent <- maxRangelandBiomassContentHa * hectareToCell;
	
}

grid landscape width: gridWidth height: gridHeight parallel: true neighbors: 8 {
	
	// Land use
	string cellLU;
	// Part of a parcel
	parcel myParcel;
	// Internal N and C stock and processes
	SOCstock mySOCstock;
	SNstock mySNstock;
	
	// Grazable biomass
	float biomassContent min: 0.0; // max: max(maxCropBiomassContent, maxRangelandBiomassContent);
	
	action biomassProduction {
		// Computes plant biomass production at the end of the rain season
		
	}
	
	action drySeasonStartUpdateGrazBiomassContent {
		// Updates biomass content in cells at the start of the dry season
			if cellLU = "Cropland" {
				//TODO
				biomassContent <- maxCropBiomassContent;
			} else if cellLU = "Rangeland" {
				//TODO
				biomassContent <- maxRangelandBiomassContent;
			}
	}
	
	// Colouring
	reflex updateColour when: (cellLU != "NonGrazable" and every(visualUpdate)) {
		
		if cellLU = "Cropland" {
			color <- rgb(255 + (216 - 255) / maxCropBiomassContent * biomassContent, 255 + (232 - 255) / maxCropBiomassContent * biomassContent, 180);
		} else if cellLU = "Rangeland" {
			color <-
			rgb(200 + (101 - 200) / maxRangelandBiomassContent * biomassContent, 230 + (198 - 230) / maxRangelandBiomassContent * biomassContent, 180 + (110 - 180) / maxRangelandBiomassContent * biomassContent);
		}
		
	}

}

