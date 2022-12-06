/**
* In: SahelFlux
* Name: Landscape
* Based on the internal empty template. 
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Landscape

import "Parcel.gaml"
import "SOCstock.gaml"
import "SNstock.gaml"

global {
	int gridWidth <- 1;
	int gridHeight <- 1;
}

grid landscape width: gridWidth height: gridHeight parallel: true neighbors: 8 {
	
	// Part of a parcel
	parcel myParcel;
	// Internal N and C stock and processes
	SOCstock mySOCstock;
	SNstock mySNstock;
	
}

