/**
* In: SahelFlux
* Name: GenerateExportFiles
* Generate grid input ASCII files from parcel and land use GIS data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

global {
	string inPath <- "../InputFiles/SpatialInputs/";
	string outPath <- "../InputFiles/GridInputs/";
	
	float startTimeReal <- machine_time;
	bool endSimu <- false;
	
	int cellSize <- 50; // max LU shapefile pixelsize : 1.5 m
	float cellHeight <- cellSize #m;
	float cellWidth <- cellSize #m;
	
	list<string> villageNamesList <- ["Barry", "Sob", "Diohine"];
	string villageName <- "Sob" among: villageNamesList;
	
	shape_file parcelsCentroids <- shape_file(inPath + "Voro" + villageName + ".shp");
	shape_file shapeLU <- shape_file(inPath + "OcuSols" + villageName + ".shp");
	shape_file villageLimits <- shape_file(inPath + "Limi" + villageName + ".shp");
	shape_file croplandsLimits <- shape_file(inPath + "LimiParcelles" + villageName + ".shp");
	
	geometry shape <- envelope(villageLimits);
	geometry villageArea <- villageLimits.contents[0];
	geometry croplandArea <- croplandsLimits.contents[0];
	
	list<string> LUList <- [
		"Dwelling", "Tree", "Homefield", // 0, 1, 2
		"Bushfield", "BareGround", "Pond", // 3, 4, 5
		"Road", "Rangeland", "NonGrazable", // 6, 7, 8
		"Fallow", "Garden", "Lowland",  // 9, 10, 11
		"River" // 12
	];
	list<string> parcellableLUList <- ["Homefield", "Bushfield", "Fallow"];
	list<rgb> LUColours <- [
		rgb(134, 140, 134), #green, rgb(186, 202, 150), rgb(216, 232, 180), #ivory, rgb(57, 106, 178), #grey,
		rgb(101, 198, 110), #red, rgb(57, 208, 202), rgb(0, 187, 53), rgb(100, 217, 244), #blue
	];
	map<string, float> overLUAreaTemplate <- [
		"Dwelling"::0.0, "Tree"::0.0, "Homefield"::0.0, "Bushfield"::0.0, "BareGround"::0.0, "Pond"::0.0, "Road"::0.0,
		"Rangeland"::0.0, "NonGrazable"::0.0, "Fallow"::0.0, "Garden"::0.0, "Lowland"::0.0, "River"::0.0
	];
	
	
	init {
		write "Generating map for " + villageName + ", cell size : " + cellSize;
		
		do generateParcelsPolygons (parcelsCentroids);
		do generateOcuSolsPolygons (shapeLU);
		
		write "Getting grid info from overlapping polygons";
		int cellCount <- 1;
		ask cellGrid parallel: true {
//			do progressionPrompt (cellCount, length(cellGrid), 10);
			if mod(cellCount, length(cellGrid) / 10) = 0 {
				write "	" + int(ceil(cellCount / length(cellGrid) * 100)) + " %";
			}
			cellCount <- cellCount + 1;
			do getOverlappingPolygonsAreasAndSetLU;
		}
		
		write "Creating parcels";
		ask shuffle(parcelsShapes) parallel: true {
			do createParcel;
		}
		
		do generateOutputFiles;
		
		float runTime <- (machine_time - startTimeReal) / 60000;
		write "Done. Runtime : " + floor(runTime) + " min " + round((runTime - floor(runTime)) * 60 ) + " s";
		endSimu <- true;
	}
	
	action generateParcelsPolygons (shape_file inputPoints) {
		write "Creating Voronoi parcels from " + inputPoints;
		list<point> points;
		loop voroPoint over: inputPoints.contents {
			points <+ point(voroPoint);
		}
		list<geometry> voronoiPolygons <- voronoi(points);
		create parcelsShapes from: voronoiPolygons {
			self.shape <- croplandArea inter self.shape;
		}
	}
	
	action generateOcuSolsPolygons (shape_file inputShapes) {
		write "Extracting land units from " + inputShapes;
		create ocuSolShapes from: inputShapes.contents with:[class::float(get("Classe"))] {
			if class > 13 {
				shpLU <- "NonGrazable";
				self.color <- #red;
			} else {
				shpLU <- LUList[class - 1];
				self.color <- LUColours[class - 1];
			}
		}
	}
	
	action generateOutputFiles {
		write "Exporting grid file to " + outPath + "LU&ParcGrid" + villageName + cellSize + ".asc";
		ask cellGrid {
			assert self.cellLUId < 100;
			self.grid_value <- float(self.myParcelId);
			self.grid_value <- self.grid_value + (self.cellLUId + 1) / 100;
		}
		save cellGrid to: outPath + "LU&ParcGrid" + villageName + cellSize + ".asc";
	}
}

grid cellGrid
	cell_height: cellHeight cell_width: cellWidth parallel: true
	neighbors: 8 optimizer: "JPS" schedules: [] use_regular_agents: false
{
	string cellLU;
	int cellLUId min: 0 max: 99;
	parcel myParcel;
	int myParcelId min: 0;
	float grid_value;
	
	action getOverlappingPolygonsAreasAndSetLU {
		
		list<ocuSolShapes> overOcuSolShapes <- ocuSolShapes overlapping self;
		list<parcelsShapes> overParcelsShapes <- parcelsShapes overlapping self;
		
		// Remove cell if out of bounds
		if empty(overOcuSolShapes) {
			do die;
		}
		assert !dead(self);
		
		// Get overlapping LUs and select the most present one
		map<string, float> overLUArea <- copy(overLUAreaTemplate);
		ask overOcuSolShapes parallel: true {
			// inter function below is the (VERY) slow part of the script (especially with small cellSize)
			overLUArea[self.shpLU] <- overLUArea[self.shpLU] + (self.shape inter myself.shape).area;
		}
		cellLU <- first(overLUArea.pairs sort_by -each.value).key;
		cellLUId <- LUList index_of cellLU;
		color <- LUColours[cellLUId];
		
		// Assign to parcel which polygon is most present
		if !empty(overParcelsShapes) and cellLU in parcellableLUList {
			parcelsShapes myParcelShape;
			map<parcelsShapes, float> overParcelArea;
			ask overParcelsShapes parallel: true {
				overParcelArea <+ self::(myself.shape inter self.shape).area;
			}
			myParcelShape <- first(overParcelArea.pairs sort_by - each.value).key;
			ask myParcelShape {
				self.parcelCells <+ myself;
			}
		}
	}
}

species parcel parallel: true schedules: [] {
	rgb parcelColour;
	list<cellGrid> myCells;
	aspect default {
		draw self.shape color: #transparent border: parcelColour;
	}
}

species parcelsShapes parallel: true schedules: [] {
	rgb color <- rnd_color(255);
	list<cellGrid> parcelCells;
	
	action createParcel {
		if empty(parcelCells) {
			do die;
		} else {
			create parcel {
				self.parcelColour <- myself.color;
				ask (myself.parcelCells) {
					assert self.myParcel = nil;
					myself.myCells <+ self;
					self.myParcel <- myself;
					self.myParcelId <- int(myself);
				}
				self.shape <- union(self.myCells);
			}
			do die;
		}
	}
	
	aspect default {
		draw self.shape color: color border: color;
	}
}

species ocuSolShapes parallel: true schedules: [] {
	int class;
	string shpLU;
	rgb color;
	aspect default {
		draw self.shape color: color;
	}
}

experiment GenerateOne type: gui {
	parameter "Village" var: villageName among: villageNamesList;
	parameter "Cell size" var: cellSize;
	
    output {
	    display map type: java2D{
	        grid cellGrid border: #lightgrey;
//	        species parcelsShapes aspect: default;
//	        species ocuSolShapes aspect: default;
	        species parcel;
	        graphics "sf" {
	        	draw villageArea color: #transparent border: #black;
//	        	draw croplandArea color: #transparent border: #brown;
	        }
	    }
    }
}

experiment GenerateAll autorun: true type: batch until: endSimu {
	parameter "Village" var: villageName among: villageNamesList;
	parameter "Cell size" var: cellSize among: [50, 40, 30, 20, 10];
}