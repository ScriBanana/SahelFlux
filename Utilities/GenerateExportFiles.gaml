/**
* In: SahelFlux
* Name: GenerateExportFiles
* Generate various export files with simulation outputs
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model GenerateExportFiles

import "../Models/OutputProcesses/ComputeOutputs.gaml"
import "ImportZoning.gaml"

global {
	string outputDirectory <- "../OutputFiles/";
	
	action exportOutputData {
		write "Saving data in " + outputDirectory;
		// Saving a matrix to a csv doesn't work. Issue raised on github. Fix coming up in Gama 1.9.0 (commit a4d2a56)
		
		// Header with IF and TF origin
		list<string> outputCSVheader <- [""];
		outputCSVheader <<+ flowsMapTemplate.keys where (each contains "IF-");
		outputCSVheader <<+ NFlowsMap.keys;
		
		save outputCSVheader to: outputDirectory + "SahelFlux-Out_NFlowsMatrix.csv" type: csv rewrite: true header: false;
		save outputCSVheader to: outputDirectory + "SahelFlux-Out_CFlowsMatrix.csv" type: csv rewrite: true header: false;
		
		// Lines for each TF destination and outflows
		//Again, could have been a loop over N and C, but Gama doesn't like looping on nested containers.
		int outputId <- 0;
		loop matLine over: rows_list (NFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			lineToSave <<+ list<string>(matLine);
			save lineToSave to: outputDirectory + "SahelFlux-Out_NFlowsMatrix.csv" type: csv rewrite: false;
			outputId <- outputId +1;
		}
		outputId <- 0;
		loop matLine over: rows_list (CFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			lineToSave <<+ list<string>(matLine);
			save lineToSave to: outputDirectory + "SahelFlux-Out_CFlowsMatrix.csv" type: csv rewrite: false;
			outputId <- outputId +1;
		}
		
		// Global matrix per ha
		save outputCSVheader to: outputDirectory + "SahelFlux-Out_haNFlowsMatrix.csv" type: csv rewrite: true header: false;
		save outputCSVheader to: outputDirectory + "SahelFlux-Out_haCFlowsMatrix.csv" type: csv rewrite: true header: false;
		
		outputId <- 0;
		loop matLine over: rows_list (NFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			loop valueToSave over: matLine {
				lineToSave <+ string(valueToSave / totalAreaHa);
			}
			save lineToSave to: outputDirectory + "SahelFlux-Out_haNFlowsMatrix.csv" type: csv rewrite: false;
			outputId <- outputId +1;
		}
		outputId <- 0;
		loop matLine over: rows_list (CFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			loop valueToSave over: matLine {
				lineToSave <+ string(valueToSave / totalAreaHa);
			}
			save lineToSave to: outputDirectory + "SahelFlux-Out_haCFlowsMatrix.csv" type: csv rewrite: false;
			outputId <- outputId +1;
		}
		
		// Global matrix per TLU
		save outputCSVheader to: outputDirectory + "SahelFlux-Out_TLUNFlowsMatrix.csv" type: csv rewrite: true header: false;
		save outputCSVheader to: outputDirectory + "SahelFlux-Out_TLUCFlowsMatrix.csv" type: csv rewrite: true header: false;
		
		outputId <- 0;
		loop matLine over: rows_list (NFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			loop valueToSave over: matLine {
				lineToSave <+ string(valueToSave / length(mobileHerd)); // TODO ne marche pas pour les fattened
			}
			save lineToSave to: outputDirectory + "SahelFlux-Out_TLUNFlowsMatrix.csv" type: csv rewrite: false;
			outputId <- outputId +1;
		}
		outputId <- 0;
		loop matLine over: rows_list (CFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			loop valueToSave over: matLine {
				lineToSave <+ string(valueToSave / length(mobileHerd));
			}
			save lineToSave to: outputDirectory + "SahelFlux-Out_TLUCFlowsMatrix.csv" type: csv rewrite: false;
			outputId <- outputId +1;
		}
		
		write "... Done";
	}
}
