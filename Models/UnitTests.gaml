/**
* In: SahelFlux
* Name: UnitTests
* Unit tests on input parameter
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "Main.gaml"

global {
	action inputUnitTests {
		
		// Main
		assert starting_date < endDate;
		assert lengthRainySeason > 0;
		
		// Households
		assert nbHousehold >= nbTranshumantHh;
		
	}
}
	