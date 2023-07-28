/**
* In: SahelFlux
* Name: ImportZoning
* Generates grid layout based on input data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model ImportZoning

import "../Models/Entities/SpatialEntities/Landscape.gaml"

global {
	
	//// Global world grid parameters
	
	int cellSize <- 40; // max LU shapefile pixelsize : 1.5 m
	float cellHeight <- cellSize #m;
	float cellWidth <- cellSize #m;
	float hectareToCell <- cellWidth * cellHeight / 10000 #m2; // cell/ha
	
	string filePath <- "../Inputs/GridInputs/";
	file gridData <- file(filePath + "LU&ParcGrid" + villageName + cellSize + ".asc");
	geometry shape <- envelope(gridData);
	float totalAreaHa <- shape.area / 10000 #m2;
	
	point villageCenterPoint <- point(2100, 1700); // TODO Pourrait partir du centre de l'enveloppe des croplands?
	
	action readLandscapeInputData {
		write "Reading grid data from " + gridData;
		ask landscape {
			if grid_value = 0.0 {
				nonEmptyLandscape >- self;
				do die;
			}
			
			parcelID <- floor(grid_value);
			parcelsIDList <+ parcelID;
			cellLUId <- round(100 * (grid_value - parcelID)) - 1;
			
			list<rgb> LUColours <- [
				rgb(134, 140, 134), #green, rgb(186, 202, 150), rgb(216, 232, 180), #ivory, rgb(57, 106, 178), #grey,
				rgb(101, 198, 110), #red, rgb(57, 208, 202), rgb(0, 187, 53), rgb(100, 217, 244), #blue
			];
			color <- cellLUId >= 0 ? LUColours[cellLUId] : #white;
		}
		parcelsIDList <- remove_duplicates(parcelsIDList);
		parcelsIDList >- 0;
	}
}

