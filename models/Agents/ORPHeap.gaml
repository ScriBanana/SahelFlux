
/**
* In: SahelFlux
* Name: ORPHeap
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ORPHeap

import "Household.gaml"

global {
	float heapNContentInit <- 0.0; // kgN Init value is 0 because start of dry season?
	float heapCContentInit <- 0.0; // kgC Init value is 0 because start of dry season?
	
	float kitchenWasteInputRate <- 0.33; // kgDM/day/hh
	float otherWastesInputRate <- 0.25; // kgDM/day/hh (Grillot 2018)
	float kitchenWastesNInputRate <- 0.594; // kgN/day/hh (Grillot 2018)
	float otherWastesNContent <- 0.001; // kgN/kgDM TODO DUMMY
	float kitchenWastesCContent <- 0.6; // kgC/kgDM TODO DUMMY
	float otherWastesCContent <- 0.4; // kgC/kgDM TODO DUMMY
	
	date lastORPAddition <- starting_date;
}

species ORPHeap {
	
	household myHousehold;
	
	float heapNContent;
	float heapCContent;
	
	action addWastes {
		float ORPAccumulationPeriodLength <- (current_date - lastORPAddition) / 86400; // Converted in days
		heapNContent <- heapNContent + (kitchenWastesNInputRate + otherWastesInputRate * otherWastesNContent) * ORPAccumulationPeriodLength;
		heapCContent <- heapCContent + (kitchenWasteInputRate * kitchenWastesCContent + otherWastesInputRate * otherWastesCContent) * ORPAccumulationPeriodLength;
	}
	
	action spreadORPOnParcels {
//		ask myHousehold.myHomeParcelsList {
//			currentCell.mySOCstock.periodCInputMap["ORP"] <- currentCell.mySOCstock.periodCInputMap["ORP"] + heapCContent;
//		}
	}
}


