/**
* In: SahelFlux
* Name: SupportFunctions
* Various support functions
* Author: Arthur Scriban (arthur.scriban@cirad.fr)
*/

model SahelFlux

global {
	rgb eucliClosestColour (rgb colourToCompare, list<rgb> colourPalette) {
	// Compares a colour (rgb) to those of a list of colours
	// and returns the index in the list of the closest colour (euclidian distance)
		rgb closestColour;
		float shortestDist <- 3 ^ (1 / 2) * 255.0;
		loop refColour over: colourPalette {
			float rgbEucliDist <- ((refColour.red - colourToCompare.red) ^ 2 + (refColour.green - colourToCompare.green) ^ 2 + (refColour.blue - colourToCompare.blue) ^ 2) ^ (1 / 2);
			if rgbEucliDist < shortestDist {
				shortestDist <- rgbEucliDist;
				closestColour <- refColour;
			}

		}

		return closestColour;
	}
	
	action progressionPrompt (int increment, int target, int promptIncrement) {
		// Insert in a loop or ask statement to display progress in the console
		// promptIncrement should be between 0 and 100 %
		if mod(increment, target / (100 / promptIncrement)) = 0 {
			write "	" + int(ceil(increment / target * 100)) + " %";
		}
	}
	
	string getCurrentTimeStamp {
		// Timestamp from current machine_time with YYMMDDhhmmss format
		string currentTimeStamp <- "";
		currentTimeStamp <- currentTimeStamp + (year(#now) - 2000);
		currentTimeStamp <- currentTimeStamp + (month(#now) < 10 ? "0" + month(#now) : month(#now));
		currentTimeStamp <- currentTimeStamp + (day(#now) < 10 ? "0" + day(#now) : day(#now));
		currentTimeStamp <- currentTimeStamp + (hour(#now) < 10 ? "0" + hour(#now) : hour(#now));
		currentTimeStamp <- currentTimeStamp + (minute(#now) < 10 ? "0" + minute(#now) : minute(#now));
		currentTimeStamp <- currentTimeStamp + (second(#now) < 10 ? "0" + second(#now) : second(#now));
		return currentTimeStamp;
	}

}
