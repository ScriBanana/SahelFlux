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
		create household number: nbHousehold {
			// Associating parcels
			ask nbHomeFieldsPerHh among (parcel where (each.homeField and each.myOwner = nil)) {
				self.myOwner <- myself;
				myOwner.myHomeParcelsList <+ self;
			}
			ask nbBushFieldsPerHh among (parcel where (!each.homeField and each.myOwner = nil)) {
				self.myOwner <- myself;
				myOwner.myBushParcelsList <+ self;
			}
			// TODO Besoin à un moment de faire un truc pour matcher les nombres de parcelles et de parcelles par household.
			
			// TODO Désigner le premier paddock ici.
			
			// Giving a mobile herd
			create mobileHerd with: [
				myHousehold::self,
				herdSize::round(meanHerdSize)
			] {	
				myHousehold.myMobileHerd <- self;
				location <- (one_of(myHousehold.myHomeParcelsList)).location; // TODO remplacer par le paddock
			}
		}
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

