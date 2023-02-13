/**
* In: SahelFlux
* Name: Parcel
* Parcels
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/
model Parcel

import "Landscape.gaml"
import "../Household.gaml"

global {
	
	//// Global parcels parameters
	
	int maxNbCroplandParcels <- 10000;
	pair<float, float> parcelRadiusDistri <- (100.0 #m)::(30.0 #m);
	float homeFieldsRadius <- 1200 #m; // Distance from village center TODO dummy
	float homeParcelsDimmingFactor <- 1.6; // Mere esthetic parameter
	
	// Variables
	list<parcel> listAllHomeParcels;
	list<parcel> listAllBushParcels;
	string parcelsAspect;
	
	//// Global parcels functions
	
	action placeParcels {		
		// Instantiate parcels
		write "Cutting the territory into a maximum of " + maxNbCroplandParcels + " parcels.";

		int newParc <- 0;
		list<landscape> availableCroplandCells <- landscape where (each.cellLU = "Cropland");
		int nbAvailableCells <- nil;
	
		//TODO : needs revamp for full coverage and better shapes		
		loop while: nbAvailableCells != length(availableCroplandCells) {
			nbAvailableCells <- length(availableCroplandCells);
			
			list<landscape> croplandCells <- availableCroplandCells;
			loop cell over: shuffle(croplandCells) {
				if cell.myParcel = nil {
					if newParc >= maxNbCroplandParcels {
						break; // Not the most elegant
					} else if empty(availableCroplandCells) {
						break;
					}
	
					// Attributing a random (positive) parcel size
					float parcelSize <- -1.0;
					loop while: parcelSize < 0.0 {
						parcelSize <- gauss(parcelRadiusDistri.key, parcelRadiusDistri.value);
					}
					
					// Checking if neighbouring cells can be integrated into the parcel.
					if parcelSize / 2 < min(cellHeight, cellWidth) / 2 or empty(cell neighbors_at (parcelSize / 2) where (each.myParcel != nil or each.cellLU != "Cropland")) {
					// If all is green, create the parcel and assign its cells to it.
						create parcel {
							self.parcelColour <- #olive;
							landscape myCenterCell <- cell;
							myCenterCell.myParcel <- self;
							self.myCells <+ myCenterCell;
							location <- myCenterCell.location;
							if parcelSize / 2 >= min(cellHeight, cellWidth) / 2 {
								ask myCenterCell neighbors_at (parcelSize / 2) {
									self.myParcel <- myself;
									myself.myCells <+ self;
									availableCroplandCells >- self;
								}
							}
						}
						
						newParc <- newParc + 1;
					}
				}
			}
		}
		listAllBushParcels <- copy(list(parcel));
		write "	Done. " + length(parcel) + " parcels placed.";
	}
	
	action segregateBushFields {
		write "Segregating bush and home fields.";
		
		ask first(landscape overlapping villageCenterPoint) neighbors_at (homeFieldsRadius) {
			ask parcel overlapping self {
				self.homeField <- true;
				self.parcelColour <- self.parcelColour / homeParcelsDimmingFactor;
				listAllHomeParcels <+ self;
				listAllBushParcels >- self;
			}
		}
		write "	Done. " + length(listAllHomeParcels) + " home parcels.";
	}
	
	action initiateRotations {
		ask parcel {
			myRotation <- homeField ? ["Millet"] : (partOfFallow ? ["Millet", "Groundnut", "Fallow"] : ["Millet", "Groundnut"]);
			currentYearCover <- one_of(myRotation);
		}
	}
}

species parcel parallel: true schedules: [] {
	
	//// Parameters
	
	list<landscape> myCells;
	household myOwner;
	bool homeField <- false;
	bool partOfFallow <- false;
	
	list<string> myRotation;
	string currentYearCover;
	
	rgb parcelColour;
	map<string, rgb> coverColourMap <- ["Millet"::#yellow, "Groundnut"::#brown, "Fallow"::#green];
	aspect default {
		shape <- union(myCells);
		switch parcelsAspect {
			match "Owner" {
				draw shape color: #transparent border: parcelColour;
			}
			match "Cover" {
				draw shape color: #transparent border: coverColourMap[currentYearCover];
			}
		}
	}
}

