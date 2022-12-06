/**
* In: SahelFlux
* Name: Parcel
* Based on the internal empty template. 
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model Parcel

import "Landscape.gaml"

species parcel parallel: true {
	list<landscape> myCells;
	
}

