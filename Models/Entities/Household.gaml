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
	int nbBushFieldsPerHh <- 10; // TODO Dummy
	int nbHomeFieldsPerHh <- 2; // TODO Dummy
	
	int nbReserveDaysToTriggerTranshu <- 7; // Arbitrary
	
	//// Global households functions
	
	action instantiateHouseholds {
		write "Populating the village.";
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
		
		assert mobileHerd min_of each.herdSize > 0;
		write "	Done. " + length(household) + " households, " + length(mobileHerd) + " mobile herds, " +  length(household where each.isTranshumant) + " transhumants.";
	}
}

species household schedules: [] {
	
	//// Variables
	
	rgb householdColour;
	bool isTranshumant <- false;
	// Links to other agents
	list<parcel> myBushParcelsList;
	list<parcel> myHomeParcelsList;
	mobileHerd myMobileHerd;
	fattenedAnimal myFattenedAnimals;
	float myForagePileBiomassContent;
	ORPHeap myORPHeap;
	
	//// Functions
	
	action checkTranshuCondition {
		if (myForagePileBiomassContent + sumBiomassContent) / myMobileHerd.dailyIntakeRatePerHerd < nbReserveDaysToTriggerTranshu {
			write "" + myMobileHerd + " is leaving for transhumance.";
			ask transhumance {
				capture myself.myMobileHerd as: transhumingHerd;
			}
		}
	}
	
}

