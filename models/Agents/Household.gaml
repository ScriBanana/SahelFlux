/**
* In: SahelFlux
* Name: Household
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
* Tags: 
*/


model Household

import "../SpatialEntities/Parcel.gaml"
import "Household.gaml"
import "AnimalGroup.gaml"
import "ORPHeap.gaml"

global {
	
	int nbHousehold <- 84; // TODO Dummy
	int nbBushFieldsPerHh <- 4; // TODO Dummy
	int nbHomeFieldsPerHh <- 2; // TODO Dummy
	
	action instantiateHouseholds {
		write "Populating the village.";
		assert length (parcel where (each.homeField)) > nbHomeFieldsPerHh * nbHousehold; // Tests if enough home parcels are available
		create household number: nbHousehold {
			// Associating parcels
			ask nbHomeFieldsPerHh among (listAllHomeParcels where (each.myOwner = nil)) {
				self.myOwner <- myself;
				myOwner.myHomeParcelsList <+ self;
			}
			ask nbBushFieldsPerHh among (listAllBushParcels where (each.myOwner = nil)) {
				self.myOwner <- myself;
				myOwner.myBushParcelsList <+ self;
			}
						
			// Giving a mobile herd
			create mobileHerd with: [
				myHousehold::self,
				herdSize::round(meanHerdSize)
			] {	
				myHousehold.myMobileHerd <- self;
				myPaddock <- (one_of(myHousehold.myHomeParcelsList));
				location <- myPaddock.location;
			}
		}
		write "	Done. " + length(household) + " households, " + length(mobileHerd) + " mobile herds.";
	}
}

species household {
	
	// Links to other agents
	list<parcel> myBushParcelsList;
	list<parcel> myHomeParcelsList;
	mobileHerd myMobileHerd;
	fattenedAnimal myFattenedAnimals;
	float foragePile;
	ORPHeap myORPHeap;
	
}

