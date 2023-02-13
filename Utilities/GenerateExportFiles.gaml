/**
* In: SahelFlux
* Name: GenerateExportFiles
* Generate various export files with simulation outputs
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model GenerateExportFiles

import "../Models/OutputProcesses/ComputeOutputs.gaml"

global {
	string outputDirectory <- "../OutputFiles/";
	
	action exportOutputData {
		write "Saving data in " + outputDirectory;
		// Saving a matrix to a csv doesn't work. Issue raised on github. Fix coming up in Gama 1.9.0 (commit a4d2a56)
//		save NFlowsMap.keys to: outputDirectory + "SahelFlux-Out_NFlowsMatrix.csv" type: csv header: true rewrite: true;
//		save CFlowsMatrix to: outputDirectory + "SahelFlux-Out_CFlowsMatrix.csv" type: csv;
		
		write NFlowsMap.keys;
		write flowsMapTemplate.keys;
		
		loop matLine over: rows_list (NFlowsMatrix) {
			write matLine;
		}
		
	}
}
