/**
* In: SahelFlux
* Name: ImportZoning
* Assigns scenario parameters based on input data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ImportInputData

import "../Models/Entities/Household.gaml"

global {
	action readInputParameters {
		csv_file inputDataFile <- csv_file("../Inputs/SahelFlux_ScenarioInputData.csv");
		matrix inputData <- matrix(inputDataFile);
		
		int scenarioIndex <- (inputData row_at 0) index_of villageName;
		
		villageCenterPoint <- point((inputData column_at scenarioIndex)[1]);
		fallowEnabled <- bool((inputData column_at scenarioIndex)[2]);
		nbHousehold <- int((inputData column_at scenarioIndex)[3]);
		propTranshumantHh <- float((inputData column_at scenarioIndex)[4]);
		propFatteningHh <- float((inputData column_at scenarioIndex)[5]);
		meanHerdSize <- float((inputData column_at scenarioIndex)[8]);
		meanFattenedGroupSize <- float((inputData column_at scenarioIndex)[9]);
		SDHerdSize <- float((inputData column_at scenarioIndex)[10]);
		homeFieldsProportion <- float((inputData column_at scenarioIndex)[11]);
		homefieldsSOChaInit <- float((inputData column_at scenarioIndex)[12]);
		bushfieldsSOChaInit <- float((inputData column_at scenarioIndex)[13]);
		rangelandSOChaInit <- float((inputData column_at scenarioIndex)[14]);
		
		nbTranshumantHh <- round(propTranshumantHh * nbHousehold);
		nbFatteningHh <- round(propFatteningHh * nbHousehold);
		homefieldsSOCInit <- homefieldsSOChaInit * hectareToCell; // kgC/cell
		bushfieldsSOCInit <- bushfieldsSOChaInit * hectareToCell; // kgC/cell
		rangelandSOCInit <- rangelandSOChaInit * hectareToCell; // kgC/cell
	}
}
