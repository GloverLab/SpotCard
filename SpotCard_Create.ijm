	// This file is available from https://github.com/GloverLab/SpotCard
	
	// Set up various variables
	showDialog = true;
	flowerDiameter = -1;
	cornerDotColour = "";
	sets = newArray();
	setChoices = newArray();
	setA = "";
	setB = "";
	setC = "";
	choicesA = "";
	choicesB = "";
	choicesC = "";

	// set defaults
	pixelsPerMM = 12; // I prefer to work in mm, so this is pixels per mm.
	spotDiameter = 3.3; // in mm
	spotMinimumSpacing = 1; // in mm. This can be overridden if the text for the choice is longer
	if( flowerDiameter == 0 ){
		flowerPadding = 0; // No flower - no padding!
	} else {
		flowerPadding = 10; // in mm. Padding around the flower before we have spot graphics
	}
	spotTextPadding = 1; // padding between spot and text, in mm
	fontSize = 2.5; // height, in mm
	setPadding = 3; // padding between sets
	cornerDotDiameter = 8;
	cornerDotClear = 1; // how much clear space you have to have around corner dots


	// I only want three choices per dialog, as otherwise it gets horribly long and complicated,
	// so use a loop and ask the user if they want to add more each tiem.
	while( showDialog == true ) {
	
		Dialog.create( "Set up choice sets" );
		
		if( flowerDiameter == -1 ) {
			Dialog.addChoice( "Approx. flower diameter (mm):", newArray( "No flower", "20", "30", "40", "60", "80", "100" ) );
		}

		if( cornerDotColour == "" ) {
			Dialog.addChoice( "Corner dot colour:", newArray( "Blue", "Pink" ) );
		}
		
		Dialog.addString( "Set " + sets.length + 1 + " description:", setA );
		Dialog.addString( "Set " + sets.length + 1 + " choices (comma separated):", choicesA );
		Dialog.addString( "Set " + sets.length + 2 + " description:", setB );
		Dialog.addString( "Set " + sets.length + 2 + " choices (comma separated):", choicesB );
		Dialog.addString( "Set " + sets.length + 3 + " description:", setC );
		Dialog.addString( "Set " + sets.length + 3 + " choices (comma separated):", choicesC );
		Dialog.addChoice( "Add more sets?", newArray( "No", "Yes" ) );
		Dialog.show();

		// Save the flower diameter if we've not already saved it	
		if( flowerDiameter == -1 ) {
			flowerChoice = Dialog.getChoice();
			if( flowerChoice == "No flower" ) {
				flowerDiameter = 0;
			} else {
				flowerDiameter = parseInt( flowerChoice );
			}
		}

		if( cornerDotColour == "" ) {
			cornerDotColour = Dialog.getChoice();
		}

		// Fiji macro language lacks a trim() function
		// Trim the set names and remove all spaces from the choices
		setA = replace( replace( Dialog.getString(), "^\\s*", "" ), "\\s*$", "" ); //removes leading and trailing whitespaces
		choicesA = replace( Dialog.getString(), " ", "" );
		setB = replace( replace( Dialog.getString(), "^\\s*", "" ), "\\s*$", "" ); //removes leading and trailing whitespaces
		choicesB = replace( Dialog.getString(), " ", "" );
		setC = replace( replace( Dialog.getString(), "^\\s*", "" ), "\\s*$", "" ); //removes leading and trailing whitespaces
		choicesC = replace( Dialog.getString(), " ", "" );
		addMore = Dialog.getChoice(); 

		// Sanity checking the input
		// Note this doesn't check for blank values (ie 1,2,,3,4) or duplicate values (ie 1,2,2,3). 
		// Such sanity checking is on the shoulders of the user!
		if( ( setA != "" && choicesA == "" ) || ( setA == "" && choicesA != "" ) ||
			( setB != "" && choicesB == "" ) || ( setB == "" && choicesB != "" ) ||
			( setC != "" && choicesC == "" ) || ( setC == "" && choicesC != "" ) ||
			( setA == "" && setB == "" && setC == "" && choicesA == "" && choicesB == "" && choicesC == "" ) ) {

			// Either they've got a set with no choices, or some choices with no set, or haven't entered anything.
			Dialog.create( "Please enter accurate data" );
			Dialog.addMessage( "Please enter accurate data.\nf you enter a set name, you need to enter choices;\nif you enter choices, you need to enter a set name.\nYou also need to enter at least one set of choices." );
			Dialog.show();
			
		} else {
			
			// All seems well with this entry. 

			// Add sets and choices to array
			if( setA != "" ) {
				sets = Array.concat( sets, setA );
				setChoices = Array.concat( setChoices, choicesA );
				setA = "";
				choicesA = "";
			}
			
			if( setB != "" ) {
				sets = Array.concat( sets, setB );
				setChoices = Array.concat( setChoices, choicesB );
				setB = "";
				choicesB = "";
			}
			
			if( setC != "" ) {
				sets = Array.concat( sets, setC );
				setChoices = Array.concat( setChoices, choicesC );
				setC = "";
				choicesC = "";
			}

			if( addMore == "No" ) {
				showDialog = false;
			}
			
		}
	
	}

	// Now we have an array of set names (sets), an array of choices (setChoices)
	// which has the same number of values as sets, and a flower diameter.
	// We can start to construct the card graphic. 

	// set up output values
	spotsX = newArray();
	spotsY = newArray();
	spotsValue = newArray();
	spotsCategory = newArray();
	originalWidth = -1;
	originalHeight = -1;

	fontSize = fontSize * pixelsPerMM; // convert to points

	// Prepare the card graphic file
	if( flowerDiameter > 0 ){
		cardWidth = ( parseInt( flowerDiameter ) + ( flowerPadding * 2 ) ) * pixelsPerMM;
	} else {
		cardWidth = 1;
	}
	
	newImage( "Card", "RGB", cardWidth, cardWidth, 1 );
	run( "Colors...", "foreground=black background=black selection=yellow" );
	floodFill( 1, 1 );

	// Store the position of the flower centroid so we can draw a line to it later; 
	// It's also useful for positioning of spot sets.
	flowerCentroidX = getWidth() / 2;
	flowerCentroidY = ( flowerPadding + ( flowerDiameter / 2 ) ) * pixelsPerMM;

	// Loop through the sets and prepare the spots graphic for them.
	for( j = 0; j < sets.length; j++ ){

		thisSetSpotsX = newArray();
		thisSetSpotsY = newArray();
		thisSetSpotsValue = newArray();
		thisSetSpotsCategory = newArray();
		thisSetSpotChoices = newArray();
		
		// Set up the spots graphic image
		newImage( "Helper", "RGB", 1, 1, 1 );
		run( "Colors...", "foreground=black background=black selection=yellow" );
		floodFill( 1, 1 );
	
		selectWindow( "Helper" );
		
		// determine width of this set
		if( startsWith(setChoices[ j ], "0-") ){
			thisSetChoices = newArray( "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" );
		} else {
			thisSetChoices = split( setChoices[ j ], ",," ); // Fiji can return an empty string if , is used as a separator
		}		
		setFont( "SansSerif", fontSize, "antialiased" );
		widthOfSet = 0;
		choiceWidths = newArray();
		spotsWidth = 0;
		// See if the width of the text for this spot is more than the width of the spot itself
		for( i = 0; i < thisSetChoices.length; i++ ) {
			if( getStringWidth( thisSetChoices[ i ] ) > ( pixelsPerMM * spotDiameter) ) { 
				widthOfSet += getStringWidth( thisSetChoices[ i ] );
				choiceWidths = Array.concat( choiceWidths, getStringWidth( thisSetChoices[ i ] ) );
			} else {
				widthOfSet += pixelsPerMM * spotDiameter;
				choiceWidths = Array.concat( choiceWidths, pixelsPerMM * spotDiameter );
			}
			if( i != ( thisSetChoices.length - 1 ) ) {
				widthOfSet += pixelsPerMM * spotMinimumSpacing;
			}
			
		}
	
		spotsWidth = widthOfSet; // in pixels
	
		// check the width of the set isn't wider than the width of the set name
		if( widthOfSet < getStringWidth( sets[ j ] ) ) {
			widthOfSet = getStringWidth( sets[ j ] );
		}
	
		// Resize the helper canvas to hold the set
		if( startsWith( setChoices[ j ], "0-" ) ) {
			numberOfRows = lengthOf( setChoices[ j ] ) - lengthOf( replace( setChoices[ j ], "9", "" ) ); // somewhat hacky way of finding out how many 9s there are after the dash!
		} else {
			numberOfRows = 1;
		}
		
		run("Canvas Size...", "width=" + widthOfSet + " height=" + fontSize + ( ( spotTextPadding + ( numberOfRows * spotDiameter ) + ( ( numberOfRows - 1 ) * spotMinimumSpacing ) + spotTextPadding) * pixelsPerMM) + fontSize + " position=Top-Center");
	

		// Set the colour to white and draw the set name
		run( "Colors...", "foreground=white background=black selection=yellow" );
		setJustification( "center" );
		setFont( "SansSerif", fontSize, "antialiased" ); //You have to reset antialiasing after setJustification?
		drawString( sets[ j ], getWidth() / 2, fontSize );

		
		// Draw spots and text below them
		spotCurrentX = ( getWidth() - spotsWidth ) / 2;
		spotY = fontSize + ( spotTextPadding * pixelsPerMM );
		
		for( i = 0; i < thisSetChoices.length; i++ ) {

			// Allow us to use eg 0-999 as a choice, which will give three rows of dots, 0-9
			for( k = 0; k < numberOfRows; k++ ){
					
				fillOval( spotCurrentX + ( ( choiceWidths[ i ] - ( spotDiameter * pixelsPerMM ) ) / 2 ), 
					spotY + ( k * ( spotDiameter + spotMinimumSpacing ) * pixelsPerMM ), spotDiameter * pixelsPerMM, spotDiameter * pixelsPerMM );
		
				drawString( thisSetChoices[ i ], spotCurrentX + ( choiceWidths[ i ] / 2 ), 
					spotY + ( ( spotDiameter + spotTextPadding ) * pixelsPerMM ) + fontSize + ( k * ( spotDiameter + spotMinimumSpacing ) * pixelsPerMM ) );
	
				// Save the current X and Y values for spots
				thisSetSpotsX = Array.concat( thisSetSpotsX, spotCurrentX + ( ( choiceWidths[ i ] - ( spotDiameter * pixelsPerMM ) ) / 2 ) );
				thisSetSpotsY = Array.concat( thisSetSpotsY, spotY + ( k * ( spotDiameter + spotMinimumSpacing ) * pixelsPerMM ));
				if( numberOfRows == 1 ) {
					thisSetSpotsValue = Array.concat( thisSetSpotsValue, thisSetChoices[ i ] );
				} else {
					thisSetSpotsValue = Array.concat( thisSetSpotsValue, parseInt( thisSetChoices[ i ] ) * pow( 10, numberOfRows - ( k + 1 ) ) );
				}

				// Save the category name for this spot, adding 'sum' if it's a 0-xx type row.
				thisSpotCategory = sets[ j ];
				if( numberOfRows > 1 ) {
					thisSpotCategory += " (sum)";
				}
				thisSetSpotsCategory = Array.concat( thisSetSpotsCategory, thisSpotCategory );
			}
			
			// Increase the spotCurrentX value to the X for the next spot
			spotCurrentX = spotCurrentX + choiceWidths [ i ] + ( spotMinimumSpacing * pixelsPerMM );
			
		}
		
		// Work out if this is going to go on the left, on the right or under the flower centroid
		// If there's only one set, it goes below. Two sets go left and right. Three sets go left, right, below.
		if( flowerDiameter == 0 ) {
			positionOnCard = "bottom";
		} else {
			if( ( j + 1 ) % 3 == 1 ) {
				if( j < ( sets.length - 1 ) ) {
					positionOnCard = "left";
				} else {
					positionOnCard = "bottom";
				}
			} else if( ( j + 1 ) % 3 == 2 ) {
				positionOnCard = "right";
			} else {
				positionOnCard = "bottom";
			}
		}

		// Rotate the helper image if we're putting it on the left or right
		if( positionOnCard == "left" ){ 
			
			run("Rotate 90 Degrees Right");

			// Change the X and Y coordinates to reflect the fact that this image has been rotated
			tempYValues = Array.copy( thisSetSpotsY ); // need to copy these as we're about to overwrite them! 
			thisSetSpotsY = Array.copy( thisSetSpotsX );
			for( i = 0; i < tempYValues.length; i++ ){
				thisSetSpotsX[ i ] = getWidth() - tempYValues[ i ] - ( spotDiameter * pixelsPerMM );
			}
			
		} else if( positionOnCard == "right" ) {
			
			run("Rotate 90 Degrees Left");

			// Change the X and Y coordinates to reflect the fact that this image has been rotated
			tempXValues = Array.copy( thisSetSpotsX ); // need to copy these as we're about to overwrite them! 
			thisSetSpotsX = Array.copy( thisSetSpotsY );
			for( i = 0; i < tempXValues.length; i++ ){
				thisSetSpotsY[ i ] = getHeight() - tempXValues[ i ] - ( spotDiameter * pixelsPerMM );
			}
			
			
		}
		
		// Get width and height of current spots image
		spotSetImageWidth = getWidth();
		spotSetImageHeight = getHeight();
		
		// Prepare to copy this spot set to the helper image
		selectWindow( "Card" );

		// If we already have sets added, we need to have padding between them
		if( j < 3 && flowerDiameter != 0 ) {
			additionalPadding = 0;
		} else {
			additionalPadding = setPadding * pixelsPerMM;
		}
			
		// Depending on where we're copying, the resizing is different
		if( positionOnCard == "bottom" ) {
			
			// we have to resize the card image wider if need be
			if( spotSetImageWidth > getWidth() ) {
				increaseCardWidthBy = spotSetImageWidth - getWidth();
			} else {
				increaseCardWidthBy = 0;
			}
			
			run("Canvas Size...", "width=" + getWidth() + increaseCardWidthBy + " height=" + getHeight() + spotSetImageHeight + additionalPadding + " position=Top-Center");
			
			// increase the X values as we're widening the card. 
			// No need to increase Y values as we're widening based around top centre
			for( i = 0; i < spotsX.length; i++ ) {
				spotsX[ i ] += increaseCardWidthBy/2;
			}
			
			// Copy the spot set image to the helper image
			run("Add Image...", "image=Helper x=" + ( getWidth() - spotSetImageWidth ) / 2 + " y=" + getHeight() - spotSetImageHeight + " opacity=100");

			// Alter the X and Y values for this set now we've placed it on the larger image
			for( i = 0; i < thisSetSpotsX.length; i++ ){
				thisSetSpotsX[ i ] += ( getWidth() - spotSetImageWidth ) / 2 ;
			}
			
			for( i = 0; i < thisSetSpotsY.length; i++ ){
				thisSetSpotsY[ i ] += getHeight() - spotSetImageHeight ;
			}
			
		} else if( positionOnCard == "left" ) {
			
			// See if we have to resize the card higher
			// Spot sets are centred on the flower centroid
			if( spotSetImageHeight > 2 * flowerCentroidY ) {
				increaseCardHeightBy = spotSetImageHeight - ( ( flowerDiameter + ( flowerPadding * 2 ) ) * pixelsPerMM );
				flowerCentroidY = flowerCentroidY + increaseCardHeightBy / 2;
			} else {
				increaseCardHeightBy = 0;
			}

			flowerCentroidX = flowerCentroidX + spotSetImageWidth + additionalPadding;
			
			run("Canvas Size...", "width=" + getWidth() + spotSetImageWidth + spotSetImageWidth + additionalPadding + additionalPadding + " height=" + getHeight() + increaseCardHeightBy + " position=Top-Center");

			// increase the X values as we're widening the card. 
			for( i = 0; i < spotsX.length; i++ ) {
				spotsX[ i ] += spotSetImageWidth + additionalPadding;
			}
			// Increase the Y values as we're making the card deeper
			for( i = 0; i < spotsY.length; i++ ) {
				spotsY[ i ] += increaseCardHeightBy / 2;
			}
			
			// Copy the spot set image to the helper image
			run("Add Image...", "image=Helper x=0 y=" + flowerCentroidY - ( spotSetImageHeight / 2 )  + " opacity=100");			

			// Alter the X and Y values for this set now we've placed it on the larger image
			for( i = 0; i < thisSetSpotsY.length; i++ ){
				thisSetSpotsY[ i ] += flowerCentroidY - ( spotSetImageHeight / 2 ) ;
			}
		} else if( positionOnCard == "right" ) {
			
			// See if we have to resize the card higher
			// Spot sets are centred on the flower centroid
			if( spotSetImageHeight > 2 * flowerCentroidY ) {
				increaseCardHeightBy = spotSetImageHeight - ( ( flowerDiameter + ( flowerPadding * 2 ) ) * pixelsPerMM );
				flowerCentroidY = flowerCentroidY + increaseCardHeightBy / 2;
			} else {
				increaseCardHeightBy = 0;
			}

			run("Canvas Size...", "width=" + getWidth() + " height=" + getHeight() + increaseCardHeightBy + " position=Top-Center");
			
			// Increase the Y values as we're widening the card
			for( i = 0; i < spotsY.length; i++ ) {
				spotsY[ i ] += increaseCardHeightBy / 2;
			}
			
			// Copy the spot set image to the helper image
			run("Add Image...", "image=Helper x=" + getWidth() - spotSetImageWidth - additionalPadding + " y=" + flowerCentroidY - ( spotSetImageHeight / 2 )  + " opacity=100");			
			
			// Alter the X and Y values for this set now we've placed it on the larger image
			for( i = 0; i < thisSetSpotsX.length; i++ ){
				thisSetSpotsX[ i ] += getWidth() - spotSetImageWidth - additionalPadding ;
			}
			for( i = 0; i < thisSetSpotsY.length; i++ ){
				thisSetSpotsY[ i ] += flowerCentroidY - ( spotSetImageHeight / 2 ) ;
			}
		}
		
		// Close the helper image for this set
		selectWindow( "Helper" );
		run( "Close" );

		for( i = 0; i < thisSetSpotsX.length; i++ ) {
			spotsX = Array.concat( spotsX, thisSetSpotsX[ i ] );
			spotsY = Array.concat( spotsY, thisSetSpotsY[ i ] );
			spotsValue = Array.concat( spotsValue, thisSetSpotsValue[ i ] );
			spotsCategory = Array.concat( spotsCategory, thisSetSpotsCategory[ i ] );
		}

	}
	// Put in the four corner dots, which tell us about orientation
	// First flatten the card
	run( "Flatten" ); // makes a new window
	selectWindow( "Card" );
	run( "Close" );
	selectWindow( "Card-1" );
	rename( "Card" );
	
	// if the card height isn't enough to fit the corner dots in, increaese it
	if( getHeight() < ( 2 * ( cornerDotDiameter * pixelsPerMM ) ) ){ 
		increaseHeightBy = ( 2 * ( cornerDotDiameter * pixelsPerMM * 1.1 ) ) - getHeight(); // Need to make the total height more than twice the corner dot diameter, otherwise the dots can bleed into each other
		run("Canvas Size...", "width=" + getWidth() + " height=" + 2 * ( cornerDotDiameter * pixelsPerMM * 1.1 ) + " position=Center");
		flowerCentroidY += ( increaseHeightBy / 2 );
		for( i = 0; i < spotsY.length; i++ ){ 
			spotsY[ i ] += ( increaseHeightBy / 2 );
		}
	}
	
	// See if we can add them to the card as it is. 
	expandCard = false;
	run("Set Measurements...", "mean redirect=None decimal=3");
	makeOval( 0, 0, ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM, ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM );
	run("Measure");
	if( getResult( "Mean" ) > 0 ) { // There's something white in there
		expandCard = true;
	}
	if( expandCard == false ){ 
		makeOval( getWidth() -  ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM, 0, ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM, ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM );
		run("Measure");
		if( getResult( "Mean" ) > 0 ) { // There's something white in there
			expandCard = true;
		}
	}
	if( expandCard == false ){ 
		makeOval( 0, getHeight() - ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM, ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM, ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM );
		run("Measure");
		if( getResult( "Mean" ) > 0 ) { // There's something white in there
			expandCard = true;
		}
	}
	if( expandCard == false ){ 
		makeOval( getWidth() -  ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM, getHeight() -  ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM, ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM, ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM );
		run("Measure");
		if( getResult( "Mean" ) > 0 ) { // There's something white in there
			expandCard = true;
		}
	}

	// If we need to expand the card, do so by the (corner dot diameter + corner dot padding) * square root 2
	// which will give us the padding we need in each corner
	if( expandCard == true ){ 
		run("Canvas Size...", "width=" + getWidth() + 2 * ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM + " height=" + getHeight() +" position=Center");
		flowerCentroidX = flowerCentroidX + ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM;

		for( i = 0; i < spotsX.length; i++ ){ 
			spotsX[ i ] += ( cornerDotDiameter + cornerDotClear ) * pixelsPerMM;
		}

	}

	
	// Place the four dots in the four corners
	if( cornerDotColour == "blue" ){
		setColor( 0, 126, 255 ); // blue
	} else if( cornerDotColour == "pink" ) {
		setColor( 255, 0, 183 ); // pink
	}
	fillOval( 0, 0, cornerDotDiameter * pixelsPerMM, cornerDotDiameter * pixelsPerMM );
	fillOval( getWidth() - cornerDotDiameter * pixelsPerMM , 0, cornerDotDiameter * pixelsPerMM, cornerDotDiameter * pixelsPerMM );
	fillOval( 0, getHeight() - cornerDotDiameter * pixelsPerMM, cornerDotDiameter * pixelsPerMM, cornerDotDiameter * pixelsPerMM );
	fillOval( getWidth() - cornerDotDiameter * pixelsPerMM , getHeight() - cornerDotDiameter * pixelsPerMM, cornerDotDiameter * pixelsPerMM, cornerDotDiameter * pixelsPerMM );

	// Place the four dots in the middle of the dots already in the four corners
	setColor( 255, 0, 0 ); // red, top left
	fillOval( cornerDotDiameter * pixelsPerMM * 0.25, cornerDotDiameter * pixelsPerMM * 0.25, cornerDotDiameter * pixelsPerMM * 0.5, cornerDotDiameter * pixelsPerMM * 0.5 );
	setColor( 0, 255, 0 ); // green, top right
	fillOval( getWidth() - cornerDotDiameter * pixelsPerMM * 0.75 , cornerDotDiameter * pixelsPerMM * 0.25, cornerDotDiameter * pixelsPerMM * 0.5, cornerDotDiameter * pixelsPerMM * 0.5 );
	setColor( 255, 255, 255 ); // white, bottom left
	fillOval( cornerDotDiameter * pixelsPerMM * 0.25, getHeight() - cornerDotDiameter * pixelsPerMM * 0.75, cornerDotDiameter * pixelsPerMM * 0.5, cornerDotDiameter * pixelsPerMM * 0.5 );
	setColor( 0, 0, 0 ); // black, bottom right
	fillOval( getWidth() - cornerDotDiameter * pixelsPerMM * 0.75 , getHeight() - cornerDotDiameter * pixelsPerMM * 0.75, cornerDotDiameter * pixelsPerMM * 0.5, cornerDotDiameter * pixelsPerMM * 0.5 );

	widthWithoutBorder = getWidth();
	heightWithoutBorder = getHeight();
	
	// Add black border round the whole card
	run("Canvas Size...", "width=" + getWidth() + 2 * sqrt( 2 ) * cornerDotClear * pixelsPerMM + " height=" + getHeight() + 2 * sqrt( 2 ) * cornerDotClear * pixelsPerMM + " position=Center");
	flowerCentroidX = flowerCentroidX + sqrt( 2 ) * cornerDotClear * pixelsPerMM;
	flowerCentroidY = flowerCentroidY + sqrt( 2 ) * cornerDotClear * pixelsPerMM;
	// Don't add to the spotsX and spotY arrays here because they're relative to the corner dots, not to the card itself
		
	// Add the cut line to the centroid
	if( flowerDiameter > 0 ) {
		setColor( 255, 255, 255 );
		setLineWidth( pixelsPerMM ); // 1mm thick line
		drawLine( flowerCentroidX, 0, flowerCentroidX, flowerCentroidY );
	} 
	
	// Set the pixelsPerMM of the card to what it should be
	// Have to convert this to inches as the information doesn't make it through to the 
	// tif file if we set it in mm
	run("Set Scale...", "distance=" + round(pixelsPerMM * 25.4) + " known=1 unit=inch");
	
	// Rename the card to today's date plus a random number, to aid working out which card is for which file
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	month = toString( month );
	if( lengthOf( month ) == 1 ) {
		month = "0" + month;	
	}
	dayOfMonth = toString( dayOfMonth );
	if( lengthOf( dayOfMonth ) == 1 ) {
		dayOfMonth = "0" + toString( dayOfMonth );	
	}
	rename( year + "-" + month + "-" + dayOfMonth + "-" + floor( random() * 1000 ) );

	// Choose where to save, and save the tif and the txt file, making sure that a file with this name doesn't exist already
	showMessage( "Choose a directory in which to save" );
	saveDirectory = getDirectory( "Choose a directory in which to save" );

	saveFilename = getTitle() ;
	saveFilenameAddition = "";
	i = 0;
	while( File.exists( saveDirectory + saveFilename + saveFilenameAddition + ".tif" ) || File.exists( saveDirectory + saveFilename + saveFilenameAddition + ".txt" ) ) {
		i++;
		saveFilenameAddition = toString( i );
	}

	// Save the image
	saveAs( "Tiff", saveDirectory + saveFilename + saveFilenameAddition + ".tif" );

	// Save the configuration file.
	outputFile = File.open( saveDirectory + saveFilename + saveFilenameAddition + ".txt" );

	outputSpotsX = "";
	outputSpotsY = "";
	outputSpotsValue = "";
	outputSpotsCategory = "";
	for( i = 0; i < spotsX.length; i++ ){
		spotsX[ i ] = round( spotsX[ i ] );
		spotsY[ i ] = round( spotsY[ i ] );
	}
	
	print( outputFile, arrayToString( spotsX ) );
	print( outputFile, arrayToString( spotsY ) );
	print( outputFile, spotDiameter * pixelsPerMM );
	print( outputFile, spotDiameter * pixelsPerMM );
	print( outputFile, flowerDiameter * pixelsPerMM );
	print( outputFile, flowerPadding * pixelsPerMM );
	print( outputFile, arrayToString( spotsValue ) );
	print( outputFile, arrayToString( spotsCategory ) );
	print( outputFile, widthWithoutBorder );
	print( outputFile, heightWithoutBorder );
	print( outputFile, round( flowerCentroidY )  ); // No need to store flowerCentroidX as it's symmetrically positioned on the card 
	print( outputFile, pixelsPerMM );
	print( outputFile, cornerDotColour );
	File.close( outputFile );

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