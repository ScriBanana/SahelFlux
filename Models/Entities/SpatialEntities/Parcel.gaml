/**
* In: SahelFlux
* Name: Parcel
* Parcels
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/
model Parcel

import "Landscape.gaml"

global {
	
	//// Global parcels parameters and variables
	
	// Parameters
	point villageCenterPoint;
	float homeFieldsProportion;
	
	// Variables
	bool fallowEnabled;
	string parcelsAspect;
	list<int> parcelsIDList;
	list<parcel> listAllHomeParcels;
	list<parcel> listAllBushParcels;
	
	//// Global parcels functions
	
	// Init functions
	
	action placeParcels {
		write "Placing parcels according to input data.";
		
		list<int> createdParcelsIDList;
		ask (nonEmptyLandscape where (each.parcelID != 0)) sort_by each.parcelID {
			if (parcelID - 1) in createdParcelsIDList {
				ask parcel[parcelID - 1] {
					self.myCells <+ myself;
					myself.myParcel <- self;
				}
			} else {
				create parcel {
					self.myCells <+ myself;
					myself.myParcel <- self;
					createdParcelsIDList <+ int(self);
				}
			}
		}
		
		ask parcel {
			if enableDebug {assert length(myCells) != 0;}
			shape <- union(myCells);
			parcelSurface <- length(myCells) / hectareToCell; // shape.area ?
			listAllBushParcels <+ self;
			parcelColour <- #olive;
		}
		write "	Done. " + length(parcel) + " parcels placed.";
	}
	
	action designateHomeFields {
		write "Segregating bush and home fields.";
		
		ask household {
			loop times: round(homeFieldsProportion * length(self.myBushParcelsList)) {
				ask myBushParcelsList closest_to villageCenterPoint {
					listAllBushParcels >- self;
					myself.myBushParcelsList >- self;
					listAllHomeParcels <+ self;
					myself.myHomeParcelsList <+ self;
					self.homeField <- true;
					ask myCells {
						homefieldCell <- true;
						nbTrees <- nbTreesInitHomefields;
					}
					parcelColour <- parcelColour / 1.02; // Arbitrary esthetic factor
				}
				
				ask myORPHeap {
					nextSpreadParcelsOrder <- myself.myHomeParcelsList;
					parcelSpreadOn <- first(nextSpreadParcelsOrder);
				}
			}
		}
		
		write "	Done. " + length(listAllHomeParcels) + " home parcels.";
	}
		
	action initiateRotations {
		ask parcel {
			if homeField {
				myRotation <- ["Millet"];
				nextRSCover <- one_of(myRotation);
				lastRSCover <- one_of(myRotation);
				coverColourMap[nextRSCover] <- coverColourMap[nextRSCover] / 1.05; // Arbitrary esthetic factor
			} else {
				if !fallowEnabled {
					myRotation <- ["Millet", "Groundnut"];
					nextRSCover <- one_of(myRotation);
					lastRSCover <- nextRSCover = "Millet" ? "Groundnut" : "Millet";
				} else {
					myRotation <- ["Millet", "Groundnut", "Fallow"];
					float midXaxis <- centroid(world).x;
					float midYaxis <- centroid(world).y;
					// Divides the map into three quadrants, using the less flexible function to ever be written, because my last math lesson is far away
					if location.x < midXaxis and (
						location.y < - sqrt(3) * (location.x - midXaxis) + midYaxis
					) and (
						location.y > sqrt(3) * (location.x - midXaxis) + midYaxis
					) { // Ugly as all hell and an insult to my all my math teachers. Sorry.
						nextRSCover <- myRotation[0];
						lastRSCover <- myRotation[2];
					} else if location.y < midYaxis {
						nextRSCover <- myRotation[1];
						lastRSCover <- myRotation[0];
					} else {
						nextRSCover <- myRotation[2];
						lastRSCover <- myRotation[1];
					}
				}
			}
		}
	}
	
	// State update functions
	
	action updateParcelsCovers {
		ask parcel {
			int coverIdInRot <- myRotation index_of nextRSCover;
			lastRSCover <- nextRSCover;
			nextRSCover <- coverIdInRot >= length(myRotation) - 1 ? myRotation[0] : myRotation[coverIdInRot + 1];
		}
	}
	
}

species parcel parallel: true schedules: [] {
	
	//// Parameters
	
	list<landscape> myCells;
	float parcelSurface; // ha
	
	household myOwner;
	bool homeField;
	
	list<string> myRotation;
	string nextRSCover;
	string lastRSCover;
	
	rgb parcelColour;
	map<string, rgb> coverColourMap <- ["Millet"::#yellow, "Groundnut"::#brown, "Fallow"::#green];
	aspect default {
		switch parcelsAspect {
			match "Owner" {
				draw shape color: #transparent border: parcelColour;
			}
			match "Cover" {
				draw shape color: #transparent border: coverColourMap[nextRSCover];
			}
		}
	}
}

