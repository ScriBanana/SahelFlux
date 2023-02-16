/**
* In: SahelFlux
* Name: UnitTests
* Unit tests on input parameter
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model UnitTests

import "../Models/Main.gaml"

/* Insert your model definition here */
global {
	action inputUnitTests {
		
		// Main
		assert starting_date < endDate;
		assert lengthRainySeason > 0;
		
		// Parcel
		assert parcelRadiusDistri.value > 0.0 and parcelRadiusDistri.key >= 0.0;
		
	}
}
	