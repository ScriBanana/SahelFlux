/**
* In: SahelFlux
* Name: ExpeRun
* Based on the internal empty template. 
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model ExpeRun

import "Main.gaml"

experiment run type:gui  {
	output {
		display mainDisplay type: java2D {
			grid landscape;
			species mobileHerd;
		}
	}
	
}