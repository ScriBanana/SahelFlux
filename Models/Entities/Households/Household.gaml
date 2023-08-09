/**
* In: SahelFlux
* Name: Household
* Central entity owning animals, parcels and ORP heap
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "../../Main.gaml"
import "ORPHeap.gaml"

global {
	
	//// Global households parameters
	
	int nbHousehold;
	float propTranshumantHh min: 0.0 max: 1.0;
	float propFatteningHh min: 0.0 max: 1.0;
	int nbTranshumantHh;
	int nbFatteningHh;
	
	float meanForagePileBiomassContent <- 300.0 const: true; // kgDM TODO DUMMY
	
	//// Global households functions
	
	action instantiateHouseholds {
		write "Populating the village.";
		
		int minNbParcelPerHousehold <- floor(length(parcel) / nbHousehold);
		
		create household number: nbHousehold with: [householdColour::rnd_color(255)] {
			myForagePileBiomassContent <- gauss(
				meanForagePileBiomassContent, meanForagePileBiomassContent * 0.1
			);
			
			// Associating parcels
			ask minNbParcelPerHousehold among shuffle(listAllBushParcels where (each.myOwner = nil)) {
				self.myOwner <- myself;
				myOwner.myBushParcelsList <+ self;
				self.parcelColour <- myself.householdColour;
			}
			
			// Assiciating an ORP heap
			create ORPHeap with: [myHousehold::self] {	
				myHousehold.myORPHeap <- self;
			}
		}
		
		// Associate the remaining parcels
		if !empty(listAllBushParcels where (each.myOwner = nil)) {
			ask listAllBushParcels where (each.myOwner = nil) {
				ask one_of(household where (length(each.myBushParcelsList) = minNbParcelPerHousehold)) {
					myself.myOwner <- self;
					myBushParcelsList <+ myself;
					myself.parcelColour <- self.householdColour;
				}
			}
		}
		
		ask nbTranshumantHh among household {
			isTranshumant <- true;
		}
		
		ask nbFatteningHh among household {
			doesFattening <- true;
			myMeanNbFattenedAnx <- abs(gauss(meanFattenedGroupSize, meanFattenedGroupSize * 0.2) with_precision 3) + 0.1;// avoids 0
			do renewFattenedAnimals;
		}
		
		write "	Done. " + length(household) + " households, "
			+  length(household where each.isTranshumant) + " transhumants, "
			+ length(household where each.doesFattening) + " fatteners."
		;
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
		if
			(myForagePileBiomassContent + (sumBiomassContent / nbHousehold)) / myMobileHerd.dailyIntakeRatePerHerd <
			nbReserveDaysToTriggerTranshu
		{
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
 		nbFatteningRenewal <- nbFatteningRenewal  with_precision 2;
 		
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

