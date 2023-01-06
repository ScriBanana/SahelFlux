/**
* In: SahelFlux
* Name: ComputeOutputs
* Soil organic carbon stock
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/


model ComputeOutputs

global {
	// Initialising matrixes
	int nbNflows <- 5; // Number of N flows in the stock-flows model
	matrix<float> NflowsMatrix <- {nbNflows, nbNflows + 3} matrix_with 0.0;
	
	int nbCflows <- 5; // Number of C flows in the stock-flows model
	matrix<float> CflowsMatrix <- {nbCflows, nbCflows + 3} matrix_with 0.0;
	
	
	// Compute global ENA indicators at the end of the simulation (Stark, 2016; Balandier, 2017, Latham, 2006)
	
	
	
}

