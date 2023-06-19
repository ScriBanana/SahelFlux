/**
* In: SahelFlux
* Name: HeadlessRuns
* Fast or long experiments for testing or specific DOE
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model HeadlessRuns

import "../Main.gaml"

experiment FastAutoRun autorun: true {
	// 3 month short auto run 
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold <- 10 min: 0 updates: [nbTranshumantHh, nbFatteningHh];
	parameter "Number transhuming households" category: "Scenario - Population structure" var: nbTranshumantHh <- 5 min: 0 max: nbHousehold;
	parameter "Number fattening households" category: "Scenario - Population structure" var: nbFatteningHh <- 5 min: 0 max: nbHousehold;
	parameter "Short run start date" var: starting_date <- date([2020, 4, 10, eveningTime + 1, 0, 0]);
	parameter "Short run end date" var: endDate <- date([2020, 7, 1, eveningTime + 1, 0, 0]);
}

experiment LongRun {
	// 20 year run that records output matrixes each month
	parameter "Long run start date" category: "Scenario - Time" var: starting_date;
	parameter "Long run end date" category: "Scenario - Time" var: endDate <- date([2040, 11, 1, eveningTime + 1, 0, 0]);
	
	parameter "Enable fallow (3-years rotation)" category: "Scenario - Spatial layout" var: fallowEnabled <- false;
	parameter "Number households and mobile herds" category: "Scenario - Population structure" var: nbHousehold <- 50 min: 0;// updates: [nbTranshumantHh, nbFatteningHh];
//	parameter "Number transhuming households" category: "Scenario - Population structure" var: nbTranshumantHh <- 10 min: 0 max: nbHousehold;
//	parameter "Number fattening households" category: "Scenario - Population structure" var: nbFatteningHh <- 10 min: 0 max: nbHousehold;
	
	reflex monthlyOutputSave when: current_date != (starting_date add_hours 1) and (current_date.day = 1 and updateTimeOfDay) {
		ask simulation {
			do saveOutputsDuringSim;
		}
	}
}

