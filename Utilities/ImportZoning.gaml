/**
* In: SahelFlux
* Name: ImportZoning
* Generates grid layout based on input data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model ImportZoning

import "../Utilities/SupportFunctions.gaml"
import "../Models/Entities/SpatialEntities/Landscape.gaml"

global {
	// Import land unit layout
	file gridLayout <- image_file("../Inputs/SpatialInputs/ZonageReduitDiohineAudouinEtAl2015_LowRes_Corrected.png");
	
	// Grid parameters and units
	//geometry shape <- envelope(gridLayout);
	geometry shape <- rectangle(4980 #m, 6140 #m); // Faute d'avoir un shapefile TODO RASTER
	point villageCenterPoint <- point(3294, 2993); // TODO Suits for ZonageReduitDiohineAudouinEtAl2015_LowRes raster. Pourrait partir du centre de l'enveloppe des croplands?
	int gridHeight <- gridLayout.contents.rows;
	int gridWidth <- gridLayout.contents.columns;
	float cellHeight <- shape.height / gridHeight;
	float cellWidth <- shape.width / gridWidth;
	float hectareToCell <- cellWidth * cellHeight / 10000 #m2;
	float totalAreaHa <- shape.area / 10000 #m2;
	
	//TODO  RASTER - Landscape units definition (from source)
	list<string> LUList <- ["Dwellings", "Lowlands", "Ponds", "Wooded savannah", "Fallows", "Rainfed crops", "Gardens"];
	list<rgb> LUColourList <- [rgb(134, 140, 134), rgb(100, 217, 244), rgb(57, 106, 178), rgb(101, 198, 110), rgb(57, 208, 202), rgb(216, 232, 180), rgb(0, 187, 53)];
	
	action assignLUFromRaster {
		write "Segregating landscape into land units from raster data.";
		loop cell over: landscape {
			
			// LU attribution according to colour
			rgb LURasterColour <- rgb(gridLayout at {cell.grid_x, cell.grid_y});
			rgb computedLUColour <- eucliClosestColour(LURasterColour, LUColourList);
			string rasterLU <- LUList at (LUColourList index_of computedLUColour);
			
			// LU assignation
			switch rasterLU {
				match_one ["Rainfed crops", "Fallows"] {
					cell.cellLU <- "Cropland";
				}
				match_one ["Wooded savannah", "Lowlands"] {
					cell.cellLU <- "Rangeland";
				}
				match "Dwellings" {
					cell.cellLU <- "Dwellings";
					cell.color <- #grey;
				}
				match "Ponds" {
					cell.cellLU <- "NonGrazable";
					cell.color <- #lightsteelblue;
				}
				default {
					cell.cellLU <- "NonGrazable";
					cell.color <- #silver;
				}
			}
		}
	}
}

