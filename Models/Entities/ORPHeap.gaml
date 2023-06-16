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
	
	float heapCH4ToBeEmittedInRainySeason; // kgC
	float heapGasLossNToEmitInRS; // kgN TODO emit at some point (register in matrix?)
	
	list<parcel> nextSpreadParcelsOrder; // = myHomeParcelsList, but rotates
	parcel parcelSpreadOn;
	float ORPSpreadOnCurrentParcel <- 0.0; // kgDM
	
	//// Functions
	
	action addWastes {
		float ORPAccumulationPeriodLength <- (current_date - lastORPAddition) / 86400; // Converted in days TODO utiliser time
		float wastesNAddition <- (kitchenWastesNInputRate + otherWastesInputRate * otherWastesNContent) * ORPAccumulationPeriodLength;
		float wastesCAddition <- (
			kitchenWasteInputRate * kitchenWastesCContent + otherWastesInputRate * otherWastesCContent
		) * ORPAccumulationPeriodLength;
		
		float emittedN2OFromWastesAddition <- wastesNAddition * emissionFactorN2OInHeap; // kgN
		
		ask world {	do saveFlowInMap("N", "Households", "TF-ToORPHeaps" , wastesNAddition);}
		ask world {	do saveFlowInMap("C", "Households", "TF-ToORPHeaps" , wastesCAddition);}
		ask world {	do saveFlowInMap("N", "HomeFields", "OF-GHG" , emittedN2OFromWastesAddition);}
		
		heapQuantity <- heapQuantity + (kitchenWasteInputRate + otherWastesInputRate) * ORPAccumulationPeriodLength;
		heapNContent <- heapNContent + wastesNAddition;
		heapCContent <- heapCContent + wastesCAddition;
	}
	
	action accumulateFattenedInputs {
		loop dungDeposit over: heapFattenedInput {
			
			// Compute CH4 emissions
			float futureCH4Emission <- methaneProdFromManure * methaneConversionFactorORPPile * float(dungDeposit[0]); // kgCH4
			heapCH4ToBeEmittedInRainySeason <- heapCH4ToBeEmittedInRainySeason + futureCH4Emission;
			
			// Compute N2O emissions
			float emittedN2OFromFattenedInput <- (float(dungDeposit[2]) + float(dungDeposit[3])) * emissionFactorN2OInHeap; // kgN
			ask world {	do saveFlowInMap("N", "ORPHeaps", "OF-GHG" , emittedN2OFromFattenedInput);}
			
			// Compute NOx gas losses
			float lostNGasFromFattenedInput <- (float(dungDeposit[2]) + float(dungDeposit[3])) * fractionGasLossORPHeap; // kgN
			heapGasLossNToEmitInRS <- heapGasLossNToEmitInRS + lostNGasFromFattenedInput;
			ask world {	do saveFlowInMap("N", "ORPHeaps", "OF-AtmoLosses" , lostNGasFromFattenedInput);}
			
			// Balance balances
			heapQuantity <- heapQuantity + float(dungDeposit[0]) - futureCH4Emission;
			manureInHeap <- manureInHeap + float(dungDeposit[0]) - futureCH4Emission;
			heapCContent <- heapCContent + min(0, float(dungDeposit[1]) - futureCH4Emission * coefCH4ToC);
			// Wastes don't contribute to CH4 emissions, then. They are just added to soils C stock.
			heapNContent <- heapNContent + min(
				0,
				float(dungDeposit[2]) + float(dungDeposit[3]) - emittedN2OFromFattenedInput - lostNGasFromFattenedInput
			); // Mins mathematically useless, but, oh well, who doesn't fancy failsafes...
			
			// Refusals - No emissions ?
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
			ORPSpreadOnCurrentParcel <- 0.0;
		}
		
		float spreadORPQuantity <- heapQuantity > maxManureCartWeight ? maxManureCartWeight : heapQuantity;
		float spreadManureInSpreadORPQuantity <- (manureInHeap / heapQuantity) * spreadORPQuantity;
		float spreadCQuantity <- heapQuantity / spreadORPQuantity * heapCContent;
		float spreadNQuantity <- heapQuantity / spreadORPQuantity * heapNContent;
				
		// Emit N gases
		// N2O direct
		float spreadORPNDirectN2OEmissions <- spreadNQuantity * emissionFactorN2ODeposits; // kgN
		ask world {	do saveFlowInMap("N", "HomeFields", "OF-GHG" , spreadORPNDirectN2OEmissions);}
		
		// Indirect RS
		float spreadORPNGasLoss <- spreadNQuantity * fractionGasLossOrganicFerti; // kgN
		ask world {	do saveFlowInMap("N", "HomeFields", "OF-AtmoLosses" , spreadORPNGasLoss);}
		
		float incorporatedN <- spreadNQuantity - (spreadORPNDirectN2OEmissions + spreadORPNGasLoss);
		
		// Save flows in the parcel's cells
		int nbSpreadCells <- length(parcelSpreadOn.myCells);
		ask parcelSpreadOn.myCells {
			// Add carbon and manure for CH4 emissions
			mySOCstock.carbonInputsList <+ [
				"ORP", spreadManureInSpreadORPQuantity / nbSpreadCells, spreadCQuantity / nbSpreadCells
			];
			
			// Incorporate non-emitted N
			mySoilNProcesses.NInflows["ORP"] <- mySoilNProcesses.NInflows["ORP"] + incorporatedN / nbSpreadCells;
			// And gas losses for RS
			mySoilNProcesses.soilGasLossNToEmitInRS <- mySoilNProcesses.soilGasLossNToEmitInRS + spreadORPNGasLoss / nbSpreadCells;
		}
		
		ask world {	do saveFlowInMap("C", "ORPHeaps", "TF-ToHomeFields" , spreadCQuantity);}
		ask world {	do saveFlowInMap("N", "ORPHeaps", "TF-ToHomeFields" , incorporatedN);}
		
		// Add quantity for parcel rotation
		ORPSpreadOnCurrentParcel <- ORPSpreadOnCurrentParcel + spreadORPQuantity;
		
		// Balance balances
		heapQuantity <- heapQuantity - spreadORPQuantity;
		manureInHeap <- manureInHeap - spreadManureInSpreadORPQuantity;
		heapCContent <- heapCContent - spreadCQuantity;
		heapNContent <- heapNContent - spreadNQuantity;
	}
	
}


