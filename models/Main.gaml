/**
* In: SahelFlux
* Name: Main
* Model main file.
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SahelFlux

import "SpatialEntities/Landscape.gaml"
import "Agents/AnimalGroup.gaml"
import "ExpeRun.gaml"

global {
	init {
		write "MODEL INITIALISATION";
		do importRaster;
	}
	
}