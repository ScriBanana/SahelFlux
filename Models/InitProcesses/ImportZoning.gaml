/**
* In: SahelFlux
* Name: ImportZoning
* Generates grid layout based on input data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model SahelFlux

import "../Main.gaml"

global {
	
	//// Global world grid variables
	
	float cellHeight <- cellSize #m;
	float cellWidth <- cellSize #m;
	float hectarePerCell <- cellWidth * cellHeight / (10000 #m2); // ha/cell
	
	// NOTE : To generate the ASC file, see SahelFlux/Utilities/GenerateSpatialInput.gaml
	string zoningFilesPath <- "../InputFiles/GridInputs/";
	string zoningFileName <- "LU&ParcGrid" + villageName + cellSize + ".asc";
	file gridData <- file(zoningFilesPath + zoningFileName);
	geometry shape <- envelope(gridData);
	float totalAreaHa <- shape.area / 10000 #m2;
	
	action readLandscapeInputData {
		write "Reading grid data from " + zoningFileName;
		nonEmptyLandscape <- list(landscape);
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
		write "	Done. Cell size: " + cellSize + " m, village: " + villageName + ".";
	}
}

