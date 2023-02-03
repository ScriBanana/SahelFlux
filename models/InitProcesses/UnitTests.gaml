/**
* Name: UnitTests
* Based on the internal empty template. 
* Author: AS
* Tags: 
*/


model UnitTests

import "../Main.gaml"

/* Insert your model definition here */
global {
	action unitTests {
		
		// Main
		assert starting_date < endDate;
		
		// Parcel
		assert parcelRadiusDistri.value > 0.0 and parcelRadiusDistri.key >= 0.0;
	}
}
	