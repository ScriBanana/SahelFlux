/**
* In: SahelFlux
* Name: Parcel
* Based on the internal empty template. 
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/
model Parcel

import "Landscape.gaml"

global {
	int nbCroplandParcels <- 600;
	float meanParcelSize <- 100.0 #m; // 1 ha parcels TODO input data
	float SDParcelSize <- 50.0 #m; // Pour un effet avec des cellules de 50x50 m
	
	action placeParcels {
		
		// Instantiate parcels
		write "Cutting the territory into a maximum of " + nbCroplandParcels + " parcels.";
		
		int newParc <- 0;
		
		loop while: newParc < nbCroplandParcels {
			// Checking cropland cells around the village to find a suitable parcel center
			// TODO try and get a way to have even sized parcels?
			loop cell over: shuffle(landscape where (each.cellLU = "Cropland")) {
				if cell.myParcel = nil {
					if newParc >= nbCroplandParcels { // Sadly needed
						break;
					}
					
					// Attributing a random parcel size
					float parcelSize <- -1.0;
					loop while: parcelSize / 2 < min(cellHeight, cellWidth) / 2 { // Avoid parcels smaller than a cell
						parcelSize <- gauss(meanParcelSize, SDParcelSize);
					}
					
					// Checking if neighbouring cells can be integrated into the parcel.
					if empty((cell neighbors_at (parcelSize / 2) where (each.myParcel != nil or each.cellLU !=
					"Cropland"))) {
						// If all is green, create the parcel and assign its cells to it.
						create parcel {
							landscape myCenterCell <- cell;
							location <- myCenterCell.location;
							ask landscape at_distance (parcelSize / 2) {
								self.myParcel <- myself;
								myself.myCells <+ self;
							}
							self.parcelColor <- rnd_color(255);
						}
						newParc <- newParc + 1;
						if newParc mod int(nbCroplandParcels/10) = 0 {
							write "		Placed : " + newParc + " parcels. (" + int(newParc/nbCroplandParcels*100) + " %)";
						}
					}
				}
			}
			if empty(landscape where (each.cellLU = "Cropland" and each.myParcel = nil)) {
				write "Not enough space to fit all parcels. Parcels placed : " + newParc;
				break;
			}
		}
	}
}

species parcel parallel: true {
	list<landscape> myCells;
	rgb parcelColor;
	aspect default {
		ask myCells {
			draw rectangle(cellWidth, cellHeight) color: #transparent border: myself.parcelColor;
		}
	}
}

