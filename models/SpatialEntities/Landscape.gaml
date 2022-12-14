/**
* In: SahelFlux
* Name: Landscape
* Based on the internal empty template. 
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Landscape

import "../InitProcesses/ImportZoning.gaml"
import "Parcel.gaml"
import "SOCstock.gaml"
import "SNstock.gaml"

global {
	
	action drySeasonStartUpdateBiomassContent {
		//Updates biomass cotnent in cells at the start of the dry season
		
		write "Computing grazable biomass contents";
		loop cell over: landscape {
			
		}
	}
}

grid landscape width: gridWidth height: gridHeight parallel: true neighbors: 8 {
	
	// Land use
	string cellLU;
	// Part of a parcel
	parcel myParcel;
	// Internal N and C stock and processes
	SOCstock mySOCstock;
	SNstock mySNstock;
	
}

