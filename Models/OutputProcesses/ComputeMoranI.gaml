/**
* In: SahelFlux
* Name: ImportZoning
* Computes Moran I for a given list of cell
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model SahelFlux

import "../Main.gaml"

global {
	
	float computeMoran (list<landscape> inputGridList) {
		// Thought about storing the matrix for each case, but generating the neighbour one is fast enough
		matrix<float> moranWeightsMatrix <- generateMoranNeighboursWeightMatrix(inputGridList);
		return moran(inputGridList collect each.moranValue, moranWeightsMatrix);
	}
	
	matrix<float> generateMoranNeighboursWeightMatrix (list<landscape> inputGridList) {
		matrix<float> moranWeightsMatrix;
		map<landscape, int> moranInputsMap;
		
		int idIncrement <- 0;
		ask inputGridList {
			moranInputsMap <+ self::idIncrement;
			idIncrement <- idIncrement + 1;
		}
		
		moranWeightsMatrix <- 0.0 as_matrix {length(moranInputsMap), length(moranInputsMap)};
		
		ask inputGridList {
			ask self.neighbors where (each in inputGridList) {
				moranWeightsMatrix[moranInputsMap[self], moranInputsMap[myself]] <- 1.0;
			}
		}
		return moranWeightsMatrix;
	}
}