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
	
	// Input
	float kitchenWasteInputRate <- 0.33; // kgDM/day/hh
	float otherWastesInputRate <- 0.25; // kgDM/day/hh (Grillot 2018)
	float ratioStrawToManureInORP <- 29/71; // kgDM/kgDM, Wade 2016
	
	// Spreading
	float maxManureCartWeight <- 300 / 2; // kgDM expert knowledge
	
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
	
	float heapQuantity; // kgDM
	float manureInHeap; // kgDM manure
	float heapNContent; // kgN
	float heapCContent; // kgC
	
	float heapCH4ToBeEmittedInRainySeason;
	
	list<parcel> nextSpreadParcelsOrder; // = myHomeParcelsList, but rotates
	parcel parcelSpreadOn;
	float ORPSpreadOnCurrentParcel <- 0.0;
	
	//// Functions
	
	action addWastes {
		float ORPAccumulationPeriodLength <- (current_date - lastORPAddition) / 86400; // Converted in days TODO utiliser time
		heapQuantity <- heapQuantity + (kitchenWasteInputRate + otherWastesInputRate) * ORPAccumulationPeriodLength;
		float wastesNAddition <- (kitchenWastesNInputRate + otherWastesInputRate * otherWastesNContent) * ORPAccumulationPeriodLength;
		float wastesCAddition <- (kitchenWasteInputRate * kitchenWastesCContent + otherWastesInputRate * otherWastesCContent) * ORPAccumulationPeriodLength;
		heapNContent <- heapNContent + wastesNAddition;
		heapCContent <- heapCContent + wastesCAddition;
		ask world {	do saveFlowInMap("N", "Households", "TF-ToORPHeaps" , wastesNAddition);}
		ask world {	do saveFlowInMap("C", "Households", "TF-ToORPHeaps" , wastesCAddition);}
	}
	
	action accumulateFattenedInputs {
		loop dungDeposit over: heapFattenedInput {
			
			// Fattened manure
			float futureCH4Emission <- methaneProdFromManure * methaneConversionFactorORPPile * float(dungDeposit[0]); // kgCH4
			heapCH4ToBeEmittedInRainySeason <- heapCH4ToBeEmittedInRainySeason + futureCH4Emission;
			heapQuantity <- heapQuantity + float(dungDeposit[0]) - futureCH4Emission;
			manureInHeap <- manureInHeap + float(dungDeposit[0]) - futureCH4Emission;
			heapCContent <- heapCContent + min(0, float(dungDeposit[1]) - futureCH4Emission * coefCH4ToC);
			// Wastes don't contribute to CH4 emissions, then. They are just added to soils C stock.
			heapNContent <- heapNContent + float(dungDeposit[2]) + float(dungDeposit[3]);
			
			// Refusals
			float addedStraw <- float(dungDeposit[0]) * ratioStrawToManureInORP;
			heapQuantity <- heapQuantity + addedStraw;
			heapCContent <- heapCContent + addedStraw * milletStrawCContent;
			heapNContent <- heapNContent + addedStraw * milletStrawNContent;
			
		}
		heapFattenedInput <- []; // Useless but safer
	}
	
	
	action emitRSHeapsCH4 {
		ask world {	do saveFlowInMap("C", "ORPHeaps", "OF-GHG" , myself.heapCH4ToBeEmittedInRainySeason * coefCH4ToC);}
		heapCH4ToBeEmittedInRainySeason <- 0.0;
	}
	
	action spreadORPOnParcels {
		
		// Select new parcel if need be
		if ORPSpreadOnCurrentParcel / parcelSpreadOn.parcelSurface > maxORPSpreadPerParcel {
			parcelSpreadOn <- first(nextSpreadParcelsOrder);
			nextSpreadParcelsOrder >- first(nextSpreadParcelsOrder);
			nextSpreadParcelsOrder <+ parcelSpreadOn;
		}
		
		float spreadORPQuantity <- heapQuantity > maxManureCartWeight ? maxManureCartWeight : heapQuantity;
		float spreadManureInSpreadORPQuantity <- (manureInHeap / heapQuantity) * spreadORPQuantity;
		float spreadCQuantity <- heapQuantity / spreadORPQuantity * heapCContent;
		float spreadNQuantity <- heapQuantity / spreadORPQuantity * heapNContent;
		
		// Add quantity for parcel rotation
		ORPSpreadOnCurrentParcel <- ORPSpreadOnCurrentParcel + spreadORPQuantity;
		
		// Add carbon and manure for CH4 emissions
		ask parcelSpreadOn.myCells {
			mySOCstock.carbonInputsList <+ [
				"ORP", spreadManureInSpreadORPQuantity, spreadCQuantity
			];
		}
		
		// N2O direct
		
		// Indirect RS
		
		// N incorporé (N avail)
		
	}
	
}


