/**
* In: SahelFlux
* Name: Household
* Central entity owning animals, parcels and ORP heap
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Household

import "SpatialEntities/Parcel.gaml"
import "MobileHerd.gaml"
import "FattenedAnimal.gaml"
import "ORPHeap.gaml"
import "TranshumanceAndFallows.gaml"

global {
	
	//// Global households parameters
	
	int nbHousehold; // Parameter
	int nbTranshumantHh;
	int nbFatteningHh;
	int nbBushFieldsPerHh <- 10; // TODO Dummy
	int nbHomeFieldsPerHh <- 2; // TODO Dummy
	
	int nbReserveDaysToTriggerTranshu <- 7; // Arbitrary
	
	//// Global households functions
	
	action instantiateHouseholds {
		write "	Populating the village.";
		if nbHomeFieldsPerHh != 0 {
			assert length (parcel where (each.homeField)) > nbHomeFieldsPerHh * nbHousehold; // Tests if enough home parcels are available
		}
		create household number: nbHousehold {
			householdColour <- rnd_color(255);
			
			// Associating parcels
			ask nbHomeFieldsPerHh among (listAllHomeParcels where (each.myOwner = nil)) {
				self.myOwner <- myself;
				myOwner.myHomeParcelsList <+ self;
				self.parcelColour <- myself.householdColour;
			}
			ask nbBushFieldsPerHh among (listAllBushParcels where (each.myOwner = nil)) {
				self.myOwner <- myself;
				myOwner.myBushParcelsList <+ self;
				self.parcelColour <- myself.householdColour;
			}
			
			// Giving a mobile herd
			create mobileHerd with: [
				myHousehold::self,
				herdSize::round(abs(gauss(meanHerdSize - 1, SDHerdSize) + 1)),
				herdColour::self.householdColour
			] {	
				myHousehold.myMobileHerd <- self;
				// Paddocking initialisation
				myPaddockList <- copy(myHousehold.myHomeParcelsList);
				do resetSleepSpot;
				location <- currentSleepSpot.location;
			}
			
			// Assiciating an ORP heap
			create ORPHeap with: [myHousehold::self] {	
				myHousehold.myORPHeap <- self;
			}
		}
		ask nbTranshumantHh among household {
			isTranshumant <- true;
		}
		ask nbFatteningHh among household {
			doesFattening <- true;
			myMeanNbFattenedAnx <- abs(gauss(meanFattenedGroupSize, meanFattenedGroupSize * 0.2)) + 0.1; // TODO DUMMY 0.1 to avoid 0
		}
		ask household where each.doesFattening {
			do renewFattenedAnimals;
		}
		
		assert mobileHerd min_of each.herdSize > 0;
		write "		Done. " + length(household) + " households, " + length(mobileHerd) + " mobile herds, " +  length(household where each.isTranshumant) + " transhumants, " + length(household where each.isTranshumant) + " fatteners.";
	}
}

species household schedules: [] {
	
	//// Parameters and variables
	
	rgb householdColour;
	bool isTranshumant <- false;
	bool doesFattening <- false;
	
	// Links to other agents
	list<parcel> myBushParcelsList;
	list<parcel> myHomeParcelsList;
	ORPHeap myORPHeap;
	mobileHerd myMobileHerd;
	fattenedAnimal myFattenedAnimals;
	float myMeanNbFattenedAnx;
	
	// Variables
	float nbAnxSoldLastSeason;
	float myForagePileBiomassContent;
	
	//// Functions
	
	action checkTranshuCondition {
		if (myForagePileBiomassContent + (sumBiomassContent / nbHousehold)) / myMobileHerd.dailyIntakeRatePerHerd < nbReserveDaysToTriggerTranshu {
			write "	" + myMobileHerd + " is leaving for transhumance early."; // TODO remove after calibration
			
	 		float leavingHerdNFlow <- myMobileHerd.herdSize * TLUNcontent;
	 		float leavingHerdCFlow <- myMobileHerd.herdSize * TLUCcontent;
	 		ask world {	do saveFlowInMap("N", "MobileHerds", "OF-ToTranshu", leavingHerdNFlow);}
	 		ask world {	do saveFlowInMap("C", "MobileHerds", "OF-ToTranshu", leavingHerdCFlow);}
	 		
			ask transhumance {
				capture myself.myMobileHerd as: transhumingHerd;
			}
		}
	}
	
	action sellFattenedAnimals {
		if !empty(myFattenedAnimals) {
 			float soldFattenedNFlow <- myFattenedAnimals.groupSize * TLUNcontent;
	 		float soldFattenedCFlow <- myFattenedAnimals.groupSize * TLUCcontent;
	 		ask world {	do saveFlowInMap("N", "FattenedAn", "OF-SoldOnMarket", soldFattenedNFlow);}
	 		ask world {	do saveFlowInMap("C", "FattenedAn", "OF-SoldOnMarket", soldFattenedCFlow);}
	 		
	 		nbAnxSoldLastSeason <- myFattenedAnimals.groupSize;
	 		
	 		ask myFattenedAnimals {
	 			do die;
	 		}
		}
	}
	
	action renewFattenedAnimals {
 		float nbFatteningRenewal <- gauss(myMeanNbFattenedAnx, myMeanNbFattenedAnx * 0.2); // TODO DUMMY 0.2
 		nbFatteningRenewal <- nbFatteningRenewal * increaseNbTLUBoughtPerTLUSold * nbAnxSoldLastSeason / myMeanNbFattenedAnx;
 		if myForagePileBiomassContent != 0.0 and nbFatteningRenewal != 0.0 {
 			nbFatteningRenewal <- nbFatteningRenewal * min(0, max(1, 1 + 1 / myForagePileBiomassContent - 1 / (dailyIntakeRatePerTLU * nbFatteningRenewal * lengthFatteningSeason * 30))); // Doesn't take into account mobileherds
 		}
 		
		float boughtFattenedNFlow <- nbFatteningRenewal * TLUNcontent;
 		float boughtFattenedCFlow <- nbFatteningRenewal * TLUCcontent;
 		ask world {	do saveFlowInMap("N", "FattenedAn", "IF-FromMarket", boughtFattenedNFlow);}
 		ask world {	do saveFlowInMap("C", "FattenedAn", "IF-FromMarket", boughtFattenedCFlow);}
 		
 		create fattenedAnimal with: [
			myHousehold::self,
			groupSize::nbFatteningRenewal
 		] {
			myHousehold.myFattenedAnimals <- self;
 		}
	}
	
}

