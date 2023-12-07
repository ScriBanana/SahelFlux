/**
* In: SahelFlux
* Name: GenerateExportFiles
* Generate various export files with simulation outputs
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "OutputVariablesGatherer.gaml"

global {
	string outputDirectory <- "../../OutputFiles/";
	bool generateMonthlySaves <- false;
	string experimentType;
	string timeStampInit;
	string runPrefix;
	
	//// LOG
	
	// Persistent log of all simulations ran until their conclusion
	action saveLogOutput {
		
		// File or header if need be
		if !file_exists(outputDirectory + "SahFl-Log.csv") {
			save parametersMap.keys + variableOutputsMap.keys + differentialOutputsMap.keys
				to: outputDirectory + "SahFl-Log.csv" format: "csv"
				rewrite: true header: false
			;
		} else if enableDebug { // Doesn't work with parallel runs
			matrix logAsMatrix <- matrix(csv_file(outputDirectory + "SahFl-Log.csv"));
			list logLastRow <- logAsMatrix row_at (logAsMatrix.rows - 1);
			if (logLastRow count (each!= nil)) != (length(parametersMap) + length(variableOutputsMap) + length(differentialOutputsMap)) {
				save parametersMap.keys + variableOutputsMap.keys + differentialOutputsMap.keys
					to: outputDirectory + "SahFl-Log.csv" format: "csv"
					rewrite: false header: false
				;
			}
		}
		
		// Simulation line
		write "Saving log entry for simulation " + int(self);
		save parametersMap.values + variableOutputsMap.values + differentialOutputsMap.values
			to: outputDirectory + "SahFl-Log.csv" format: "csv" rewrite: false header: false;
	}
	
	
	//// REGULAR SAVES
	
	// Saves output to a CSV whenever called during the simulation
	action saveOutputsDuringSim {
		do gatherRegularOutputs(regularOutputNFlowsMap, regularOutputCFlowsMap, regularOutputGHGFlowsMap);
		
		list lineToSave <-  [current_date.year, current_date.month, cycle, timeStampInit, runTime];
		lineToSave <<+ list<float>(variableOutputsMap.values);
		save lineToSave
			to: outputDirectory + "Monthly/" + runPrefix + "-MnthSv-" + villageName + cellSize + ".csv"
			format: "csv"
			rewrite: (current_date.month = starting_date.month and current_date.year = starting_date.year) ? true : false
			header: false
		;
		
		do resetRegularOutputMap;
	}
	
	// CSV headers
	action initOutputsDuringSim {
		do setVariableOutputMap(0.0, 0.0, 0.0, 0.0);
		
		list<string> inSimHeader <-  ["Year", "Month", "Cycle", "Machine time", "Runtime"];
		inSimHeader <<+ list<string>(variableOutputsMap.keys);
		
		save inSimHeader
			to: outputDirectory + "Monthly/" + runPrefix + "-MnthSv-" + villageName + cellSize + ".csv"
			format: "csv"
			rewrite: true
			header: false
		;
	}
	
	
	//// DETAILED OUTPUTS
	
	// At the end of the simulation, saves
	// - Parameters
	// - GHG emissions per pool
	// - N and C balance per pool
	// - Flows matrix (ENA paradigm)
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
		do exportOutputData;
		do exportGHGMat;
		do exportBalanceMat;
		
		do saveSFMatrix (outputCSVheader, "-Flow-", 1.0, false);
		do saveSFMatrix (outputCSVheader, "-FlowYear-", durationSimu, false);
		do saveSFMatrix (outputCSVheader, "-FlowHaYear-", (length(grazableLandscape) * hectarePerCell) * durationSimu, false);
		do saveSFMatrix (outputCSVheader, "-FlowDiv-", 1.0, true);
		do saveSFMatrix (outputCSVheader, "-FlowDivYear-", durationSimu, true);
		
		write "... Done";
	}
	
	// Gathers and saves parameters
	action exportParameterData { // Redundant with log.
		string pathParameters <-  outputDirectory + "Single/" + runPrefix + "/" + runPrefix + "-Param.csv";
		save parametersMap.keys to: pathParameters rewrite: true header: false;
		save parametersMap.values to: pathParameters rewrite: false header: false;
	}
	
	// Gathers and saves global outputs
	action exportOutputData { // Redundant with log.
		string pathOutputs <-  outputDirectory + "Single/" + runPrefix + "/" + runPrefix + "-Outputs.csv";
		save differentialOutputsMap.keys to: pathOutputs rewrite: true header: false;
		save differentialOutputsMap.values to: pathOutputs rewrite: false header: false;
	}
	
	// Gathers and saves pool GHG
	action exportGHGMat {
		string pathGHG <-  outputDirectory + "Single/" + runPrefix + "/" + runPrefix + "-GHGmat.csv";
		list<string> outputCSVheader <- ["", "kgCO2", "kgCH4", "kgN2O"];
		save outputCSVheader to: pathGHG rewrite: true header: false;
		
		loop subMap over: GHGFlowsMap.pairs {
			list lineToSave <- [subMap.key];
			loop flowPair over: subMap.value.pairs {
				lineToSave <+ string(flowPair.value);
			}
			save lineToSave to: pathGHG rewrite: false header: false;
		}
	}
	
	// Gathers and saves pool balance
	action exportBalanceMat {
		string pathBalance <-  outputDirectory + "Single/" + runPrefix + "/" + runPrefix + "-Balancemat.csv";
		list<string> outputCSVheader <- ["", "ΔkgC", "ΔkgN", "GHG(kgCO2eq)"];
		save outputCSVheader to: pathBalance rewrite: true header: false;
		
		loop subMap over: poolFlowsMap.pairs {
			list lineToSave <- [subMap.key];
			lineToSave <<+ subMap.value;
			save lineToSave to: pathBalance rewrite: false header: false;
		}
	}
	
	// Generate ENA flow matrix. May be divided by a global variable (divisionOperand)
	// and some relevant variable specific to each flow
	action saveSFMatrix (list<string> outputCSVheader, string fileCoreName, float divisionOperand, bool perFlowDivision) {
		
		float nbTLUHerds;
		map<string, float> dividingFactors;
		if perFlowDivision {
			nbTLUHerds <- float(mobileHerd sum_of each.herdSize);
			ask transhumance {	nbTLUHerds <- nbTLUHerds + transhumingHerd sum_of each.herdSize;}
			dividingFactors <- [
				"Households"::length(household),
				"MobileHerds"::nbTLUHerds,
				"FattenedAn"::nbFatteningHh,
				"ORPHeaps"::length(ORPHeap),
				"StrawPiles"::length(household),
				"HomeFields"::(listAllHomeParcels sum_of each.parcelSurface),
				"BushFields"::((grazableLandscape count (
					each.cellLU = "Cropland" and (each.myParcel = nil or !each.myParcel.homeField)
				)) * hectarePerCell),
				"Rangelands"::((grazableLandscape count (each.cellLU = "Rangeland")) * hectarePerCell),
				"Millet"::(parcel sum_of each.parcelSurface),
				"Groundnut"::(listAllBushParcels sum_of each.parcelSurface),
				"FallowVeg"::(listAllBushParcels sum_of each.parcelSurface),
				"SpontVeg"::((grazableLandscape count (each.cellLU = "Rangeland")) * hectarePerCell),
				"Weeds"::(length(grazableLandscape) * hectarePerCell),
				"Trees"::(grazableLandscape sum_of each.nbTrees)
			];
		}
		
		string pathN <-  outputDirectory + "Single/" + runPrefix + "/" + runPrefix + fileCoreName + "Nmat.csv";
		string pathC <-  outputDirectory + "Single/" + runPrefix + "/" + runPrefix + fileCoreName + "Cmat.csv";
		
		save outputCSVheader to: pathN rewrite: true header: false;
		save outputCSVheader to: pathC rewrite: true header: false;
		
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
			save lineToSave to: pathN rewrite: false;
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
			save lineToSave to: pathC rewrite: false;
			outputId <- outputId +1;
		}
	}
	
}
