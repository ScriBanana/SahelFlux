/**
* In: SahelFlux
* Name: TranshumanceAndFallows
* Controls transhumance and fallow transition for mobile herds
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model TranshumanceAndFallows

import "../../Main.gaml"

global {
	int nbReserveDaysToTriggerTranshu <- 7; // Arbitrary
	
	//// Transhumance transition functions
	action captureRemainingTranshumants {
		write "	Sending remaining transhuming herds to transhumance";
		
 		float leavingHerdNFlow <- mobileHerd where (each.myHousehold.isTranshumant) sum_of (each.herdSize * TLUNContent * weightTLU);
 		float leavingHerdCFlow <- mobileHerd where (each.myHousehold.isTranshumant) sum_of (each.herdSize  * TLUCContent * weightTLU);
 		ask world {	do saveFlowInMap("N", "MobileHerds", "OF-ToTranshu", leavingHerdNFlow);}
 		ask world {	do saveFlowInMap("C", "MobileHerds", "OF-ToTranshu", leavingHerdCFlow);}
 		
		ask transhumance {
			capture mobileHerd where (each.myHousehold.isTranshumant) as: transhumingHerd;
		}
	}
	
	//// Fallow transition functions
	
	action transitionToFallows {
		
		write "Restrincting remaining herds to fallows and contiguous rangelands.";
		
		// Restrict grazable area
		walkableLandscape <- nonEmptyLandscape where (
			each.cellLU = "Rangeland" or (each.cellLU = "Cropland" and (each.myParcel = nil or each.myParcel.nextRSCover = "Fallow"))
		);
		targetableCellsForChangingSite <- walkableLandscape where (each.myParcel != nil and each.myParcel.nextRSCover = "Fallow");
		
		// Moving herds
		list<parcel> fallowParcelsNotPaddockedList <- listAllBushParcels where (each.nextRSCover = "Fallow" and (each.myOwner = nil or each.myOwner.isTranshumant));
		ask mobileHerd where !(each.myHousehold.isTranshumant) { // Revamp condition (useless as of now) if additionnal cases emerge
			
			// Store paddocking data for next dry season
			lastDSPaddock <- currentPaddock;
			lastDSSleepSpot <- currentSleepSpot;
			lastDSNbNightInCurrentSleepSpot <- nbNightInCurrentSleepSpot;
			lastDSRemainingSleepSpots <- copy(remainingSleepSpots);
			lastDSPaddockList <- copy(myPaddockList);
			lastDSRemainingPaddocks <- copy(remainingPaddocks);
			
			// New paddocks attribution. Owner parcels first, then the rest
			myPaddockList <- [];
			list<parcel> myOwnerFallowParcels <- myHousehold.myBushParcelsList where (each.nextRSCover = "Fallow");
			if !empty(myOwnerFallowParcels) {
				myPaddockList <- maxNbFallowPaddock among myOwnerFallowParcels;
				fallowParcelsNotPaddockedList >>- myPaddockList;
			}
			if length(myPaddockList) < maxNbFallowPaddock { // Apparently loop times: 0 is a thing, but I'm too scared.
				if empty(fallowParcelsNotPaddockedList) {
					// Reset availiable parcels if need be. Several herds can end up in the same paddock.
					fallowParcelsNotPaddockedList <- listAllBushParcels where (each.nextRSCover = "Fallow" and (each.myOwner = nil or each.myOwner.isTranshumant));
				}
				loop times: maxNbFallowPaddock - length(myPaddockList) {
					myPaddockList <+ one_of(fallowParcelsNotPaddockedList);
					fallowParcelsNotPaddockedList >>- myPaddockList;
				}
			}
			remainingSleepSpots <- [];
			remainingPaddocks <- [];
			do resetSleepSpot;
			
			// Actual transition
			self.location <- currentSleepSpot.location;
			self.currentCell <- currentSleepSpot; // Probably not necessary.
		}
	}
	
	action transitionFromFallows {
		// Unrestrict grazable area
		walkableLandscape <- nonEmptyLandscape where (each.cellLU = "Cropland" or each.cellLU = "Rangeland");
		do updateTargetableCellsForChangingSiteInDS;
		
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
 		write "	Herds return from transhumance";
 		
 		float returningTranshumersNFlow <- transhumingHerd sum_of (each.herdSize * TLUNContent * weightTLU);
 		float returningTranshumersCFlow <- transhumingHerd sum_of (each.herdSize * TLUCContent * weightTLU);
 		ask world {	do saveFlowInMap("N", "MobileHerds", "IF-FromTranshu", returningTranshumersNFlow);}
 		ask world {	do saveFlowInMap("C", "MobileHerds", "IF-FromTranshu", returningTranshumersCFlow);}
 		
 		release list(transhumingHerd) as: mobileHerd {
 			myHousehold.myMobileHerd <- self;
 			location <- currentSleepSpot.location;
// 		chymeChunksList <- []; TODO temporary? As of now, they poop what they ate 4 months ago.
		}
 	}
 }
