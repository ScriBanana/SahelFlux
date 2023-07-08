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
	bool generateMonthlySaves <- false;
	string experimentType;
	string runPrefix <- "" + floor(machine_time / 1000) + "-" + experimentType + int(self) + "-";
	
	action saveLogOutput {
		if !file_exists(outputDirectory + "SahFl-Log.csv") {
			save parametersStringList + outputsStringList
				to: outputDirectory + "SahFl-Log.csv" format: "csv"
				rewrite: true header: false
			;
		}
		write "Saving log entry for simulation " + int(self);
		save parametersList + outputsList to: outputDirectory + "SahFl-Log.csv" format: "csv" rewrite: false header: false;
	}
	
	action exportStockFlowsOutputData {
		write "Saving data in " + outputDirectory;
		// Saving a matrix to a csv doesn't work. Issue raised on github. Fix coming up in Gama 1.9.0 (commit a4d2a56)
		
		runPrefix <- "" + floor(machine_time / 1000) + "-" + experimentType + int(self) + "-";
		
		// Variables
		float durationSimu <- (current_date - starting_date)/#year;
		
		// Header with IF and TF origin; lines for each TF destination and outflows
		list<string> outputCSVheader <- [""];
		outputCSVheader <<+ flowsMapTemplate.keys where (each contains "IF-");
		outputCSVheader <<+ NFlowsMap.keys;
		
		do exportParameterData;
		do exportGHGMat;
		do exportBalanceMat;
		
		do saveSFMatrix (outputCSVheader, "Flow-", 1.0, false);
		do saveSFMatrix (outputCSVheader, "FlowYear-", durationSimu, false);
		do saveSFMatrix (outputCSVheader, "FlowHaYear-", ((landscape count (each.biomassProducer)) / hectareToCell) * durationSimu, false);
		do saveSFMatrix (outputCSVheader, "FlowDiv-", 1.0, true);
		do saveSFMatrix (outputCSVheader, "FlowDivYear-", durationSimu, true);
		
		write "... Done";
	}
	
	action saveSFMatrix (list<string> outputCSVheader, string fileCoreName, float divisionOperand, bool perFlowDivision) {
		
		float nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
		ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
		map<string, float> dividingFactors <- [
			"Households"::length(household),
			"MobileHerds"::nbTLUHerds,
			"FattenedAn"::nbFatteningHh,
			"ORPHeaps"::length(ORPHeap),
			"StrawPiles"::length(household),
			"HomeFields"::(listAllHomeParcels sum_of each.parcelSurface),
			"BushFields"::((landscape count (each.cellLU = "Cropland" and (each.myParcel = nil or each.myParcel.homeField))) / hectareToCell),
			"Rangelands"::((landscape count (each.cellLU = "Rangeland")) / hectareToCell),
			"Millet"::((listAllHomeParcels + listAllBushParcels) sum_of each.parcelSurface),
			"Groundnut"::(listAllBushParcels sum_of each.parcelSurface),
			"FallowVeg"::(listAllBushParcels sum_of each.parcelSurface),
			"SpontVeg"::((landscape count (each.cellLU = "Rangeland")) / hectareToCell),
			"Weeds"::((landscape count (each.biomassProducer)) / hectareToCell),
			"Trees"::(landscape sum_of each.nbTrees)
		];
		
		string pathN <-  outputDirectory + "Single/" + runPrefix + fileCoreName + "Nmat.csv";
		string pathC <-  outputDirectory + "Single/" + runPrefix + fileCoreName + "Cmat.csv";
		
		save outputCSVheader to: pathN format: csv rewrite: true header: false;
		save outputCSVheader to: pathC format: csv rewrite: true header: false;
		
		//Again, could have been a loop over N and C, but Gama doesn't like looping on nested containers.
		int outputId <- 0;
		loop matLine over: rows_list (NFlowsMatrix) {
			string flowDestination <- flowsMapTemplate.keys[outputId + nbInflows];
			list<string> lineToSave <- [flowDestination];
			int inputId <- 0;
			loop valueToSave over: matLine {
				string flowOrigin <- (outputCSVheader - "")[inputId];
				float divisionFactor <- perFlowDivision and (flowOrigin in dividingFactors.keys) ?
					dividingFactors[flowOrigin] * divisionOperand :
					divisionOperand
				;
				lineToSave <+ string(valueToSave / divisionFactor);
				inputId <- inputId + 1;
			}
			save lineToSave to: pathN format: csv rewrite: false;
			outputId <- outputId +1;
		}
		
		outputId <- 0;
		loop matLine over: rows_list (CFlowsMatrix) {
			string flowDestination <- flowsMapTemplate.keys[outputId + nbInflows];
			list<string> lineToSave <- [flowDestination];
			int inputId <- 0;
			loop valueToSave over: matLine {
				string flowOrigin <- (outputCSVheader - "")[inputId];
				float divisionFactor <- perFlowDivision and (flowOrigin in dividingFactors.keys) ?
					dividingFactors[flowOrigin] * divisionOperand :
					divisionOperand
				;
				lineToSave <+ string(valueToSave / divisionFactor);
				inputId <- inputId + 1;
			}
			save lineToSave to: pathC format: csv rewrite: false;
			outputId <- outputId +1;
		}
	}
	
	action exportGHGMat {
		string pathGHG <-  outputDirectory + "Single/" + runPrefix + "GHGmat.csv";
		list<string> outputCSVheader <- ["", "kgCO2", "kgCH4", "kgN2O"];
		save outputCSVheader to: pathGHG format: csv rewrite: true header: false;
		
		loop subMap over: GHGFlowsMap.pairs {
			list lineToSave <- [subMap.key];
			loop flowPair over: subMap.value.pairs {
				lineToSave <+ string(flowPair.value);
			}
			save lineToSave to: pathGHG format: csv rewrite: false header: false;
		}
	}
	
	action exportBalanceMat {
		string pathBalance <-  outputDirectory + "Single/" + runPrefix + "Balancemat.csv";
		list<string> outputCSVheader <- ["", "ΔkgC", "ΔkgN", "GHG(kgCO2eq)"];
		save outputCSVheader to: pathBalance format: csv rewrite: true header: false;
		
		loop subMap over: poolFlowsMap.pairs {
			list lineToSave <- [subMap.key];
			lineToSave <<+ subMap.value;
			save lineToSave to: pathBalance format: csv rewrite: false header: false;
		}
	}
	
	action exportParameterData { // Redundant with log.
		string pathParameters <-  outputDirectory + "Single/" + runPrefix + "Param.csv";
		save parametersStringList to: pathParameters format: csv rewrite: true header: false;
		save parametersList to: pathParameters format: csv rewrite: false header: false;
	}
	
	action saveOutputsDuringSim {
		do gatherFlows;
		do computeOutputs;
		do gatherOutputsAndParameters;
		
		save [
			current_date.year, current_date.month,
			cycle, machine_time, runTime,
			outputsList
		]
			to: outputDirectory + "Monthly/" + runPrefix + "Out-MnthSv-B" + batchOn + "Sim" + int(self) + ".csv"
			format: "csv"
			rewrite: (current_date.month = starting_date.month and current_date.year = starting_date.year) ? true : false
			header: true
		;
	}
}
