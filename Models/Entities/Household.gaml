/**
* In: SahelFlux
* Name: Household
* Central entity owning animals, parcels and ORP heap
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Household

import "../../Utilities/CnNFlowsParameters.gaml"
import "SpatialEntities/Parcel.gaml"
import "MobileHerd.gaml"
import "FattenedAnimal.gaml"
import "ORPHeap.gaml"
import "TranshumanceAndFallows.gaml"

global {
	
	//// Global households parameters
	
	int nbHousehold <- 84; // Parameter
	int nbTranshumantHh <- 45;
	int nbFatteningHh <- 30;
	int nbBushFieldsPerHh <- 10; // TODO Dummy
	int nbHomeFieldsPerHh <- 2; // TODO Dummy
	
	int nbReserveDaysToTriggerTranshu <- 7; // Arbitrary
	
	float meanForagePileBiomassContent <- 300.0; // kgDM TODO DUMMY
	
	//// Global households functions
	
	action instantiateHouseholds {
		write "Populating the village.";
		if nbHomeFieldsPerHh != 0 {
			assert length (parcel where (each.homeField)) > nbHomeFieldsPerHh * nbHousehold; // Tests if enough home parcels are available
		}
		create household number: nbHousehold {
			myForagePileBiomassContent <- gauss(meanForagePileBiomassContent, meanForagePileBiomassContent * 0.1);
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
				nextSpreadParcelsOrder <- myself.myHomeParcelsList;
				parcelSpreadOn <- first(nextSpreadParcelsOrder);
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
		write "	Done. " + length(household) + " households, " + length(mobileHerd) + " mobile herds, " +  length(household where each.isTranshumant) + " transhumants, " + length(household where each.doesFattening) + " fatteners.";
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
			
	 		float leavingHerdNFlow <- myMobileHerd.herdSize * TLUNContent * weightTLU;
	 		float leavingHerdCFlow <- myMobileHerd.herdSize * TLUCContent * weightTLU;
	 		ask world {	do saveFlowInMap("N", "MobileHerds", "OF-ToTranshu", leavingHerdNFlow);}
	 		ask world {	do saveFlowInMap("C", "MobileHerds", "OF-ToTranshu", leavingHerdCFlow);}
	 		
			ask transhumance {
				capture myself.myMobileHerd as: transhumingHerd;
			}
		}
	}
	
	action sellFattenedAnimals {
		if !dead(myFattenedAnimals){
 			float soldFattenedNFlow <- myFattenedAnimals.groupSize * ratioWeightSoldOnBought * TLUNContent * weightTLU;
	 		float soldFattenedCFlow <- myFattenedAnimals.groupSize * ratioWeightSoldOnBought * TLUCContent * weightTLU;
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
// 		nbFatteningRenewal <- nbFatteningRenewal * increaseNbTLUBoughtPerTLUSold * nbAnxSoldLastSeason / myMeanNbFattenedAnx;
 		if
	 		myForagePileBiomassContent != 0.0 and
	 		nbFatteningRenewal != 0.0 and
	 		2 - 2 * myForagePileBiomassContent / (strawInFattenedTLUDailyRation * nbFatteningRenewal * lengthFatteningSeason) > 0
 		{
 			nbFatteningRenewal <- nbFatteningRenewal * max(
 				0,
 				min(1,
 					-log(2 - 2 * myForagePileBiomassContent / (strawInFattenedTLUDailyRation * nbFatteningRenewal * lengthFatteningSeason))
 				)
 			); // Doesn't take into account mobileherds
 		}
 		nbFatteningRenewal <- floor(nbFatteningRenewal * 100) / 100; // Less decimals
 		
 		if nbFatteningRenewal > 0.0 {
			float boughtFattenedNFlow <- nbFatteningRenewal * TLUNContent * weightTLU;
	 		float boughtFattenedCFlow <- nbFatteningRenewal * TLUCContent * weightTLU;
	 		ask world {	do saveFlowInMap("N", "FattenedAn", "IF-FromMarket", boughtFattenedNFlow);}
	 		ask world {	do saveFlowInMap("C", "FattenedAn", "IF-FromMarket", boughtFattenedCFlow);}
	 		
	 		create fattenedAnimal with: [
				myHousehold::self,
				groupSize::nbFatteningRenewal,
				chymeChunksList::[]
	 		] {
				myHousehold.myFattenedAnimals <- self;
	 		}
 		}
	}
	
}

