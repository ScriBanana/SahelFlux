/**
* In: SahelFlux
* Name: TranshumanceAndFallows
* Controls transhumance and fallow transition for mobile herds
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model TranshumanceAndFallows

import "MobileHerd.gaml"

global {
	
	//// Fallow transition functions
	
	action transitionToFallows {
		write "Restrincting remaining herds to fallows and contiguous rangelands.";
		// Restrict grazable area
		grazableLandscape <- landscape where (each.cellLU = "Rangeland" or (each.cellLU = "Cropland" and (each.myParcel = nil or each.myParcel.currentYearCover = "Fallow")));
		targetableCellsForChangingSite <- landscape where (each.myParcel != nil and each.myParcel.currentYearCover = "Fallow");
		
		list<parcel> fallowParcelNotPaddocks <- listAllBushParcels where (each.currentYearCover = "Fallow" and (each.myOwner = nil or each.myOwner.isTranshumant));
		
		ask mobileHerd where !(each.myHousehold.isTranshumant) {
			
			// Store paddocking data for next dry season
			lastDSPaddock <- currentPaddock;
			lastDSSleepSpot <- currentSleepSpot;
			lastDSNbNightInCurrentSleepSpot <- nbNightInCurrentSleepSpot;
			lastDSRemainingSleepSpots <- copy(remainingSleepSpots);
			lastDSPaddockList <- copy(myPaddockList);
			lastDSRemainingPaddocks <- copy(remainingPaddocks);
			
			// Transition to fallow
			if !empty(myHousehold.myBushParcelsList where (each.currentYearCover = "Fallow")) {
				myPaddockList <- maxNbFallowPaddock among (myHousehold.myBushParcelsList where (each.currentYearCover = "Fallow"));
				fallowParcelNotPaddocks >>- myPaddockList;
			}
			if length(myPaddockList) < maxNbFallowPaddock { // Apparently loop times: 0 is a thing, but I'm too scared.
				loop times: maxNbFallowPaddock - length(myPaddockList) {
					myPaddockList <+ one_of(fallowParcelNotPaddocks); // TODO dummy and can still cause trouble if several herds get tied to the same parcel
					fallowParcelNotPaddocks >>- myPaddockList;
				}
			}
			
			remainingSleepSpots <- [];
			remainingPaddocks <- [];
			do resetSleepSpot;
			self.location <- currentSleepSpot.location;
			self.currentCell <- currentSleepSpot;
		}
	}
	
	action transitionFromFallows {
		// Unrestrict grazable area
		grazableLandscape <- landscape where (each.cellLU = "Cropland" or each.cellLU = "Rangeland");
		targetableCellsForChangingSite <- landscape where (each.cellLU = "Rangeland");
		
		ask mobileHerd where !(each.myHousehold.isTranshumant) {
			// Set paddocking variable to those of the last dry season
			currentPaddock <- lastDSPaddock;
			currentSleepSpot <- lastDSSleepSpot;
			nbNightInCurrentSleepSpot <- lastDSNbNightInCurrentSleepSpot;
			remainingSleepSpots <- lastDSRemainingSleepSpots;
			myPaddockList <- lastDSPaddockList;
			remainingPaddocks <- lastDSRemainingPaddocks;
		}
	}
}


// Macro-species that captures (in Household.gaml) mobileHerds and stores them until they come back, at the end of the rainy season.
 species transhumance {
 	
 	species transhumingHerd parent: mobileHerd schedules: [];
 	
 	action returnHerdsToLandscape {
 		write "Herds return from transhumance";
 		release list(transhumingHerd) as: mobileHerd {
 			myHousehold.myMobileHerd <- self;
 			location <- currentSleepSpot.location;
// 			chymeChunksList <- []; TODO temporary?
		}
 	}
 }
