// This file is available from https://github.com/GloverLab/SpotCard

// If you want to extract date, time and GPS from the image you'll need the EXIF reader plugin
// It can be found at https://imagej.nih.gov/ij/plugins/exif-reader.html

// GPS additionally requires a GPS-enabled camera. iPhone is GPS enabled, but if you import images into Photos
// and then drag them from there into another folder it strips the GPS data. Instead, select the images 
// you want, then File, Export; you can choose to include location information. 

// Setup options - set them here if you want to hard-code them
// This can be useful for testing purposes
configurationFile = "" // getDirectory("home") + "Desktop/2018-07-06-280.txt"; 
outputOption = "" // "Create new CSV";
outputFile = "" // getDirectory( "home" ) + "Desktop/batch.txt" ;
imageFolder = "" // getDirectory( "home" ) + "Desktop/p/" ;

// From where do you want to start and end? FromImage is zero-based; set toImage to -1 to process all images in the folder. 
// This is useful if you want to try the macro on a couple of images, rather than the whole lot. 
fromImage = 0;
toImage = -1;

// If the images we're processing don't have lat and long info in them, then it's useful to show a message about this -
// It's easy to forget to export them with the info in, and if you're processing lots of images you'll only discover
// you've forgotten them when you look at the data after spending a while processing them! 
// But I only want to show the warning once, so we need a flag which says if we've shown it. 
shownLatLongWarning = false;

// Do you want to do flower area and perimeter as well?
measureFlower = false;

// ---- SETUP PHASE ---- //

// Choose the configuration file and parse it
if( configurationFile == "" ) {
	showMessage( "Choose the configuration file (.txt) for this card" );
	configurationFile = File.openDialog( "Choose the configuration file (.txt) for this card" ); ;
	while( !endsWith( configurationFile, ".txt" ) ){
		showMessage( "The configuration file needs to be a .txt file. Please try again." );
		configurationFile = File.openDialog( "Choose the configuration file (.txt) for this card" ); 
	}
}

fileContents  = File.openAsString( configurationFile ); 
rows = split( fileContents, "\n" );
if( rows.length != 13 ) {
	exit( "The configuration file needs to have exactly thirteen lines." );
}

// Split the configuration file into its component parts
spotsX = split( rows[ 0 ], ",," );
spotsY = split( rows[ 1 ], ",," );
spotWidth = parseInt( rows[ 2 ] );
spotHeight = parseInt( rows[ 3 ] );
flowerDiameter = parseInt( rows[ 4 ] );
flowerPadding = parseInt( rows[ 5 ] );
spotsValue = split( rows[ 6 ], ",," );
spotsCategory = split( rows[ 7 ], ",," );
originalWidth = parseInt( rows[ 8 ] );
originalHeight = parseInt( rows[ 9 ] );
flowerCentroidY = parseInt( rows[ 10 ] );
pixelsPerMM = parseInt( rows[ 11 ] );
cornerDotColour = rows[ 12 ]; // blue or pink

// Find out how we want to export the data
if( outputOption == "" ){
	Dialog.create( "Choose output option" );
	Dialog.addChoice( "Output option:", newArray( "Create new file", "Append to existing file" ) );
	Dialog.addMessage( "In the next dialog, please choose an output file." );
	Dialog.show( );
	outputOption = Dialog.getChoice;
}

// Set up the array we're going to use for the output
outputColumns = newArray();
		
// Get the names for the output columns from the config file
for( i = 0; i < spotsX.length ; i++ ) {
	addValue = true;
	for( j = 0; j < outputColumns.length ; j++ ) { // Fiji doesn't have an 'is value NEEDLE in array HAYSTACK' function
		if( outputColumns[ j ] == spotsCategory[ i ] ) {
			addValue = false;
			j = outputColumns.length; // a way to exit the for loop 
		}
	}
	if (addValue == true) {
		outputColumns = Array.concat( outputColumns, spotsCategory[ i ] );
	}
}

// Create the output file if it doesn't already exist
if( outputFile == "" ){
	outputFile = File.open( "" );
	File.close( outputFile );
	outputFile = File.directory + File.name; // gets the path, which is what we pass to File.append
}

