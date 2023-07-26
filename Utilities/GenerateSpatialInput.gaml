/**
* In: SahelFlux
* Name: GenerateExportFiles
* Generate grid input ASCII files from parcel and land use GIS data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model GenerateSpatialInput

global {
	float startTimeReal <- machine_time;
	bool endSimu <- false;
	
	int cellSize <- 50; // max LU shapefile pixelsize : 1.5 m
	float cellHeight <- cellSize #m;
	float cellWidth <- cellSize #m;
	
	list<string> villageNamesList <- ["Sob", "Diohine", "Barry"];
	string villageName <- "Barry" among: villageNamesList;
	shape_file parcelsCentroids <- shape_file("../Inputs/SpatialInputs/Voro" + villageName + ".shp");
	shape_file shapeLU <- shape_file("../Inputs/SpatialInputs/OcuSols" + villageName + ".shp");
	shape_file villageLimits <- shape_file("../Inputs/SpatialInputs/Limi" + villageName + ".shp");
	shape_file croplandsLimits <- shape_file("../Inputs/SpatialInputs/LimiParcelles" + villageName + ".shp");
	geometry villageArea <- villageLimits.contents[0];
	geometry croplandArea <- croplandsLimits.contents[0];
	geometry shape <- envelope(villageLimits);
	
	list<string> LUList <- [
		"Dwelling", "Tree", "Homefield", "Bushfield", "BareGround", "Pond", "Road",
		"Rangeland", "NonGrazable", "Fallow", "Garden", "Lowland", "River"
	];
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
		
		do generateGridInitFiles;
		
		float runTime <- (machine_time - startTimeReal) / 60000;
		write "Done. Runtime : " + floor(runTime) + " min " + round((runTime - floor(runTime)) * 60 ) + " s";
		endSimu <- true;
	}
	
	action generateParcelsPolygons (shape_file inputPoints) {
		write "Creating parcels from " + inputPoints;
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
	
	action generateGridInitFiles {
		write "Exporting LU grid file";
		ask cellGrid {
			self.grid_value <- self.cellLUId;
		}
		save cellGrid to:"../Inputs/GridInputs/LUGrid" + villageName + cellSize + ".asc";
		
		write "Exporting parcels grid file";
		ask cellGrid {
			self.grid_value <- self.myParcelId;
		}
		save cellGrid to:"../Inputs/GridInputs/ParcelGrid" + villageName + cellSize + ".asc";
	}
}

grid cellGrid
	cell_height: cellHeight cell_width: cellWidth parallel: true
	neighbors: 8 optimizer: "JPS" schedules: [] use_regular_agents: false
{
	string cellLU;
	float cellLUId;
	parcel myParcel;
	float myParcelId;
	
	action getOverlappingPolygonsAreasAndSetLU {
		
		list<ocuSolShapes> overOcuSolShapes <- ocuSolShapes overlapping self;
		list<parcelsShapes> overParcelsShapes <- parcelsShapes overlapping self;
		
		// Kill if out of bounds
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
		color <- LUColours[LUList index_of cellLU];
		switch cellLU {
			match "Homefield" {
				cellLU <- "Homefield";
				cellLUId <- 1.0;
			}
			match "Bushfield" {
				cellLU <- "Bushfield";
				cellLUId <- 2.0;
			}
			match "Fallow" {
				cellLU <- "Fallow";
				cellLUId <- 3.0;
			}
			match_one ["Tree", "Rangeland", "Lowland"] {
				cellLU <- "Rangeland";
				cellLUId <- 4.0;
			}
			default {
				cellLU <- "NonGrazable";
				cellLUId <- 5.0;
			}
		}
		
		// Assign to parcel which polygon is most present
		if !empty(overParcelsShapes) and cellLU != "NonGrazable" and cellLU != "Rangeland" {
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
					self.myParcelId <- float(int(myself));
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

experiment Run type: gui {
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

experiment Batch autorun: true type: batch until: endSimu {
	parameter "Cell size" var: cellSize among: [50, 40, 30, 20, 10];
	parameter "Village" var: villageName among: villageNamesList;
}