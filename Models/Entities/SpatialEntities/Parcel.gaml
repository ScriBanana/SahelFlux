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
	
	//// Global parcels parameters and variables
	
	int maxNbCroplandParcels <- 1000;
	pair<float, float> parcelRadiusDistri <- (100.0 #m)::(30.0 #m);
	float homeFieldsRadius <- 1200 #m; // Distance from village center TODO dummy
	bool fallowEnabled;
	
	// Variables
	list<parcel> listAllHomeParcels;
	list<parcel> listAllBushParcels;
	string parcelsAspect;
	
	//// Global parcels functions
	
	// Init functions
	
	action placeParcels {
		// Instantiate parcels
		write "	Cutting the territory into a maximum of " + maxNbCroplandParcels + " parcels.";

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
		write "		Done. " + length(parcel) + " parcels placed.";
	}
	
	action segregateBushFields {
		write "	Segregating bush and home fields.";
		
		ask first(landscape overlapping villageCenterPoint) neighbors_at (homeFieldsRadius) {
			ask parcel overlapping self {
				self.homeField <- true;
				parcelColour <- parcelColour / 1.6; // Arbitrary esthetic factor
				listAllHomeParcels <+ self;
				listAllBushParcels >- self;
			}
		}
		write "		Done. " + length(listAllHomeParcels) + " home parcels.";
	}
		
	action initiateRotations {
		ask parcel {
			if !fallowEnabled {
				myRotation <- homeField ? ["Millet"] : ["Millet", "Groundnut"];
				currentYearCover <- one_of(myRotation);
			} else {
				if homeField {
					myRotation <- ["Millet"];
					currentYearCover <- one_of(myRotation);
					coverColourMap[currentYearCover] <- coverColourMap[currentYearCover] / 1.05; // Arbitrary esthetic factor
				} else {
					myRotation <- ["Millet", "Groundnut", "Fallow"];
					float midXaxis <- centroid(world).x;
					float midYaxis <- centroid(world).y;
					// Divides the map into three quadrants, using the less flexible function to ever be written, because my last math lesson is far away
					if location.x < midXaxis and (location.y < - sqrt(3) * (location.x - midXaxis) + midYaxis) and (location.y > sqrt(3) * (location.x - midXaxis) + midYaxis) { // Ugly as all hell and an insult to my all my math teachers. Sorry.
						currentYearCover <- myRotation[0];
					} else if location.y < midYaxis {
						currentYearCover <- myRotation[1];
					} else {
						currentYearCover <- myRotation[2];
					}
				}
			}
			rotationLength <- length(myRotation);
		}
	}
	
	// State update functions
	
	action updateParcelsCovers {
		ask parcel {
			int coverIdInRot <- myRotation index_of currentYearCover;
			currentYearCover <- coverIdInRot >= rotationLength - 1 ? myRotation[0] : myRotation[coverIdInRot + 1];
		}
	}
	
}

species parcel parallel: true schedules: [] {
	
	//// Parameters
	
	list<landscape> myCells;
	household myOwner;
	bool homeField <- false;
	
	list<string> myRotation;
	int rotationLength;
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

