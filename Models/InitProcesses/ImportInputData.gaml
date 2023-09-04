/**
* In: SahelFlux
* Name: ImportZoning
* Assigns scenario parameters based on input data
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "../Main.gaml"

global {
	
	float propTranshumantHhExplo <- -1.0;
	float propFatteningHhExplo <- -1.0;
	float meanHerdSizeExplo <- -1.0;
	float meanFattenedGroupSizeExplo <- -1.0;
	float homeFieldsProportionExplo <- -1.0;
	
	action readInputParameters {
		csv_file inputDataFile <- csv_file("../InputFiles/SahelFlux_ScenarioInputData.csv");
		// Watch for character formatting (i.e. e.g. 1,5 instead of 1.5)
		
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
		
		if isExplo {
			propTranshumantHh <- propTranshumantHhExplo = -1.0 ? propTranshumantHh : propTranshumantHhExplo;
			propFatteningHh <- propFatteningHhExplo = -1.0 ? propFatteningHh : propFatteningHhExplo;
			meanHerdSize <- meanHerdSizeExplo = -1.0 ? meanHerdSize : meanHerdSizeExplo;
			meanFattenedGroupSize <- meanFattenedGroupSizeExplo = -1.0 ? meanFattenedGroupSize : meanFattenedGroupSizeExplo;
			homeFieldsProportion <- homeFieldsProportionExplo = -1.0 ? homeFieldsProportion : homeFieldsProportionExplo;
		}
		
		nbTranshumantHh <- round(propTranshumantHh * nbHousehold);
		nbFatteningHh <- round(propFatteningHh * nbHousehold);
		homefieldsSOCInit <- homefieldsSOChaInit * hectareToCell; // kgC/cell
		bushfieldsSOCInit <- bushfieldsSOChaInit * hectareToCell; // kgC/cell
		rangelandSOCInit <- rangelandSOChaInit * hectareToCell; // kgC/cell
		
	}
}
