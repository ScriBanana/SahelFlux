/**
* In: SahelFlux
* Name: ImportZoning
* Computes Moran I for a given list of cell
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model SahelFlux

import "../Main.gaml"

global {
	
	map<string, matrix<float>> moranWeightsMatrixStorageMap;
	string weightsMatrixType <- "Neighbours" among: ["Neighbours", "Distance"];
	float moranDistance <- 56 #m; // Coherent with validation data
	
	action getMoranSOCS {
		ask grazableLandscape {
			self.moranValue <- self.mySOCstock.totalSOC;
		}
		homefieldsSOCMoran <- computeMoran(grazableLandscape where (each.homefieldCell), villageName + cellSize + "-Homefields");
		bushfieldsSOCMoran <- computeMoran(
			grazableLandscape where (each.cellLU = "Cropland" and !each.homefieldCell), villageName + cellSize + "-Bushfields"
		);
		croplandSOCMoran <- computeMoran(grazableLandscape where (each.cellLU = "Cropland"), villageName + cellSize + "-Cropland");
		rangelandSOCMoran <- computeMoran(grazableLandscape where (each.cellLU = "Rangeland"), villageName + cellSize + "-Rangeland");
		globalSOCMoran <- computeMoran(grazableLandscape, villageName + cellSize + "-Global");
	}
	
	float computeMoran (list<landscape> inputGridList, string moranMatrixId) {
		matrix<float> moranWeightsMatrix;
		
		if moranWeightsMatrixStorageMap[moranMatrixId] != nil {
			// Storing in a permanent CSV is slower and map<string, matrix<float>> is light enough in RAM
			moranWeightsMatrix <- moranWeightsMatrixStorageMap[moranMatrixId];
		} else {
			moranWeightsMatrix <- generateMoranWeightMatrix(inputGridList, weightsMatrixType);
			moranWeightsMatrixStorageMap <+ moranMatrixId::moranWeightsMatrix;
		}
		
		// Stores weight matrix in a map for single runs (faster, but requires too much RAM for batches) or in a CSV for batches
		if batchOn and villageName = "Diohine" {
			string dirPath <- "../../InputFiles/MoranWeights/" + weightsMatrixType + "/";
			string filePath <- dirPath + moranMatrixId + ".csv";
			
			if file_exists(filePath) {
				moranWeightsMatrix <- matrix<float>(csv_file(filePath));
			} else {
				moranWeightsMatrix <- generateMoranWeightMatrix(inputGridList, weightsMatrixType);
				save moranWeightsMatrix to: filePath format: "csv" rewrite: false header: false;
			}
		} else {
			if moranWeightsMatrixStorageMap[moranMatrixId] != nil {
				moranWeightsMatrix <- moranWeightsMatrixStorageMap[moranMatrixId];
			} else {
				moranWeightsMatrix <- generateMoranWeightMatrix(inputGridList, weightsMatrixType);
				moranWeightsMatrixStorageMap <+ moranMatrixId::moranWeightsMatrix;
			}
		}
		
		return moran(inputGridList collect each.moranValue, moranWeightsMatrix);
	}
	
	matrix<float> generateMoranWeightMatrix (list<landscape> inputGridList, string matrixType) {
		matrix<float> moranWeightsMatrix;
		map<landscape, int> moranInputsMap;
		
		int idIncrement <- 0;
		ask inputGridList {
			moranInputsMap <+ self::idIncrement;
			idIncrement <- idIncrement + 1;
		}
		
		moranWeightsMatrix <- 0.0 as_matrix {length(moranInputsMap), length(moranInputsMap)};
		
		ask inputGridList {
			
			switch matrixType {
				match "Neighbours" {
					ask self.neighbors where (each in inputGridList) {
						moranWeightsMatrix[moranInputsMap[self], moranInputsMap[myself]] <- 1.0;
					}
				}
				
				match "Distance" {
					ask inputGridList at_distance moranDistance {
						moranWeightsMatrix[moranInputsMap[self], moranInputsMap[myself]] <- 1.0;
					}
				}
			}
		}
		return moranWeightsMatrix;
	}
}