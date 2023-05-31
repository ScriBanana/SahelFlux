/**
* In: SahelFlux
* Name: GenerateExportFiles
* Generate various export files with simulation outputs
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model GenerateExportFiles

import "ImportZoning.gaml"

global {
	string outputDirectory <- "../../OutputFiles/";
	string filePrefix <- "SahelFlux-Out-";
	
	action exportStockFlowsOutputData {
		write "Saving data in " + outputDirectory;
		// Saving a matrix to a csv doesn't work. Issue raised on github. Fix coming up in Gama 1.9.0 (commit a4d2a56)
		
		// Variables
		float durationSimu <- (current_date - starting_date)/#year;
		
		// Header with IF and TF origin; lines for each TF destination and outflows
		list<string> outputCSVheader <- [""];
		outputCSVheader <<+ flowsMapTemplate.keys where (each contains "IF-");
		outputCSVheader <<+ NFlowsMap.keys;
		
		
		do saveSFMatrixDivided (outputCSVheader, "", 1.0);
		do saveSFMatrixDivided (outputCSVheader, "y_", durationSimu);
		do saveSFMatrixDivided (outputCSVheader, "ha_y_", totalAreaHa * durationSimu);
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
		do saveSFMatrixDivided (outputCSVheader, "TLU_y_", (nbTLUHerds) * durationSimu);
		
		write "... Done";
	}
	
	action saveSFMatrixDivided (list<string> outputCSVheader, string fileCoreName, float divisionOperand) {
		
		save outputCSVheader to: outputDirectory + filePrefix + fileCoreName + "Nmat.csv" format: csv rewrite: true header: false;
		save outputCSVheader to: outputDirectory + filePrefix + fileCoreName + "Cmat.csv" format: csv rewrite: true header: false;
		
		//Again, could have been a loop over N and C, but Gama doesn't like looping on nested containers.
		int outputId <- 0;
		loop matLine over: rows_list (NFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			loop valueToSave over: matLine {
				lineToSave <+ string(valueToSave / divisionOperand); // TODO ne marche pas pour les fattened
			}
			save lineToSave to: outputDirectory + filePrefix + fileCoreName + "Nmat.csv" format: csv rewrite: false;
			outputId <- outputId +1;
		}
		outputId <- 0;
		loop matLine over: rows_list (CFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			loop valueToSave over: matLine {
				lineToSave <+ string(valueToSave / divisionOperand);
			}
			save lineToSave to: outputDirectory + filePrefix + fileCoreName + "Cmat.csv" format: csv rewrite: false;
			outputId <- outputId +1;
		}
	}
	
}
