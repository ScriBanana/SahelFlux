/**
* In: SahelFlux
* Name: ORPHeap
* Manure and human wastes heap
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ORPHeap

import "Household.gaml"

global {
	
	//// Global manure heap parameters
	
	float kitchenWasteInputRate <- 0.33; // kgDM/day/hh
	float otherWastesInputRate <- 0.25; // kgDM/day/hh (Grillot 2018)
	float kitchenWastesNInputRate <- 0.594; // kgN/day/hh (Grillot 2018)
	float otherWastesNContent <- 0.001; // kgN/kgDM TODO DUMMY
	float kitchenWastesCContent <- 0.6; // kgC/kgDM TODO DUMMY
	float otherWastesCContent <- 0.4; // kgC/kgDM TODO DUMMY
	
	map<string, float> flowsMapORPHeap <- ["Inflows"::0.0, "ToHomeFields"::0.0, "ToBushFields"::0.0];
	
	//// Global manure heap functions
	
	date lastORPAddition <- starting_date;
	action addWastesToHeaps {
		ask ORPHeap {
			do addWastes;
		}
		lastORPAddition <- current_date;
	}
	
}

species ORPHeap schedules: [] {
	
	//// Parameters
	
	household myHousehold;
	
	list heapFattenedInput; // float::VSE, float::CAmount, float::NAmount
	
	float heapNContent;
	float heapCContent;
	
	float heapCH4ToBeEmittedInRainySeason;
	
	//// Functions
	
	action addWastes {
		float ORPAccumulationPeriodLength <- (current_date - lastORPAddition) / 86400; // Converted in days TODO utiliser time
		float wastesNAddition <- (kitchenWastesNInputRate + otherWastesInputRate * otherWastesNContent) * ORPAccumulationPeriodLength;
		float wastesCAddition <- (kitchenWasteInputRate * kitchenWastesCContent + otherWastesInputRate * otherWastesCContent) * ORPAccumulationPeriodLength;
		heapNContent <- heapNContent + wastesNAddition;
		heapCContent <- heapCContent + wastesCAddition;
		ask world {	do saveFlowInMap("N", "Households", "TF-ToORPHeaps" , wastesNAddition);}
		ask world {	do saveFlowInMap("C", "Households", "TF-ToORPHeaps" , wastesCAddition);}
	}
	
	action accumulateInputs {
		loop dungDeposit over: heapFattenedInput {
			
			float futureCH4Emission <- methaneProdFromManure * methaneConversionFactorORPPile * float(dungDeposit[0]); // kgCH4
			heapCH4ToBeEmittedInRainySeason <- heapCH4ToBeEmittedInRainySeason + futureCH4Emission;
			heapCContent <- heapCContent + min(0, float(dungDeposit[1]) - futureCH4Emission * coefCH4ToC);
			// Wastes don't contribute to CH4 emissions, then. They are just added to soils C stock.
			heapNContent <- heapNContent + float(dungDeposit[2]) + float(dungDeposit[3]);
		}
		
		heapFattenedInput <- [];
	}
	
	action emitRSHeapsCH4 {
		ask world {	do saveFlowInMap("C", "ORPHeaps", "OF-GHG" , myself.heapCH4ToBeEmittedInRainySeason * coefCH4ToC);}
		heapCH4ToBeEmittedInRainySeason <- 0.0;
	}
	
	action spreadORPOnParcels {
//		ask myHousehold.myHomeParcelsList {
//			currentCell.mySOCstock.periodCInputMap["ORP"] <- currentCell.mySOCstock.periodCInputMap["ORP"] + heapCContent;
//		}
	}
	
	// TODO find out wtf that is and if it is necessary
//	float lastORPNStock <- heapNContentInit;
//	float lastORPCStock <- heapCContentInit;
//	action registerORPFlows {
//		
//		lastORPNStock <- heapNContent;
//		lastORPCStock <- heapCContent;
//	}
}


