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
		list<landscape> availableCroplandCells <- landscape where (each.cellLU = "Cropland");
		int nbAvailableCells <- nil;
		
		// Checking cropland cells around the village to find a suitable parcel center
		// TODO try and get a way to have parcels with an even number of cells?
		loop while: nbAvailableCells != length(availableCroplandCells) {
			nbAvailableCells <- length(availableCroplandCells);
			
			list<landscape> croplandCells <- availableCroplandCells;
			loop cell over: shuffle(croplandCells) {
				if cell.myParcel = nil {
					if newParc >= nbCroplandParcels or empty(availableCroplandCells) {
						write "dada";
						break;
					}
	
					// Attributing a random parcel size
					float parcelSize <- -1.0;
					loop while: parcelSize / 2 < min(cellHeight, cellWidth) / 2 { // Avoid parcels smaller than a cell
						parcelSize <- gauss(meanParcelSize, SDParcelSize);
					}
	
					// Checking if neighbouring cells can be integrated into the parcel.
					if empty((cell neighbors_at (parcelSize / 2) where (each.myParcel != nil or each.cellLU != "Cropland"))) {
					// If all is green, create the parcel and assign its cells to it.
						create parcel {
							self.parcelColor <- rnd_color(255);
							landscape myCenterCell <- cell;
							location <- myCenterCell.location; // Necessary for at_distance
							ask landscape at_distance (parcelSize / 2) {
								self.myParcel <- myself;
								myself.myCells <+ self;
								availableCroplandCells >- self;
							}
						}
						
						newParc <- newParc + 1;
						if newParc mod int(nbCroplandParcels / 10) = 0 {
							write "		Placed : " + newParc + " parcels. (" + int(newParc / nbCroplandParcels * 100) + " %)";
						}
					}
				}
			}
		}
		write "		Placed : " + (newParc - 1) + " parcels. (Done)";
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

