/**
* In: SahelFlux
* Name: Parcel
* Based on the internal empty template. 
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/
model Parcel

import "Landscape.gaml"

global {
	int maxNbCroplandParcels <- 10000;
	float meanParcelSize <- 100.0 #m; // 1 ha parcels TODO input data
	float SDParcelSize <- 30.0 #m; // Pour un effet avec des cellules de 50x50 m
	float homeFieldsRadius <- 1200 #m; // Distance from village center TODO dummy
	float homeParcelsDimmingFactor <- 1.6; // Mere esthetic parameter
	
	// Optimisation variables
	list<parcel> listAllHomeParcels;
	list<parcel> listAllBushParcels;
	
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
						parcelSize <- gauss(meanParcelSize, SDParcelSize);
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
}

species parcel parallel: true {
	list<landscape> myCells;
	household myOwner;
	bool homeField <- false;
	rgb parcelColour;
	aspect default {
		shape <- union(myCells);
		draw shape color: #transparent border: parcelColour;
	}
}

