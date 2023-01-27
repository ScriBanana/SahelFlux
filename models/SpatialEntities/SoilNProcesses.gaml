/**
* In: SahelFlux
* Name: SNstock
* Soil nitrogen stock
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model SoilNProcesses

import "Landscape.gaml"

global {
	matrix dungMineraPercentMatrix <- matrix([[0.6, 0.4, 0.0], [1.0, 0.0, 0.0], [0.4, 0.3, 0.3], [1.0, 0.0, 0.0]]); // N available over the years for : Dung, Urine, ORP, Mineral fertiliser
	
}

species soilNProcesses {
	landscape myCell;
	map<string, float> NInflows <- ["HerdsDung"::0.0, "HerdsUrine"::0.0, "ORP"::0.0, "MineralFerti"::0.0];
	
	action computeNAvailable {
		// TODO Virer les emissions
		
		//float NAvailable <- sum(NInflows);
	}
	
}


