/**
* In: SahelFlux
* Name: Transhumance
* Controls transhumance for mobile herds
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model Transhumance

import "MobileHerd.gaml"

// Macro-species that captures (in Household.gaml) mobileHerds and stores them until they come back, at the end of the rainy season.
 species transhumance schedules: [] {
 	species transhumingHerd parent: mobileHerd schedules: [];
 	action returnHerdsToLandscape {
 		write "Herds return from transhumance";
 		release list(transhumingHerd) as: mobileHerd {
 			location <- currentSleepSpot.location;
 			chymeChunksList <- [];
		}
 	}
 }
