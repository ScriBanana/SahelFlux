/**
* In: SahelFlux
* Name: GenerateExportFiles
* Generate various export files with simulation outputs
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model GenerateExportFiles

import "ImportZoning.gaml"
import "../Utilities/ParamAndOutCentraliser.gaml"

global {
	string outputDirectory <- "../../OutputFiles/";
	string universalPrefix <- "" + floor(machine_time / 1000) + "-SahFl-";
	bool generateMonthlySaves <- false;
	string experimentType;
	
	action saveLogOutput {
		write "Saving output for simulation " + int(self);
		save [
			machine_time, int(self), experimentType,
			starting_date, endDate, cycle, runTime,
			fallowEnabled, meteoUpdateType,
			nbHousehold, nbTranshumantHh, nbFatteningHh,
			meanHerdSize, meanFattenedGroupSize,
			homeFieldsRadius, nbBushFieldsPerHh, nbHomeFieldsPerHh,
			maxNbNightsPerCellInPaddock, digestionLengthParamAsInt,
			totalNFlows, totalCFlows, totalNThroughflows, totalCThroughflows
		]
			to: outputDirectory + "SahFl-Log.csv"
			format: "csv"
			rewrite: false
			header: true
		;
	}
	
	action exportStockFlowsOutputData {
		write "Saving data in " + outputDirectory;
		// Saving a matrix to a csv doesn't work. Issue raised on github. Fix coming up in Gama 1.9.0 (commit a4d2a56)
		
		// Variables
		float durationSimu <- (current_date - starting_date)/#year;
		
		// Header with IF and TF origin; lines for each TF destination and outflows
		list<string> outputCSVheader <- [""];
		outputCSVheader <<+ flowsMapTemplate.keys where (each contains "IF-");
		outputCSVheader <<+ NFlowsMap.keys;
		
		do exportParameterData;
		do saveSFMatrixDivided (outputCSVheader, "Out-", 1.0);
		do saveSFMatrixDivided (outputCSVheader, "Out-y_", durationSimu);
		do saveSFMatrixDivided (outputCSVheader, "Out-ha_y_", ((landscape count (each.biomassProducer)) / hectareToCell) * durationSimu);
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
		do saveSFMatrixDivided (outputCSVheader, "Out-TLU_y_", (nbTLUHerds) * durationSimu);
		
		write "... Done";
	}
	
	action saveSFMatrixDivided (list<string> outputCSVheader, string fileCoreName, float divisionOperand) {
		
		string pathN <-  outputDirectory + "Single/" + universalPrefix + fileCoreName + "Nmat.csv";
		string pathC <-  outputDirectory + "Single/" + universalPrefix + fileCoreName + "Cmat.csv";
		
		save outputCSVheader to: pathN format: csv rewrite: true header: false;
		save outputCSVheader to: pathC format: csv rewrite: true header: false;
		
		//Again, could have been a loop over N and C, but Gama doesn't like looping on nested containers.
		int outputId <- 0;
		loop matLine over: rows_list (NFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			loop valueToSave over: matLine {
				lineToSave <+ string(valueToSave / divisionOperand); // TODO ne marche pas pour les fattened
			}
			save lineToSave to: pathN format: csv rewrite: false;
			outputId <- outputId +1;
		}
		outputId <- 0;
		loop matLine over: rows_list (CFlowsMatrix) {
			list<string> lineToSave <- [flowsMapTemplate.keys[outputId + nbInflows]];
			loop valueToSave over: matLine {
				lineToSave <+ string(valueToSave / divisionOperand);
			}
			save lineToSave to: pathC format: csv rewrite: false;
			outputId <- outputId +1;
		}
	}
	
	action exportParameterData { // Redundant with log.
		string pathParameters <-  outputDirectory + "Single/" + universalPrefix + "Param.csv";
		save parametersStringList to: pathParameters format: csv rewrite: false header: false;
		save parametersList to: pathParameters format: csv rewrite: false header: false;
	}
	
	action saveOutputsDuringSim {
		do gatherFlows;
		do computeOutputs;
		do gatherOutputsAndParameters;
		
		list<float> meanSOCS <- getMeanSOCS();
		float meanHomefieldsSOCS <- meanSOCS[0];
		float meanBushfieldsSOCS <- meanSOCS[1];
		float meanRangelandSOCS <- meanSOCS[2];
		
		save [
			current_date.year, current_date.month,
			cycle, machine_time, runTime,
			outputsList
		]
			to: outputDirectory + "Monthly/" + universalPrefix + "Out-MnthSv-B" + batchOn + "Sim" + int(self) + "-" + nbHousehold + "Hh" + nbTranshumantHh + "Tr" + nbFatteningHh + "FtF" + fallowEnabled + ".csv"
			format: "csv"
			rewrite: (current_date.month = starting_date.month and current_date.year = starting_date.year) ? true : false
			header: true
		;
	}
}