// Create the column headers for the output array
if( outputOption == "Create new file" ) {    
	outputArray = Array.concat( newArray( "Image", "Date/Time", "Latitude ref", "Latitude", "Longitude ref", "Longitude", "Altitude ref", "Altitude" ), outputColumns);
	// Header columns for when you're measuring flower area and perimeter
	if( measureFlower == true ){
		outputArray = Array.concat( outputArray, newArray( "Area (mm^2)", "Perimeter (mm)" ) );
	}
	File.append( arrayToString( outputArray ), outputFile );
} 

// Choose the images we're processing
if( imageFolder == "" ){
	showMessage( "Choose a directory of images to process." );
	imageFolder = getDirectory("Choose a directory of images to process");
}
imageList = getFileList( imageFolder );

if( toImage == -1 ){
	toImage = imageList.length; 
}

if( ( toImage - fromImage ) > 1 ) {
	setBatchMode(true); 
}

// Check if EXIF reader plugin is installed
// It can be found at https://imagej.nih.gov/ij/plugins/exif-reader.html
exifReaderInstalled = false;
List.setCommands; 
if (List.get("Exif Data...")!="") { 
	// plugin is installed 
	exifReaderInstalled = true;
} 

// ---- IMAGE PROCESSING PHASE ---- //

for( k = fromImage; k < toImage ; k++ ){
	
	// ---- GETTING IMAGE INFORMATION ---- //
	open( imageFolder + imageList[ k ] );

	// Setup: select the image and get some info about it. 
	title = getTitle();
	pictureDateTime = "";
	pictureLatitudeRef = "";
	pictureLatitude = "";
	pictureLongitudeRef = "";
	pictureLongitude = "";
	pictureAltitudeRef = "";
	pictureAltitude = "";

	// Clear any previous ROIs
	roiManager("Reset");

	// Get date and time the image was taken, if it's a JPG
	if( exifReaderInstalled == true ) {
		if (indexOf(title, '.jpg')<0 && indexOf(title, '.JPG')<0){
		 // not a JPG
		} else {

			// Opens and selects the ExifData window
			run("Exif Data...");

			// List.setList splits key/value pairs on space. Our Exif data starts with the key, then a tab, then has data which includes spaces. 
			// Therefore replace all spaces with "_", then subsequently replace all tabs with spaces.
			// This gives us one space-separated pair per line. 
			
			List.setList( replace( replace( getInfo(), " ", "_" ), "\t"," " ) );
			
			pictureDateTime = replace( List.get( "[Exif_SubIFD]_Date/Time_Original" ), "_", " " );
			
			pictureAltitudeRef = replace( List.get( "[GPS]_GPS_Altitude_Ref" ), "_", " " );
			pictureAltitude = replace( List.get( "[GPS]_GPS_Altitude" ), "_", " " );

			pictureLatitudeRef = replace( List.get( "[GPS]_GPS_Latitude_Ref" ), "_", " " );
			pictureLongitudeRef = replace( List.get( "[GPS]_GPS_Longitude_Ref" ), "_", " " );

			// Latitude and longitude values come out with a " at the end of them from the Exif reader plugin
			// so we need to replace that; Fiji also doesn't like the degrees symbol and prefaces it
			// with a Â so that needs removing as well.
			pictureLatitude = split( replace( replace( replace( List.get( "[GPS]_GPS_Latitude" ), "_", " " ), "Â", "" ), "\"", "" ), " " );
			pictureLongitude = split( replace( replace( replace( List.get( "[GPS]_GPS_Longitude" ), "_", " ") , "Â", "" ), "\"", "" ), " ");

			// Convert lat and long from degrees, minutes, seconds to decimal. 
			// This reuses the same variable and reassigns it from array to string
			// Show a warning if we don't have Lat and Long info in the image; only show it once, though.
			if( pictureLatitude.length > 0 ) {
				pictureLatitude = parseFloat( substring( pictureLatitude[ 0 ], 0, lengthOf( pictureLatitude[ 0 ] ) - 1 ) ) + parseFloat( substring( pictureLatitude[ 1 ], 0, lengthOf( pictureLatitude[ 1 ] ) - 1 ) )/60 + parseFloat( pictureLatitude[ 2 ] )/3600;
			} else {
				if( !shownLatLongWarning ){
					showMessage("The image " + title + " does not have latitude/longitude information in it.\nIf you were expecting to be able to extract this information, cancel processing \nand check your images. (If you are on a Mac, and have your images in the Photos app, \nyou need to select the images, go to File, Export, and make sure that \n'Location information' is checked (which it isn't by default).)");
					shownLatLongWarning = true;
				}
				pictureLatitude = "";
			}
			if( pictureLongitude.length > 0 ) {
				pictureLongitude = parseFloat( substring( pictureLongitude[ 0 ], 0, lengthOf( pictureLongitude[ 0 ] ) - 1 ) ) + parseFloat( substring( pictureLongitude[ 1 ], 0, lengthOf( pictureLongitude[ 1 ] ) - 1 ) )/60 + parseFloat( pictureLongitude[ 2 ] )/3600;
			} else {
				if( !shownLatLongWarning ){
					showMessage("The image " + title + " does not have latitude/longitude information in it.\nIf you were expecting to be able to extract this information, cancel processing \nand check your images. (If you are on a Mac, and have your images in the Photos app, \nyou need to select the images, go to File, Export, and make sure that \n'Location information' is checked (which it isn't by default).)");
					shownLatLongWarning = true;
				}
				pictureLongitude = "";
			}
		
			run("Close");
		}
	}
		
	// ---- FIND THE CORNER DOTS ---- //
	
	// Duplicate the image, bump up the dark parts to make it easier to detect,
	// and run the color threshold on it to get the corner dot areas. 
	run("Duplicate...", "title=duplicated_image.tif"); 
	
	setMinAndMax(101, 255);
	min=newArray(3);
	max=newArray(3);
	filter=newArray(3);
	a=getTitle();

	run("HSB Stack");
	run("Convert Stack to Images");
	
	selectWindow("Hue");
	rename("0");
	selectWindow("Saturation");
	rename("1");
	selectWindow("Brightness");
	rename("2");

	if( cornerDotColour == "blue" ){
		min[0]=120; 
		max[0]=172;
	} else if ( cornerDotColour == "pink" ) {
		min[0]=200; 
		max[0]=255;
	}
	filter[0]="pass";
	min[1]=120;
	max[1]=255;
	filter[1]="pass";
	min[2]=100;
	max[2]=255;
	filter[2]="pass";
	for (i=0;i<3;i++){
		selectWindow(""+i);
		setThreshold(min[i], max[i]);
		run("Convert to Mask");
		if (filter[i]=="stop")  run("Invert");
	}
	imageCalculator("AND create", "0","1");
	imageCalculator("AND create", "Result of 0","2");
	for (i=0;i<3;i++){
		selectWindow(""+i);
		close();
	}
	selectWindow("Result of 0");
	close();
	selectWindow("Result of Result of 0");
	rename(a);
	// Finish colour thresholding

	// Set the threshold and create a selection from it
	setAutoThreshold( "Default" );
	run( "Create Selection" );
	
	// Restore the selection of the dots onto the original image which hasn't had brightness changed
	selectWindow( title ); 
	run( "Restore Selection" ); 

	// Close the window used in thresholding
	selectWindow( a );
	close();
	
	// Return to the original image
	selectWindow( title );
	
	// Add the selection to the ROI manager and split it into its component circles.
	roiManager("Reset");
	roiManager("Add");
	roiManager("Select", 0);
	roiManager("Split");
	roiManager("Show All");
	
	// Prepare to remove all but the five largest ROIs, which will hopefully be the unsplit one plus the four corner dots
	roiAreas = newArray();

	// Measure the ROI area and save it to an array
	for (i=0; i<roiManager("count"); i++) { 
		roiManager("select", i);  
		List.setMeasurements;
		roiAreas = Array.concat( roiAreas, parseInt( List.getValue("Area") ) );
	} 
	
	// Duplicate the roiAreas array and sort it, so we can find the ROIs with largest area
	roiSortedAreas = Array.sort( Array.copy( roiAreas ) ) ;
	
	// Initialise the variables which we'll use to keep track of which ROIs are the spots, and which is the largest ROI
	spotsROIs = newArray();
	largestROI = -1;

	// Delete all but the five largest ROIs - the four individual corner dots, plus the ROI of all of them together
	for (i=(roiManager("count")-1); i>=0; i--) { 
		if( roiAreas[i] >= roiSortedAreas[ lengthOf( roiSortedAreas ) - 5 ] )  {

			// There appears to be a Java exception which sometimes is thrown if you delete lots of ROIs quickly. 
			// Instead, I'm noting down which are the four spot ROIs and which is the largest ROI, for use later. 
			// This bug was fixed in Fiji 1.52f13, but given that's quite recently, I'm leaving this workaround in here.
			// see https://forum.image.sc/t/java-exception-when-deleting-multiple-rois/18904/7
			if( roiAreas[ i ] == roiSortedAreas[ lengthOf( roiSortedAreas ) - 1 ] ) {
				largestROI = i; 
			} else {
				spotsROIs = Array.concat( spotsROIs, i );
			}

			// This is what I'd do if there wasn't a Fiji bug.
			//roiManager("select", i);  // select the ROI 
			//roiManager("Delete");  // delete the ROI 

		} 
	}

	// Select centres of selections and determine colour
	// set up individual corner dots and centroid arrays
	redDot = -1;
	blackDot = -1;
	greenDot = -1;
	whiteDot = -1;
	centroidXPoints = newArray();
	centroidYPoints = newArray();
	spotsRedValues = newArray();
	spotsGreenValues = newArray();
	spotsBlueValues = newArray();
	
	// Loop through the ROIs...
	for ( j = 1; j <=4; j++) {
	
		// Select the ROI, get its bounds, then select an area in its centre
		roiManager("Select", spotsROIs[ j - 1 ] );
		getSelectionBounds(x, y, selectionWidth, selectionHeight);
		makeOval(x + (selectionWidth*0.4), y + (selectionHeight*0.4), (selectionWidth*0.2), (selectionHeight*0.2));

		// Bump up the dark areas to make colour detection easier
		for( m = 0; m < 3; m++ ){
			setMinAndMax(30, 245);
		}

		// Measure the mean R, G and B values for the selection
		setRGBWeights(1, 0, 0);
		List.setMeasurements;
		spotsRedValues = Array.concat( spotsRedValues, parseInt( List.getValue( "Mean" ) ) );
		
		setRGBWeights(0, 1, 0);
		List.setMeasurements;
		spotsGreenValues = Array.concat( spotsGreenValues, parseInt( List.getValue( "Mean" ) ) );
		
		setRGBWeights(0, 0, 1);
		List.setMeasurements;
		spotsBlueValues = Array.concat( spotsBlueValues, parseInt( List.getValue( "Mean" ) ) );
		
	    // record the centroid point of the ROI - only need to do this once for each selection
		centroidXPoints = Array.concat( centroidXPoints, parseInt( List.getValue("X") ) );
		centroidYPoints = Array.concat( centroidYPoints, parseInt( List.getValue("Y") ) );
	
		// reset weights use (not sure this is strictly necessary but some places say it is)
		setRGBWeights(0.299, 0.587, 0.114);
	
	}
	
	// Which has the highest overall RGB sum? That's probably the white one.
	currentTotal = 0;
	for( i = 1; i <= 4; i++ ){
		if( ( spotsRedValues[ i - 1 ] + spotsGreenValues[ i - 1 ] + spotsBlueValues[ i - 1 ] ) > currentTotal ) {
			whiteDot = i;
			currentTotal = spotsRedValues[ i - 1 ] + spotsGreenValues[ i - 1 ] + spotsBlueValues[ i - 1 ];
		}
	}

	// which has the highest r value of the ones left over? That's probably red
	currentTotal = 0;
	for( i = 1; i <= 4; i++ ){
		if( spotsRedValues[ i - 1 ] > currentTotal && i != whiteDot ) {
			redDot = i;
			currentTotal = spotsRedValues[ i - 1 ] ;
		}
	}

	// which has the highest g value of the ones left over? That's probably green
	currentTotal = 0;
	for( i = 1; i <= 4; i++ ){
		if( spotsGreenValues[ i - 1 ] > currentTotal && i != whiteDot  && i != redDot ) {
			greenDot = i;
			currentTotal = spotsGreenValues[ i - 1 ] ;
		}
	}

	// And the black dot must be the one that's left.
	blackDot = 10 - ( redDot + greenDot + whiteDot );

	// Set up the outputValues array for this image and fill it with blank values
	outputValues = newArray();
	for( j = 0; j < outputColumns.length; j++ ){
		outputValues = Array.concat( outputValues, "" ); 
	}
	
	// Check we've got all four corner dots
	if ( redDot == -1 || greenDot == -1 || blackDot == -1 || whiteDot == -1 ) {

		for( j = 0; j < outputColumns.length; j++ ){
			if( j == 0 ){
				outputValues[ j ] = "Corner dot detection failed"; 
			} else {
				outputValues[ j ] = ""; 
			}
		}
		
	} else {
	
		// ---- ROTATE THE IMAGE TO HAVE RED CORNER DOT IN THE TOP LEFT ---- //
	
		// Measure the angles of the diagonals between black/red and green/white corner dots, which will help us straighten out the picture 
		makeLine( centroidXPoints[ redDot-1 ], centroidYPoints[ redDot-1 ], centroidXPoints[ blackDot-1 ], centroidYPoints[ blackDot-1 ] ); 
		List.setMeasurements;
		line1Angle = parseFloat( List.getValue("Angle") );
		line1Length = parseInt( List.getValue("Length") );
		makeLine( centroidXPoints[ greenDot-1 ], centroidYPoints[ greenDot-1 ], centroidXPoints[ whiteDot-1 ], centroidYPoints[ whiteDot-1 ] ); 
		List.setMeasurements;
		line2Angle = parseFloat( List.getValue("Angle" ) );
		line2Length = parseInt( List.getValue("Length") );
		
		run("Select None");
		
		// Sanity check to see if the diagonals are roughly right
		if( ( line1Length/line2Length ) < ( 0.95 ) || 
		    ( line1Length/line2Length ) > ( 1.05 ) ) {
		    for( j = 0; j < outputColumns.length; j++ ){
		    	if( j == 0 ) {
					outputValues[ j ] = "Diagonals not equal"; 
		    	} else {
		    		outputValues[ j ] = ""; 
		    	}
			}	
		} else {

			// Sanity check to see if the card has been tilted
			makeLine( centroidXPoints[ redDot-1 ], centroidYPoints[ redDot-1 ], centroidXPoints[ whiteDot-1 ], centroidYPoints[ whiteDot-1 ] ); 
			List.setMeasurements;
			line3Length = parseInt( List.getValue("Length") );
			makeLine( centroidXPoints[ greenDot-1 ], centroidYPoints[ greenDot-1 ], centroidXPoints[ blackDot-1 ], centroidYPoints[ blackDot-1 ] ); 
			List.setMeasurements;
			line4Length = parseInt( List.getValue("Length") );
			makeLine( centroidXPoints[ redDot-1 ], centroidYPoints[ redDot-1 ], centroidXPoints[ greenDot-1 ], centroidYPoints[ greenDot-1 ] ); 
			List.setMeasurements;
			line5Length = parseInt( List.getValue("Length") );
			makeLine( centroidXPoints[ whiteDot-1 ], centroidYPoints[ whiteDot-1 ], centroidXPoints[ blackDot-1 ], centroidYPoints[ blackDot-1 ] ); 
			List.setMeasurements;
			line6Length = parseInt( List.getValue("Length") );
			if( ( line3Length/line4Length ) < ( 0.95 ) || 
			    ( line3Length/line4Length ) > ( 1.05 ) || 
			    ( line5Length/line6Length ) < ( 0.95 ) || 
			    ( line5Length/line6Length ) > ( 1.05 ) ) {
			    for( j = 0; j < outputColumns.length; j++ ){
			    	if( j == 0 ) {
						outputValues[ j ] = "Card tilted"; 
			    	} else {
			    		outputValues[ j ] = ""; 
			    	}
				}	
			} else {

				// Work out the length of the diagonal between two spots. 
				// Then crop the image to a rectangle of width and height 1.2 x diagonal length. 
				// This allows for the image being rotated so that the diagonal is dead vertical or dead horizontal
				// and gives us enough space to do the forthcoming rotation without the corner dots falling off the edge of the image.
				// Doing this crop before we do the rotation saves approx. 0.25s per image processing time.
				diagonalLength = line1Length; 
				
				// Determine the coordinates, width and height of the rectangle we're cropping to
				if( ( ( ( centroidXPoints[ redDot - 1 ] + centroidXPoints[ blackDot - 1 ] ) / 2 ) - ( ( 1.2 * diagonalLength ) / 2 ) ) < 0 ) {
					cropX = 0;
					cropWidth = getWidth();
				} else {
					cropX = ( ( centroidXPoints[ redDot - 1 ] + centroidXPoints[ blackDot - 1 ] ) / 2 ) - ( ( 1.2 * diagonalLength ) / 2 );
					cropWidth = diagonalLength * 1.2;
				}
				if( ( ( ( centroidYPoints[ redDot - 1 ] + centroidYPoints[ blackDot - 1 ] ) / 2 ) - ( ( 1.2 * diagonalLength ) / 2 ) ) < 0 ) {
					cropY = 0;
					cropHeight = getHeight();
				} else {
					cropY = ( ( centroidYPoints[ redDot - 1 ] + centroidYPoints[ blackDot - 1 ] ) / 2 ) - ( ( 1.2 * diagonalLength ) / 2 );
					cropHeight = diagonalLength * 1.2;
				}
				
				// Translate the ROIs by the amount we're cropping by
				for( i = 0; i < 4 ; i++ ){
					roiManager( "select", spotsROIs[ i ]  );
					roiManager( "translate", -1 * cropX, -1 * cropY );
				}
				roiManager( "select", largestROI );
				roiManager( "translate", -1 * cropX, -1 * cropY );
		
				// Perform the crop
				makeRectangle( cropX, cropY, cropWidth, cropHeight );
				
				run( "Crop" );   
		
				// Make the angles 360-based, rather than +/- 180-based
				if( line2Angle>0 ) {
					line2Angle = line2Angle - 360;
				}
		
				if( line1Angle>0 ) {
					line1Angle = line1Angle - 360;
				}
		
				// Make angles positive
				line1Angle = line1Angle * -1;
				line2Angle = line2Angle * -1;
				
				// Rotate the picture so the two diagonals are equally spaced either side of vertical  
				run("Arbitrarily...", "angle="+ 450-( (line1Angle + (((line2Angle + 360 - line1Angle)%360)/2))%360)+" interpolate");
				
				// Select the largest ROI, which contains all four corner dots
				roiManager( "select", largestROI );
					
				// Rotate the selection relative to the image centre, so it still lines up with the Dots
				run("Rotate...", "rotate angle="+ 450-( (line1Angle + (((line2Angle + 360 - line1Angle)%360)/2))%360) );
			
				// Sometimes we can have a few small selections within the image which interfere with the cropping. 
				// Shrinking then enlarging the selection helps mitigate this. 
				run("Enlarge...", "enlarge=-5");
				run("Enlarge...", "enlarge=5");
	
				// Crop the image to the corner dots
				run("Crop");
		
				// Sanity check to see if it's roughly the right aspect ratio
				if( ( getWidth() / getHeight ) < ( 0.95 * ( originalWidth / originalHeight ) ) || 
				    ( getWidth() / getHeight ) > ( 1.05 * ( originalWidth / originalHeight ) ) ) {
				    for( j = 0; j < outputColumns.length; j++ ){
				    	if( j == 0 ) {
							outputValues[ j ] = "Unexpected rotated image aspect ratio"; 
				    	} else {
				    		outputValues[ j ] = ""; 
				    	}
					}	
				} else {
		
					// Set up the measurements and scaling factors 
					scaleXFactor = getWidth()/originalWidth;
					scaleYFactor = getHeight()/originalHeight;
		
					// check the top left dot is red
					optimalRedValues = newArray( 255, 0, 0, 255 ); // for red, green, black, white spots
					optimalGreenValues = newArray( 0, 255, 0, 255 ); 
					optimalBlueValues = newArray( 0, 0, 0, 255 );
					redTolerances = newArray( -100, 180, 155, -100 );
					greenTolerances = newArray( 100, -100, 155, -100 );
					blueTolerances = newArray( 100, 255, 155, -100 );
		
					makeOval( 0.5 * 8 * pixelsPerMM * scaleXFactor, 0.5 * 8 * pixelsPerMM * scaleYFactor, 0.1 * 8 * pixelsPerMM * scaleXFactor, 0.1 * 8 * pixelsPerMM * scaleYFactor );
					
					// Measure the mean R, G and B values for the selection
					setRGBWeights(1, 0, 0);
					List.setMeasurements;
					topLeftDotRedValue = parseInt( List.getValue( "Mean" ) );
					
					setRGBWeights(0, 1, 0);
					List.setMeasurements;
					topLeftDotGreenValue = parseInt( List.getValue( "Mean" ) );
					
					setRGBWeights(0, 0, 1);
					List.setMeasurements;
					topLeftDotBlueValue = parseInt( List.getValue( "Mean" ) );
				
					run( "Select None" );
		
					continueProcessing = true;
		
					// Check if the RGB values for this dot are within the tolerances for 'red'
					if( topLeftDotRedValue < optimalRedValues[ 0 ] + redTolerances[ 0 ] ||
						topLeftDotGreenValue > optimalGreenValues[ 0 ] + greenTolerances[ 0 ] ||
						topLeftDotBlueValue > optimalBlueValues[ 0 ] + blueTolerances[ 0 ] ){
		
						// Not worked? Bump up the contrast just to give it another go
						
						// check the top left dot is red
						makeOval( 0.5 * 8 * pixelsPerMM * scaleXFactor, 0.5 * 8 * pixelsPerMM * scaleYFactor, 0.1 * 8 * pixelsPerMM * scaleXFactor, 0.1 * 8 * pixelsPerMM * scaleYFactor );
						// Bump up the dark areas to make colour detection easier
						setMinAndMax(101, 255);
						
						// Measure the mean R, G and B values for the selection
						setRGBWeights(1, 0, 0);
						List.setMeasurements;
						topLeftDotRedValue = parseInt( List.getValue( "Mean" ) );
						
						setRGBWeights(0, 1, 0);
						List.setMeasurements;
						topLeftDotGreenValue = parseInt( List.getValue( "Mean" ) );
						
						setRGBWeights(0, 0, 1);
						List.setMeasurements;
						topLeftDotBlueValue = parseInt( List.getValue( "Mean" ) );
			
						run( "Select None" );
			
						if( topLeftDotRedValue < optimalRedValues[ 0 ] + redTolerances[ 0 ] ||
							topLeftDotGreenValue > optimalGreenValues[ 0 ] + greenTolerances[ 0 ] ||
							topLeftDotBlueValue > optimalBlueValues[ 0 ] + blueTolerances[ 0 ] ){
							
							for( j = 0; j < outputColumns.length; j++ ){
								outputValues[ j ] = "Image rotation failed (2)"; 
								continueProcessing = false;
							}
								
						}
							
					} 
		
					if( continueProcessing == true ){
						
						
						
						// ---- MEASURE VALUES IN THE WHITE SPOTS ---- //
						
						// Convert the spot x and y positions to integers
						for( i = 0; i < spotsX.length; i++ ){
							spotsX[ i ] = parseInt( spotsX[ i ] );
							spotsY[ i ] = parseInt( spotsY[ i ] );
						}
						
						//run("Duplicate...", "title=duplicated_image.tif"); 

				
				
						// Loop through the spots
						for( i = 0; i < spotsX.length; i++ ) {
						
							// Make the selection and measure it
							// 'adjustSpotSize' is there to determine the portion of the spot we measure; it's unlikely
							// that we'd want to measure the whole spot as that would assume a perfect photograph. 
							// A circle of diameter 25% of the spot size should be fine. 
							adjustSpotSize = 0.25;
							
							makeOval( ( spotsX[ i ] + ( ( ( 1 - adjustSpotSize) / 2 ) * spotWidth ) ) * scaleXFactor, ( spotsY[ i ] + ( ( ( 1 - adjustSpotSize) / 2 ) * spotHeight ) ) * scaleYFactor, spotWidth * scaleXFactor * adjustSpotSize, spotHeight * scaleYFactor * adjustSpotSize );
		
							// Set the histogram to make it more obvious what the coloured in / blank areas of the image are
							// Several small adjustments to brightness and contrast are better than one big one
							for( j = 0; j < 4; j++ ){
								setMinAndMax(30, 243);
							}
				
							// Measure the oval
							List.setMeasurements;
						
							if ( parseInt( List.getValue("Mean") ) < 175 ) { // probably coloured in
								
								// find which column we need to put it in
								// Fiji doesn't have a 'position of item needle in array haystack' function
								// so we have to do this with brute force
								// it could be done with a List, but you can only have one List, and this is relatively quick.
								for( j = 0; j < outputColumns.length; j++ ){
									if( outputColumns[ j ] == spotsCategory[ i ] ) {
										if( endsWith( spotsCategory[ i ], " (sum)" ) ){
											if( toString( outputValues[ j ] ) == "" ){
												outputValues[ j ] = 0;
											}
											outputValues[ j ] += parseInt( spotsValue[ i ] );
											
										} else {
											// Store the value, with a ; before it if there's already data in the value 
											if( outputValues[ j ] != "" ) {
												outputValues[ j ] = outputValues[ j ] + ";" ;
											}
											outputValues[ j ] = outputValues[ j ] + spotsValue[ i ];
										}
									}
								}
							}
						}


					
						// PERFORM YOUR CHOSEN MEASUREMENTS ON YOUR FLOWER //
						// Here I'm doing area and perimeter. 
						if( measureFlower == true ) {

							// Crop the image to the flower and delete all except a circle round the flower (which helps sort out reflections)
							selectWindow( title );
							run("Hide Overlay"); // otherwise we get the ROIs coming out on the cropped image
							makeRectangle( ( getWidth() - ( scaleXFactor *  ( flowerDiameter + flowerPadding + flowerPadding ) ) ) / 2 , scaleYFactor * ( flowerCentroidY - ( flowerDiameter / 2 ) - flowerPadding ) , ( flowerDiameter + ( 2 * flowerPadding ) ) * scaleXFactor, ( flowerDiameter + ( 2 * flowerPadding ) ) * scaleYFactor );
							run( "Crop" ); 
							makeOval( 0, 0, getWidth(), getHeight() );
							run("Make Inverse");
							setBackgroundColor(0, 0, 0);
							run("Clear", "slice");
							
							// If you want to save a JPG with the flower image, allowing inspection of how the program has measured the flower, here's where to do it.
							if( !File.exists( getDirectory("home") + "Desktop/flowerImages/" ) ) {
								File.makeDirectory( getDirectory("home") + "Desktop/flowerImages/" );
							}
							saveAs( "jpg", getDirectory("home") + "Desktop/flowerImages/" + title );
					
							// Bump up the darks and lights to make a more contrasty flower
							setMinAndMax(140, 210);
					
							// Convert to black and white and threshold, then mask
							run("8-bit");
							setThreshold(104, 255);
							setOption("BlackBackground", false);
							run("Convert to Mask");
					
							// Select the flower, then enlarge, reduce and enlarge to sort out holes and discontinuities
							// You may want to use a different enlarge/subtract value here depending on how tight you want the fit to the perimeter
							run("Create Selection");
							run("Enlarge...", "enlarge=20");
							run("Enlarge...", "enlarge=-22");
							run("Enlarge...", "enlarge=2");
							run("Create Mask");
					
							// Measure the flower
							run( "Set Measurements...", "area perimeter redirect=None decimal=3" );
							run("Analyze Particles...", "size=10000-Infinity display clear add");
					
							// If we have results, record what we're going to save
							if( nResults > 0 ){			
								outputValues = Array.concat( outputValues, newArray( round( ( getResult( "Area" ) / ( scaleXFactor * scaleYFactor ) ) / ( pixelsPerMM * pixelsPerMM ) ) , round( ( ( getResult ( "Perim." ) / pixelsPerMM ) / scaleXFactor ) ) ) );			
							} else {
								// If we don't have results, we're going to save a blank line
								outputValues = Array.concat( outputValues, newArray( "0", "0" ) );
							}
					
							// If you want to save a JPG with the masked area, allowing inspection of how the program has measured the flower, here's where to do it.
							selectWindow( title );
							run( "Restore Selection" );
							newImage( "Selection", "RGB", getWidth(), getHeight(), 1 );
							run( "Restore Selection" );
							run("Colors...", "foreground=magenta background=black selection=yellow");
							fill();
							if( !File.exists( getDirectory("home") + "Desktop/flowerCutouts/" ) ) {
								File.makeDirectory( getDirectory("home") + "Desktop/flowerCutouts/" );
							}
							saveAs( "jpg", getDirectory("home") + "Desktop/flowerCutouts/" + title );
						}
					}
				}
			}
		}
	}

	// Save this image's data
	outputArray = Array.concat( newArray( title, pictureDateTime, pictureLatitudeRef, pictureLatitude, pictureLongitudeRef, pictureLongitude, pictureAltitudeRef, pictureAltitude ), outputValues);
	File.append( arrayToString( outputArray ), outputFile );
		
	// If we're working with more than one image, close existing windows
	// (but don't do it if we're working with just one - it's useful for debugging
	if( ( toImage - fromImage ) > 1 ) {
   		run("Close All");
   		
   		// Work around a bug in ImageJ which keeps images open in memory when batch mode is selected
   		call("java.lang.System.gc"); 
  	}
	
}

// If we're working with more than one image, set batchmode back to false
if( ( toImage - fromImage ) > 1 ) {
	setBatchMode(false); 
}

// Helper function to concatenate an array because this doesn't exist in Fiji
function arrayToString( outputValues ){
	outputMessage = "";
	for( j = 0; j < outputValues.length; j++ ){
		if(toString( outputValues[j] ) != "") {
			outputMessage = outputMessage + toString( outputValues[j] );
		}
		 if( j < ( outputValues.length - 1 ) ) {
		 	outputMessage = outputMessage + ",";
		 }
	}
	return outputMessage;
}
