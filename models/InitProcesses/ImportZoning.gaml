/**
* In: SahelFlux
* Name: ImportZoning
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model ImportZoning

import "../SupportFunctions.gaml"
import "../SpatialEntities/Landscape.gaml"

global {
	// Import land unit layout
	file gridLayout <- image_file("../includes/SpatialInputs/ZonageReduitDiohineAudouinEtAl2015_LowRes.png");
	
	// Grid parameters and units
	//geometry shape <- envelope(gridLayout);
	geometry shape <- rectangle(4980 #m, 6140 #m); // Faute d'avoir un shapefile TODO RASTER
	int gridHeight <- gridLayout.contents.rows;
	int gridWidth <- gridLayout.contents.columns;
	float cellHeight <- shape.height / gridHeight;
	float cellWidth <- shape.width / gridWidth;
	float hectareToCell <- cellWidth * cellHeight / 10000 #m2;
	
	//TODO  RASTER - Landscape units definition (from source)
	list<string> LUList <- ["Dwellings", "Lowlands", "Ponds", "Wooded savannah", "Fallows", "Rainfed crops", "Gardens"];
	list<rgb> LUColourList <- [rgb(124, 130, 134), rgb(100, 217, 244), rgb(0, 114, 185), rgb(101, 198, 110), rgb(57, 208, 202), rgb(216, 232, 180), rgb(0, 187, 53)];
	
	action importLURaster { //TODO RASTER
		write "Reading input raster";
		loop cell over: landscape {
			
			// LU attribution according to colour (see ImportZoning.gaml)
			rgb LURasterColour <- rgb(gridLayout at {cell.grid_x, cell.grid_y});
			rgb computedLUColour <- eucliClosestColour(LURasterColour, LUColourList);
			cell.cellLU <- LUList at (LUColourList index_of computedLUColour);
			
			// LU assignation
			if cell.cellLU = "Rainfed crops" or cell.cellLU = "Fallows" {
				cell.cellLU <- "Cropland";
				
			} else if cell.cellLU = "Wooded savannah" or cell.cellLU = "Lowlands" {
				cell.cellLU <- "Rangeland";
				
			} else {
				cell.cellLU <- "NonGrazable";
				cell.color <- #grey;
				
			}
		}
	}
	
	action initGrazableBiomass {
		
	}
}

