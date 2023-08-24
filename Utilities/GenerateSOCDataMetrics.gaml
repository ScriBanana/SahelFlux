/**
* In: SahelFlux
* Name: GenerateSOCDataMetrics
* Generates metrics on SOC (confidential) field data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
* Find related model at https://github.com/ScriBanana/SahelFlux.
*/

model SahelFlux

global {
	string weightingType <- "DistNb" among: ["DistTot", "DistNb"];
	float moranDistance <- 56 #m;
	
	string filePath <- "../InputFiles/FieldData/SOCFieldData.csv";
	matrix inputData <- matrix(csv_file(filePath));
	
	string inPath <- "../InputFiles/SpatialInputs/";
	list<shape_file> villageLimits;
	list<string> villageNamesList <- ["Barry", "Sob", "Diohine"] const: true;
	
	geometry shape <- envelope(list<geometry>(columns_list(inputData)[0]));
	point pointZero <- {float(min(columns_list(inputData)[2])), float(min(columns_list(inputData)[3]))};
	float maxSOC <- float(max(columns_list(inputData)[10]));
	float minSOC <- float(min(columns_list(inputData)[10]));
	
	list<fieldParcel> parcelsSob;
	list<fieldParcel> parcelsDiohine;
	list<fieldParcel> parcelsBarry;
	
	init {
		
		create fieldParcel from: csv_file(filePath, true) with: [
			shape::geometry(get("wkt_geom")),
			Site::string(get("Site")),
			location::({float(get("X_Centroide_Parcelle")), float(get("Y_Centroide_Parcelle"))} - pointZero),
			Num_Parcelle::string(get("Num_Parcelle")),
			Superficie::float(get("Superficie (ha)")),
			Type_sol::string(get("Type_sol")),
			Type_champ::string(get("Type_champ")),
			Ref_SN::string(get("Ref_SN")),
			SOC_010::float(get("StockC-0_10 (Mg C ha)")),
			SOC_1030::float(get("StockC-10_30 (Mg C ha)"))
		] {
			SOC_030 <- SOC_010 + SOC_1030;
			myColor <- rgb(255 * SOC_1030 / minSOC);
		}
		
		parcelsSob <- fieldParcel where (each.Site = "Sob");
		parcelsDiohine <- fieldParcel where (each.Site = "Diohine");
		parcelsBarry <- fieldParcel where (each.Site = "Bari Sine");
		
		write "Sob : " + computeMoran(parcelsSob);
		write "Diohine : " + computeMoran(parcelsDiohine);
		write "Barry : " + computeMoran(parcelsBarry);
		
		loop villageName over: villageNamesList {
			villageLimits <+ shape_file(inPath + "Limi" + villageName + ".shp");
		}
		
	}
	
	float computeMoran (list<fieldParcel> inputGridList) {
		matrix<float> moranWeightsMatrix;
		
		moranWeightsMatrix <- generateMoranPolygonsWeightMatrix(inputGridList);
		
		return moran(inputGridList collect each.SOC_030, moranWeightsMatrix);
	}
	
	matrix<float> generateMoranPolygonsWeightMatrix (list<fieldParcel> inputGridList) {
		matrix<float> moranWeightsMatrix;
		map<fieldParcel, int> moranInputsMap;
		
		int idIncrement <- 0;
		ask inputGridList {
			moranInputsMap <+ self::idIncrement;
			idIncrement <- idIncrement + 1;
		}
		
		moranWeightsMatrix <- 0.0 as_matrix {length(moranInputsMap), length(moranInputsMap)};
		
		ask inputGridList {
			switch weightingType {
				match "DistTot" {
					ask inputGridList where (each.location != self.location) {
						moranWeightsMatrix[moranInputsMap[self], moranInputsMap[myself]] <-
							1/(self.location distance_to myself.location);
					}
				} match "DistNb" {
					ask inputGridList at_distance moranDistance {
						moranWeightsMatrix[moranInputsMap[self], moranInputsMap[myself]] <- 1;
					}
					
				}
			}
		}
		return moranWeightsMatrix;
	}
}

species fieldParcel parallel: false {
	string Site;
	string Num_Parcelle;
	float Superficie;
	string Type_sol;
	string Type_champ;
	string Ref_SN;
	float SOC_010;
	float SOC_1030;
	float SOC_030;
	rgb myColor;
	
	aspect default {
		draw shape color: myColor border: (Site = "Sob" ? #dimgrey : (Site = "Diohine" ? #darkslategray : #saddlebrown));
	}
}

experiment Run type: gui {
	output {
		layout tabs: false navigator: false;
		display "Main" type: java2D {
			species fieldParcel;
	        graphics "Village borders" {
	        	loop villageLimit over: villageLimits {
	        		draw villageLimit color: #transparent border: #black;
	        	}
	        }
		}
	}
}