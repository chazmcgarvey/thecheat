
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      SessionController.m
// Created:   Sun Sep 07 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "SessionController.h"

#import "AppController.h"

#import "CheatClient.h"


// Internal Functions
void TCPlaySound( NSString *name );


@implementation SessionController

- (id)init
{
    if ( self = [super initWithWindowNibName:@"Session"] )
	{
		NSNotificationCenter		*nc = [NSNotificationCenter defaultCenter];
		
		// initialize stuff
		sockfd = -1;
		addressList = [[NSMutableArray alloc] init];

		// notifications to receive
		[nc addObserver:self selector:@selector(listenerStarted:) name:@"TCListenerStarted" object:nil];
		[nc addObserver:self selector:@selector(listenerStopped:) name:@"TCListenerStopped" object:nil];
		[nc addObserver:self selector:@selector(windowsOnTopChanged:) name:@"TCWindowsOnTopChanged" object:nil];
		
		serverList = [(NSArray *)[NSApp serverList] retain];
		
		// register to recieve notes from the global browser
		[nc addObserver:self selector:@selector(browserServerFound:) name:@"TCServerFound" object:nil];
		[nc addObserver:self selector:@selector(browserServerLost:) name:@"TCServerLost" object:nil];

		[self connectToLocal];
	}
	
    return self;
}

/*- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (NSString *)displayName
{
	return [NSString stringWithFormat:@"The Cheat %i", TCGlobalDocumentCount++];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)controller
{
    [super windowControllerDidLoadNib:controller];

	[self initialInterfaceSetup];
}*/

- (void)windowDidLoad
{
	[cheatWindow setTitle:[NSString stringWithFormat:@"The Cheat %i", ++TCGlobalSessionCount]];
	
	[self initialInterfaceSetup];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	// closing the window will automatically disconnect the client from the server,
	// but if the application is quitting, the client may not get a chance to exit.
	// this _should_ be OK.
	[self disconnect];
	
	// clean up status timer stuff.
	// we do this here because we don't want the timer to fire after the window is gone
	// since we need to use the window in that method.
	[savedStatusColor release], savedStatusColor = nil;
	[savedStatusText release], savedStatusText = nil;
	[statusTextTimer invalidate];
	[statusTextTimer release], statusTextTimer = nil;
	
	// we keep track of ourselves so we have to release ourself.
	[self release];
}


- (void)initialInterfaceSetup
{
	NSString			*localName = @"Local"; //[NSString stringWithFormat:@"%@ (local)", TCGlobalBroadcastName];
	
	NSMenuItem			*menuItem;
	int					i, top = [serverList count];
	
	// misc window settings
	[cheatWindow useOptimizedDrawing:YES];
	[cheatWindow setFrameAutosaveName:@"TCCheatWindow"];

	// set options
	if ( TCGlobalWindowsOnTop )
	{
		[cheatWindow setLevel:NSPopUpMenuWindowLevel];
	}

	// set up the server menu default items
	[serverMenu removeAllItems];
	[serverMenu addItemWithTitle:@"Not Connected" action:@selector(serverMenuDisconnect:) keyEquivalent:@""];
	[serverMenu addItemWithTitle:localName action:@selector(serverMenuLocal:) keyEquivalent:@""];
	[processMenu removeAllItems];
	
	// update server menu
	for ( i = 0; i < top; i++ )
	{
		menuItem = [[NSMenuItem alloc] initWithTitle:[(NSNetService *)[serverList objectAtIndex:i] name] action:@selector(serverMenuItem:) keyEquivalent:@""];
		
		[menuItem setTag:i];
		
		// if this is the first server, add a divider.
		if ( [serverMenu numberOfItems] <= 2 )
		{
			[serverMenu addItem:[NSMenuItem separatorItem]];
		}
		
		[serverMenu addItem:[menuItem autorelease]];
	}
	
	// give tags to the menu items.
	[[typeMenu itemWithTitle:@"Integer"] setTag:TYPE_INTEGER];
	[[typeMenu itemWithTitle:@"String"] setTag:TYPE_STRING];
	[[typeMenu itemWithTitle:@"Decimal"] setTag:TYPE_DECIMAL];
	[[typeMenu itemWithTitle:@"Unknown Value"] setTag:TYPE_UNKNOWN];
	[[stringSizeMenu itemWithTitle:@"8-bit"] setTag:SIZE_8_BIT];
	[[integerSizeMenu itemWithTitle:@"char"] setTag:SIZE_8_BIT];
	[[integerSizeMenu itemWithTitle:@"short"] setTag:SIZE_16_BIT];
	[[integerSizeMenu itemWithTitle:@"long"] setTag:SIZE_32_BIT];
	[[decimalSizeMenu itemWithTitle:@"float"] setTag:SIZE_32_BIT];
	[[decimalSizeMenu itemWithTitle:@"double"] setTag:SIZE_64_BIT];
	
	// set default state
	[statusText setStringValue:@""];
	[self setStatusDisconnected];
	
	// display the initial description text
	[self updateDescriptionText];
	
	// change sheet initial interface.
	[changeSecondsCombo setEnabled:NO];
}

- (void)updateSearchButton
{
	TCtype			type = [typePopup indexOfSelectedItem];
	
	if ( type != TYPE_UNKNOWN )
	{
		if ( [[searchTextField stringValue] isEqualToString:@""] )
		{
			[searchButton setEnabled:NO];
		}
		else
		{
			[searchButton setEnabled:YES];
		}
	}
	else
	{
		[searchButton setEnabled:YES];
	}
}

- (void)updatePauseButton
{
	if ( !targetPaused )
	{
		[pauseButton setTitle:@"Pause Target"];
	}
	else
	{
		[pauseButton setTitle:@"Resume Target"];
	}
}

- (void)updateSearchBoxes
{
	TCtype			type = [typePopup indexOfSelectedItem];
	
	if ( type != TYPE_UNKNOWN )
	{
		[searchTextField setEnabled:YES];
		[searchRadioMatrix setEnabled:NO];
	}
	else
	{
		[searchTextField setEnabled:NO];
		[searchRadioMatrix setEnabled:YES];
	}
}

- (void)updateChangeButton
{
	if ( addressSelected )
	{
		[changeButton setEnabled:YES];
	}
	else
	{
		[changeButton setEnabled:NO];
	}
}

- (void)updateDescriptionText
{
	TCtype			type = [[typePopup selectedItem] tag];
	TCsize			size = [[sizePopup selectedItem] tag];
	
	switch ( type )
	{
		case TYPE_STRING:
			[descriptionText setStringValue:@"A string is a series of characters.\n\nThis search allows you to find and change words and phrases.  Numbers can also be stored as strings, but they aren't recognized as numbers by the computer.  Changing strings probably won't change the game in a big way."];
			break;
			
		case TYPE_INTEGER:
			switch ( size )
			{
				case SIZE_8_BIT:
					[descriptionText setStringValue:@"An integer is a non-fraction number.\n\nExamples:   0, 1, 2, 3, 4\nRange: 0 - 255\n\nIntegers usually store variables like score, lives, and remaining ammo."];
					break;
					
				case SIZE_16_BIT:
					[descriptionText setStringValue:@"An integer is a non-fraction number.\n\nExamples: -1, 0, 1, 2, 3\nRange: -32,768 - 32,767\n\nIntegers usually store variables like score, lives, and remaining ammo."];
					break;
					
				case SIZE_32_BIT:
					[descriptionText setStringValue:@"An integer is a non-fraction number.\n\nExamples: -1, 0, 1, 2, 3\nRange: about -2 billion - 2 billion\n\nIntegers usually store variables like score, lives, and remaining ammo.  This is the most common size for integer variables."];
					break;
			}
			break;
			
		case TYPE_DECIMAL:
			[descriptionText setStringValue:@"A decimal is a fraction number.\n\nFloats and doubles are not often used as variables in games, but there may be other uses for cheating them.  Type in as many digits after the decimal place as possible to ensure that your input is matched with the variable you are looking for."];
			break;
	}
}


- (void)setStatusDisconnected
{
	if ( status == STATUS_DISCONNECTED ) return;
	lastStatus = status;
	status = STATUS_DISCONNECTED;
	
	[serverPopup setEnabled:YES];
	[pauseButton setTitle:@"Pause Target"];
	[pauseButton setEnabled:NO];
	[processPopup setEnabled:NO];
	[typePopup setEnabled:NO];
	[sizePopup setEnabled:NO];
	[searchTextField setEnabled:NO];
	[searchRadioMatrix setEnabled:NO];
	[searchButton setEnabled:NO];
	[clearSearchButton setEnabled:NO];
	[statusText addStatus:@"Not Connected" duration:CM_STATUS_FOREVER];
	[statusText setToolTip:@""];
	[statusBar stopAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change..."];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Not Connected"];
}

- (void)setStatusConnected
{
	if ( status == STATUS_CONNECTED ) return;
	lastStatus = status;
	status = STATUS_CONNECTED;
	
	[serverPopup setEnabled:YES];
	[self updatePauseButton];
	[pauseButton setEnabled:YES];
	[processPopup setEnabled:YES];
	[typePopup setEnabled:YES];
	[sizePopup setEnabled:YES];
	[self updateSearchBoxes];
	[self updateSearchButton];
	[clearSearchButton setEnabled:NO];
	[statusText addStatus:@"Connected" duration:CM_STATUS_FOREVER];
	[statusText setToolTip:@""];
	[statusBar stopAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change..."];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusCheating
{
	if ( status == STATUS_CHEATING ) return;
	lastStatus = status;
	status = STATUS_CHEATING;
	
	[serverPopup setEnabled:YES];
	[self updatePauseButton];
	[pauseButton setEnabled:YES];
	[processPopup setEnabled:NO];
	[typePopup setEnabled:NO];
	[sizePopup setEnabled:NO];
	[self updateSearchBoxes];
	[self updateSearchButton];
	[clearSearchButton setEnabled:YES];
	if ( searchResultsAmount <= searchResultsAmountDisplayed )
	{
		if ( searchResultsAmount == 1 )
		{
			[statusText addStatus:@"One Result" color:[NSColor colorWithCalibratedRed:0.0f green:0.5f blue:0.0f alpha:1.0f] duration:CM_STATUS_FOREVER];
		}
		else if ( searchResultsAmount == 0 )
		{
			[statusText addStatus:@"No Results" color:[NSColor colorWithCalibratedRed:0.5f green:0.0f blue:0.0f alpha:1.0f] duration:CM_STATUS_FOREVER];
		}
		else
		{
			[statusText addStatus:[NSString stringWithFormat:@"Results: %i", searchResultsAmount] duration:CM_STATUS_FOREVER];
		}
		[statusText setToolTip:@""];
	}
	else
	{
		[statusText addStatus:[NSString stringWithFormat:@"Results: >%i", searchResultsAmountDisplayed] duration:CM_STATUS_FOREVER];
		[statusText setToolTip:[NSString stringWithFormat:@"Results: %i", searchResultsAmount]];
	}
	[statusBar stopAnimation:self];
	[addressTable setEnabled:YES];
	[changeButton setTitle:@"Change..."];
	[self updateChangeButton];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusSearching
{
	if ( status == STATUS_SEARCHING ) return;
	lastStatus = status;
	status = STATUS_SEARCHING;
	
	[serverPopup setEnabled:NO];
	[self updatePauseButton];
	[pauseButton setEnabled:NO];
	[processPopup setEnabled:NO];
	[typePopup setEnabled:NO];
	[sizePopup setEnabled:NO];
	[searchTextField setEnabled:NO];
	[searchRadioMatrix setEnabled:NO];
	[searchButton setEnabled:NO];
	[clearSearchButton setEnabled:NO];
	[statusText addStatus:@"Searching..." duration:CM_STATUS_FOREVER];
	[statusText setToolTip:@""];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change..."];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusChanging
{
	if ( status == STATUS_CHANGING ) return;
	lastStatus = status;
	status = STATUS_CHANGING;
	
	if ( lastStatus != STATUS_CHANGING_CONTINUOUSLY )
	{
		[serverPopup setEnabled:NO];
		[self updatePauseButton];
		[pauseButton setEnabled:NO];
		[processPopup setEnabled:NO];
		[typePopup setEnabled:NO];
		[sizePopup setEnabled:NO];
		[searchTextField setEnabled:NO];
		[searchRadioMatrix setEnabled:NO];
		[searchButton setEnabled:NO];
		[clearSearchButton setEnabled:NO];
		[statusBar startAnimation:self];
		[addressTable setEnabled:NO];
		[changeButton setEnabled:NO];
		
		[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
	}
}

- (void)setStatusChangingLater
{
	if ( status == STATUS_CHANGING_LATER ) return;
	lastStatus = status;
	status = STATUS_CHANGING_LATER;
	
	[serverPopup setEnabled:NO];
	[self updatePauseButton];
	[pauseButton setEnabled:NO];
	[processPopup setEnabled:NO];
	[typePopup setEnabled:NO];
	[sizePopup setEnabled:NO];
	[searchTextField setEnabled:NO];
	[searchRadioMatrix setEnabled:NO];
	[searchButton setEnabled:NO];
	[clearSearchButton setEnabled:NO];
	[statusText addStatus:@"Changing Later..." duration:CM_STATUS_FOREVER];
	[statusText setToolTip:@""];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Cancel Change"];
	[changeButton setEnabled:YES];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusChangingContinuously
{
	if ( status == STATUS_CHANGING_CONTINUOUSLY ) return;
	lastStatus = status;
	status = STATUS_CHANGING_CONTINUOUSLY;
	
	[serverPopup setEnabled:NO];
	[self updatePauseButton];
	[pauseButton setEnabled:YES];
	[processPopup setEnabled:NO];
	[typePopup setEnabled:NO];
	[sizePopup setEnabled:NO];
	[searchTextField setEnabled:NO];
	[searchRadioMatrix setEnabled:NO];
	[searchButton setEnabled:NO];
	[clearSearchButton setEnabled:NO];
	[statusText addStatus:@"Repeating Change..." duration:CM_STATUS_FOREVER];
	[statusText setToolTip:@""];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Stop Change"];
	[changeButton setEnabled:YES];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusUndoing
{
	if ( status == STATUS_UNDOING ) return;
	lastStatus = status;
	status = STATUS_UNDOING;
	
	[serverPopup setEnabled:NO];
	[self updatePauseButton];
	[pauseButton setEnabled:NO];
	[processPopup setEnabled:NO];
	[typePopup setEnabled:NO];
	[sizePopup setEnabled:NO];
	[searchTextField setEnabled:NO];
	[searchRadioMatrix setEnabled:NO];
	[searchButton setEnabled:NO];
	[clearSearchButton setEnabled:NO];
	[statusText addStatus:@"Undoing..." duration:CM_STATUS_FOREVER];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change..."];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusRedoing
{
	if ( status == STATUS_REDOING ) return;
	lastStatus = status;
	status = STATUS_REDOING;
	
	[serverPopup setEnabled:NO];
	[self updatePauseButton];
	[pauseButton setEnabled:NO];
	[processPopup setEnabled:NO];
	[typePopup setEnabled:NO];
	[sizePopup setEnabled:NO];
	[searchTextField setEnabled:NO];
	[searchRadioMatrix setEnabled:NO];
	[searchButton setEnabled:NO];
	[clearSearchButton setEnabled:NO];
	[statusText addStatus:@"Redoing..." duration:CM_STATUS_FOREVER];
	[statusText setToolTip:@""];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change..."];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

/*- (void)setStatusToLast
{
	switch ( lastStatus )
	{
		case STATUS_DISCONNECTED:
			[self setStatusDisconnected];
			break;
			
		case STATUS_CONNECTED:
			[self setStatusConnected];
			break;
			
		case STATUS_CHEATING:
			[self setStatusCheating];
			break;
			
		case STATUS_SEARCHING:
			[self setStatusSearching];
			break;
			
		case STATUS_CHANGING:
			[self setStatusChanging];
			break;
			
		case STATUS_CHANGING_LATER:
			[self setStatusChangingLater];
			break;
			
		case STATUS_CHANGING_CONTINUOUSLY:
			[self setStatusChangingContinuously];
			break;
			
		case STATUS_UNDOING:
			[self setStatusUndoing];
			break;
			
		case STATUS_REDOING:
			[self setStatusRedoing];
			break;
	}
}*/

/*
- (void)setStatusText:(NSString *)msg duration:(NSTimeInterval)seconds
{
	[self setStatusText:msg duration:seconds color:[NSColor blackColor]];
}

- (void)setStatusText:(NSString *)msg duration:(NSTimeInterval)seconds color:(NSColor *)color
{
	if ( statusTextTimer )
	{
		[statusTextTimer invalidate];
		[statusTextTimer release], statusTextTimer = nil;
	}
	else
	{
		[savedStatusText release];
		[savedStatusColor release];
		savedStatusText = [[statusText stringValue] retain];
		savedStatusColor = [[statusText textColor] retain];
	}
	
	[statusText setTextColor:color];
	[statusText setStringValue:msg];
	
	if ( seconds != 0.0 )
	{
		statusTextTimer = [[NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(statusTextTimer:) userInfo:nil repeats:NO] retain];
	}
}

- (void)statusTextTimer:(NSTimer *)timer
{
	[statusText setTextColor:savedStatusColor];
	[statusText setStringValue:savedStatusText];
	
	[savedStatusColor release], savedStatusColor = nil;
	[savedStatusText release], savedStatusText = nil;
	[statusTextTimer invalidate];
	[statusTextTimer release], statusTextTimer = nil;
}*/


- (void)connectToLocal
{
	NSString			*localName = @"Local"; //[NSString stringWithFormat:@"%@ (local)", TCGlobalBroadcastName];
	
	// depending on how the listener is listening, we need to use different means to connect to local
	if ( TCGlobalListening )
	{
		if ( TCGlobalAllowRemote )
		{
			struct sockaddr_in	addr;

			addr.sin_family = AF_INET;
			addr.sin_port = htonl( TCGlobalListenPort );
			addr.sin_addr.s_addr = INADDR_ANY;

			[self connectToServer:[NSData dataWithBytes:&addr length:sizeof(addr)] name:localName];
		}
		else
		{
			struct sockaddr_un	addr;

			addr.sun_family = AF_UNIX;
			strncpy( addr.sun_path, TCDefaultListenPath, 103 );

			[self connectToServer:[NSData dataWithBytes:&addr length:sizeof(addr)] name:localName];
		}
	}
}

- (void)connectToServer:(NSData *)addr name:(NSString *)name
{
	everConnected = YES;
	
	if ( connection )
	{
		[self disconnect];
		
		waitingToConnect = YES;
		connectionAddress = [addr retain];
		connectionName = [name retain];
	}
	else
	{
		connection = [[CheatClient clientWithDelegate:self server:addr name:name] retain];
		connectionAddress = [addr retain];
		connectionName = [name retain];
	}

	[self setStatusConnected];
}

- (void)disconnect
{
	if ( connection )
	{
		[connection release], connection = nil;
		close( sockfd );

		[self clearSearch];

		[connectionAddress release], connectionAddress = nil;
		[connectionName release], connectionName = nil;

		[processMenu removeAllItems];

		[serverPopup selectItemAtIndex:0];
		[self setStatusDisconnected];
	}
}


- (void)sendProcessListRequest
{
	PacketHeader	header;
	int				length = sizeof(header);

	header.checksum = RandomChecksum();
	header.function = 1;
	header.size = 0;

	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendProcessListRequest failed on socket %i", sockfd );
	}
}

- (void)sendClearSearch
{
	PacketHeader	header;
	int				length = sizeof(header);
	
	header.checksum = RandomChecksum();
	header.function = 3;
	header.size = 0;
	
	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendClearSearch failed on socket %i", sockfd );
	}
}

- (void)sendSearch:(char const *)data size:(int)size
{
	PacketHeader	header;
	int				length = sizeof(header) + size;
	int				lengthAfter = length;

	char			*buffer, *ptr;

	header.checksum = RandomChecksum();
	header.function = 5;
	header.size = size;

	if ( (buffer = (char *)malloc( length )) == NULL )
	{
		CMLog( @"sendSearch:size: failed" );
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, data, size );

	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendSearch:size: failed" );
	}

	free( buffer );
}

- (void)sendChange:(char const *)data size:(int)size
{
	PacketHeader	header;
	int				length = sizeof(header) + size;
	int				lengthAfter = length;
	
	char			*buffer, *ptr;
	
	header.checksum = RandomChecksum();
	header.function = 8;
	header.size = size;
	
	if ( (buffer = (char *)malloc( length )) == NULL )
	{
		CMLog( @"sendChange:size: failed" );
	}
	
	ptr = buffer;
	
	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, data, size );
	
	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendChange:size: failed" );
	}
	
	free( buffer );
}

- (void)sendPauseTarget;
{
	PacketHeader	header;
	int				length = sizeof(header);

	header.checksum = RandomChecksum();
	header.function = 10;
	header.size = 0;

	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendPauseTarget failed" );
	}
}

- (void)sendVariableValueRequest
{

}

- (void)sendUndoRequest
{
	PacketHeader	header;
	int				length = sizeof(header);

	header.checksum = RandomChecksum();
	header.function = 14;
	header.size = 0;

	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendUndoRequest failed" );
	}
}

- (void)sendRedoRequest
{
	PacketHeader	header;
	int				length = sizeof(header);

	header.checksum = RandomChecksum();
	header.function = 16;
	header.size = 0;

	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendRedoRequest failed" );
	}
}

- (void)sendSetTargetPID:(int)pid
{
	PacketHeader	header;
	int				length = sizeof(header) + sizeof(u_int32_t);
	int				lengthAfter = length;

	u_int32_t		tarPID = (u_int32_t)pid;

	char			*buffer, *ptr;

	header.checksum = RandomChecksum();
	header.function = 18;
	header.size = sizeof(u_int32_t);

	if ( (buffer = (char *)malloc( length )) == NULL )
	{
		CMLog( @"sendSetTargetPID: failed" );
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, &tarPID, sizeof(tarPID) );

	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendSetTargetPID: failed" );
	}

	free( buffer );
}


- (void)receivedProcessList:(NSData *)data
{
	NSMenuItem		*item;
	u_int32_t		processCount = 0;

	char			*ptr = (char *)[data bytes];
	int				i, max;

	COPY_FROM_BUFFER( &processCount, ptr, sizeof(processCount) );

	max = (int)processCount;

	for ( i = 0; i < max; i++ )
	{
		u_int32_t	pid;
		NSString	*name;

		COPY_FROM_BUFFER( &pid, ptr, sizeof(pid) );
		name = [NSString stringWithCString:ptr], ptr += [name length] + 1;

		item = [[NSMenuItem alloc] initWithTitle:name action:@selector(processMenuItem:) keyEquivalent:@""];
		[item setTag:(int)pid];

		[processMenu addItem:[item autorelease]];
	}
}

- (void)receivedSearchFinished
{
	if ( searchResultsAmount == 1 )
	{
		TCPlaySound( @"Submarine" );
	}
	else if ( searchResultsAmount == 0 )
	{
		TCPlaySound( @"Basso" );
	}
	
	[self setStatusCheating];
	//[self setStatusText:@"Search Finished" duration:1.5];
	[cheatWindow makeFirstResponder:searchTextField];
}

- (void)receivedVariableList:(NSData *)data
{
	char			*ptr = (char *)[data bytes];

	[self destroyResults];

	COPY_FROM_BUFFER( &searchResultsAmount, ptr, sizeof(searchResultsAmount) );
	COPY_FROM_BUFFER( &searchResultsAmountDisplayed, ptr, sizeof(searchResultsAmountDisplayed) );

	if ( searchResultsAmountDisplayed > 0 )
	{
		int				memSize = TCAddressSize * searchResultsAmountDisplayed;
		// TCAddressSize*maxSearchResultsAmount;
		
		if ( (searchResults = (TCaddress *)malloc( memSize )) == NULL )
		{
			CMLog( @"receivedVariableList failed: malloc failed" );
			searchResultsAmount = 0;
			searchResultsAmountDisplayed = 0;
			return;
		}
		CMLog( @"CLIENT setting display amount to %i", searchResultsAmountDisplayed );

		COPY_FROM_BUFFER( searchResults, ptr, memSize );
	}

	[addressTable reloadData];
}

- (void)receivedChangeFinished
{
	if ( status != STATUS_CHANGING_CONTINUOUSLY )
	{
		TCPlaySound( @"Tink" );
		[self setStatusCheating];
	}
}

- (void)receivedError:(NSData *)data
{
	u_int32_t		fatal;
	NSString		*msg;

	char			*ptr = (char *)[data bytes];

	COPY_FROM_BUFFER( &fatal, ptr, sizeof(fatal) );

	msg = [NSString stringWithCString:ptr];
	
	// alert the user.
	[self handleErrorMessage:msg fatal:fatal];
}

- (void)receivedUndoFinished
{
	[self setStatusCheating];
}

- (void)receivedRedoFinished
{
	[self setStatusCheating];
}

- (void)receivedUndoRedoStatus:(NSData *)data
{
	char			*ptr = (char *)[data bytes];
	
	COPY_FROM_BUFFER( &undoCount, ptr, sizeof(undoCount) );
	COPY_FROM_BUFFER( &redoCount, ptr, sizeof(redoCount) );
	
	CMLog( @"UNDO: %i, REDO: %i", undoCount, redoCount );
}

- (void)receivedAppLaunched:(NSData *)data
{
	NSMenuItem		*item;

	char			*ptr = (char *)[data bytes];

	u_int32_t		pid;
	NSString		*name;

	COPY_FROM_BUFFER( &pid, ptr, sizeof(pid) );
	name = [NSString stringWithCString:ptr], ptr += [name length] + 1;

	item = [[NSMenuItem alloc] initWithTitle:name action:@selector(processMenuItem:) keyEquivalent:@""];
	[item setTag:(int)pid];

	[processMenu addItem:[item autorelease]];
}

- (void)receivedAppQuit:(NSData *)data
{
	u_int32_t		pid;
	
	char			*ptr = (char *)[data bytes];

	COPY_FROM_BUFFER( &pid, ptr, sizeof(pid) );

	[processMenu removeItemWithTag:pid];
}

- (void)receivedTargetQuit
{
	[self clearSearch];
	[self sendClearSearch];
	
	// tell the server that the first app is now the target.
	targetPID = [[processMenu itemAtIndex:0] tag];
	[self sendSetTargetPID:targetPID];
	
	// alert the user.
	TCPlaySound( @"Frog" );
	//[self handleErrorMessage:@"The application that was being cheated has quit." fatal:NO];
	
	[statusText addStatus:@"Target Quit"];
	[self setStatusConnected];
}

- (void)receivedPauseFinished:(NSData *)data
{
	char			*ptr = (char *)[data bytes];

	COPY_FROM_BUFFER( &targetPaused, ptr, sizeof(targetPaused) );
	
	[self updatePauseButton];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   Searching & Changing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)search
{
	TCtype			type = [[typePopup selectedItem] tag];
	TCsize			size = [[sizePopup selectedItem] tag];
	
	char			*data, *ptr;
	int				dataSize = sizeof(type) + sizeof(size) + sizeof(TCGlobalHitsDisplayed);
	
	data = (char *)malloc( dataSize );
	ptr = data;
	
	// copy the size and type of the variable.
	COPY_TO_BUFFER( ptr, &type, sizeof(type) );
	COPY_TO_BUFFER( ptr, &size, sizeof(size) );
	
	// copy the number of results to return.
	COPY_TO_BUFFER( ptr, &TCGlobalHitsDisplayed, sizeof(TCGlobalHitsDisplayed) );
	
	CMLog( @"type: %i, size: %i", type, size );
	
	// switch to cheating mode if this is the first search.
	if ( status == STATUS_CONNECTED )
	{
		[self setStatusCheating];
	}
	
	// copy the value to search for.
	switch ( type )
	{
		case TYPE_STRING:
		{
			switch ( size )
			{
				case SIZE_8_BIT:
				{
					NSString			*string = [searchTextField stringValue];
					int					stringLength = [string length] + 1;
					
					data = (char *)realloc( data, dataSize + stringLength );
					ptr = data + dataSize;
					dataSize += stringLength;
					
					COPY_TO_BUFFER( ptr, [string cString], stringLength );
				}
					break;
			}
		}
			break;
			
		case TYPE_INTEGER:
		{
			switch ( size )
			{
				case SIZE_8_BIT:
				{
					int8_t			value = [searchTextField intValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
					
				case SIZE_16_BIT:
				{
					int16_t			value = [searchTextField intValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
					
				case SIZE_32_BIT:
				{
					int32_t			value = [searchTextField intValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
			}
		}
			break;
			
		case TYPE_DECIMAL:
		{
			switch ( size )
			{
				case SIZE_32_BIT:
				{
					float			value = [searchTextField floatValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
					
				case SIZE_64_BIT:
				{
					double			value = [searchTextField doubleValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
			}
		}
			break;
			
		case TYPE_UNKNOWN:
		{
			u_int32_t		value = 0;//[searchTextField intValue];
			
			data = (char *)realloc( data, dataSize + sizeof(value) );
			ptr = data + dataSize;
			dataSize += sizeof(value);
			
			COPY_TO_BUFFER( ptr, &value, sizeof(value) );
		}
			break;
	}
	
	[self sendSearch:data size:dataSize];
	free( data );
	
	[self setStatusSearching];
}

- (void)change
{
	TCtype			type = [[typePopup selectedItem] tag];
	TCsize			size = [[sizePopup selectedItem] tag];
	
	int				i, addressCount = [changeSelectedItems count];
	
	char			*data, *ptr;
	int				dataSize = sizeof(type) + sizeof(size) + sizeof(addressCount) + TCAddressSize*addressCount;
	
	data = (char *)malloc( dataSize );
	ptr = data;
	
	// copy the size and type of the variable.
	COPY_TO_BUFFER( ptr, &type, sizeof(type) );
	COPY_TO_BUFFER( ptr, &size, sizeof(size) );

	// copy the amount and the list of addresses to change.
	COPY_TO_BUFFER( ptr, &addressCount, sizeof(addressCount) );
	for ( i = 0; i < addressCount; i++ )
	{
		COPY_TO_BUFFER( ptr, &((TCaddress *)searchResults)[ [[changeSelectedItems objectAtIndex:i] intValue] ], sizeof(TCaddress) );
	}
	
	// copy the new value.
	switch ( type )
	{
		case TYPE_STRING:
		{
			switch ( size )
			{
				case SIZE_8_BIT:
				{
					NSString			*string = [changeTextField stringValue];
					int					stringLength = [string length] + 1;
					
					data = (char *)realloc( data, dataSize + stringLength );
					ptr = data + dataSize;
					dataSize += stringLength;
					
					COPY_TO_BUFFER( ptr, [string cString], stringLength );
				}
					break;
			}
		}
			break;
			
		case TYPE_INTEGER:
		{
			switch ( size )
			{
				case SIZE_8_BIT:
				{
					int8_t			value = [changeTextField intValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
					
				case SIZE_16_BIT:
				{
					int16_t			value = [changeTextField intValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
					
				case SIZE_32_BIT:
				{
					int32_t			value = [changeTextField intValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
			}
		}
			break;
			
		case TYPE_DECIMAL:
		{
			switch ( size )
			{
				case SIZE_32_BIT:
				{
					float			value = [changeTextField floatValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
					
				case SIZE_64_BIT:
				{
					double			value = [changeTextField doubleValue];
					
					data = (char *)realloc( data, dataSize + sizeof(value) );
					ptr = data + dataSize;
					dataSize += sizeof(value);
					
					COPY_TO_BUFFER( ptr, &value, sizeof(value) );
				}
					break;
			}
		}
			break;
			
		case TYPE_UNKNOWN:
		{
			u_int32_t		value = 0;//[searchTextField intValue];
			
			data = (char *)realloc( data, dataSize + sizeof(value) );
			ptr = data + dataSize;
			dataSize += sizeof(value);
			
			COPY_TO_BUFFER( ptr, &value, sizeof(value) );
		}
			break;
	}
	
	[self sendChange:data size:dataSize];
	free( data );
}


- (void)changeSheet:(NSWindow *)sheet returned:(int)returned context:(void *)context
{
	if ( returned == 1 )
	{
		[changeSelectedItems release], changeSelectedItems = [[[addressTable selectedRowEnumerator] allObjects] retain];
		
		if ( [recurringChangeButton state] == NSOnState )
		{
			float			seconds = [changeSecondsCombo floatValue];
			
			[self setStatusChangingContinuously];
			
			[self change];
			
			changeTimer = [[NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(changeTimer:) userInfo:nil repeats:YES] retain];
		}
		else
		{
			[self change];
		}
	}
}


- (void)changeTimer:(NSTimer *)timer
{
	[self change];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   Cheat Window Interface
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (IBAction)typePopup:(id)sender
{
	switch ( [typePopup indexOfSelectedItem] )
	{
		case TYPE_STRING:
			[sizePopup setMenu:stringSizeMenu];
			break;

		case TYPE_INTEGER:
		case TYPE_UNKNOWN:
			[sizePopup setMenu:integerSizeMenu];
			break;

		case TYPE_DECIMAL:
			[sizePopup setMenu:decimalSizeMenu];
			break;
	}
	
	[self updateSearchBoxes];
	[self updateSearchButton];
	[self updateDescriptionText];
}

- (IBAction)sizePopup:(id)sender
{
	[self updateDescriptionText];
}


- (IBAction)searchButton:(id)sender
{
	/*if ( [searchTextField intValue] == 0 )
	{
		if ( NSRunAlertPanel( @"Warning", @"Performing a search with this value will probably take a long time.  You should try to search for the variable at a different value.", @"Search Anyway", @"Cancel", nil ) == NSAlertAlternateReturn )
		{
			return;
		}
	}*/
	
	[self search];
}

- (IBAction)clearSearchButton:(id)sender
{
	[self clearSearch];
	
	[statusText addStatus:@"Search Cleared" duration:1.5];
	[self setStatusConnected];

	[self sendClearSearch];
}


- (IBAction)changeButton:(id)sender
{
	[changeTimer invalidate];
	[changeTimer release], changeTimer = nil;
	
	if ( status == STATUS_CHANGING_CONTINUOUSLY )
	{
		[changeSelectedItems release], changeSelectedItems = nil;
		
		[self setStatusCheating];
	}
	else if ( status == STATUS_CHEATING )
	{
		[NSApp beginSheet:changeSheet modalForWindow:cheatWindow modalDelegate:self didEndSelector:@selector(changeSheet:returned:context:) contextInfo:NULL];
		//[NSApp runModalForWindow:changeSheet];
		//[NSApp endSheet:changeSheet];
		//[changeSheet orderOut:self];
	}
}


- (IBAction)serverMenuItem:(id)sender
{
	NSData				*data = [[[serverList objectAtIndex:[sender tag]] addresses] objectAtIndex:0];
/*	struct sockaddr_in	addr;

	[data getBytes:&addr];*/

	[self connectToServer:data name:[serverPopup titleOfSelectedItem]];
}

- (IBAction)serverMenuDisconnect:(id)sender
{
	[self disconnect];
}

- (IBAction)serverMenuLocal:(id)sender
{
	[self connectToLocal];
}

- (IBAction)processMenuItem:(id)sender
{
	targetPID = [sender tag];

	[self sendSetTargetPID:targetPID];
	
	[statusText addStatus:[NSString stringWithFormat:@"PID: %i", targetPID] duration:CM_STATUS_FOREVER];
}


- (IBAction)pauseButton:(id)sender
{
	[self sendPauseTarget];
}


- (void)undoMenu:(id)sender
{
	if ( undoCount == 1 )
	{
		[self clearSearchButton:self];
	}
	else
	{
		[self sendUndoRequest];

		[self setStatusUndoing];
	}
}

- (void)redoMenu:(id)sender
{
	[self sendRedoRequest];

	[self setStatusRedoing];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if ( aSelector == @selector(undoMenu:) )
	{
		if ( status == STATUS_CHEATING && undoCount > 0 )
		{
			return YES;
		}
		else
		{
			return NO;
		}
	}
	
	if ( aSelector == @selector(redoMenu:) )
	{
		if ( status == STATUS_CHEATING && redoCount > 0 )
		{
			return YES;
		}
		else
		{
			return NO;
		}
	}
	
	return [super respondsToSelector:aSelector];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   Change Sheet Interface
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (IBAction)cancelButton:(id)sender
{
	[changeSheet orderOut:sender];
	[NSApp endSheet:changeSheet returnCode:0];
	//[NSApp stopModal];
}

- (IBAction)okButton:(id)sender
{
	[changeSheet orderOut:sender];
	[NSApp endSheet:changeSheet returnCode:1];
	if ( [recurringChangeButton state] == NSOnState )
	{
		[self setStatusChangingContinuously];
	}
	else
	{
		[self setStatusChanging];
	}
	//[NSApp stopModal];
}


- (IBAction)recurringChangeButton:(id)sender
{
	if ( [recurringChangeButton state] == NSOnState )
	{
		[changeSecondsCombo setEnabled:YES];
	}
	else
	{
		[changeSecondsCombo setEnabled:NO];
	}
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   Cleaning Up
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)clearSearch
{
	undoCount = 0;
	redoCount = 0;
	
	targetPaused = NO;
	
	[changeTimer invalidate];
	[changeTimer release], changeTimer = nil;
	
	[self destroyResults];
	[addressTable reloadData];
}

- (void)destroyResults
{
	if ( searchResultsAmountDisplayed > 0 )
	{
		free( searchResults );
		
		searchResultsAmount = 0;
		searchResultsAmountDisplayed = 0;
	}
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self disconnect];
	
	// clean up status timer stuff
	[savedStatusColor release];
	[savedStatusText release];
	[statusTextTimer invalidate];
	[statusTextTimer release];
	
	[changeTimer invalidate];
	[changeTimer release];
	
	[self destroyResults];
	
	[changeSelectedItems release];
	
	[serverList release];
	[addressList release];

	[super dealloc];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   TCListener Notifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)listenerStarted:(NSNotification *)note
{
	if ( !everConnected )
	{
		[self connectToLocal];
	}
}

- (void)listenerStopped:(NSNotification *)note
{
	
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   TCWindowsOnTopChanged Notification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)windowsOnTopChanged:(NSNotification *)note
{
	if ( [[note object] boolValue] )
	{
		[cheatWindow setLevel:NSPopUpMenuWindowLevel];
	}
	else
	{
		[cheatWindow setLevel:NSNormalWindowLevel];
	}
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   TCWindowsOnTopChanged Notification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)handleErrorMessage:(NSString *)msg fatal:(BOOL)fatal
{
	CMLog( @"error received" );
	// close the change sheet if it's open.
	if ( [cheatWindow attachedSheet] )
	{
		[changeSheet orderOut:self];
		[NSApp endSheet:changeSheet returnCode:0];
	}
	
	// show message.
	NSBeginAlertSheet( fatal? @"Fatal Error":@"Error", @"OK", nil, nil, cheatWindow, nil, nil, nil, 0, msg );
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   Cheat Window Delegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (BOOL)windowShouldClose:(id)sender
{
	if ( sender == cheatWindow && ( status == STATUS_SEARCHING || status == STATUS_CHANGING ) )
	{
		NSBeep();
		return NO;
	}
	
	return YES;
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   ClientDelegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)clientConnectedWithSocket:(int)sock name:(NSString *)name
{
	// the client is reporting that a connection has been made.
	sockfd = sock;

	[self sendProcessListRequest];
	
	[serverPopup selectItemWithTitle:name];
	
	[self setStatusConnected];
}

- (void)clientDisconnected
{
	// if there is a pending connection, connect now.
	if ( waitingToConnect )
	{
		waitingToConnect = NO;
		connection = [[CheatClient clientWithDelegate:self server:connectionAddress name:connectionName] retain];
	}
	// if our connection variable is still valid, we were disconnected unexpectedly.
	else if ( connection )
	{
		[self disconnect];
		NSBeginAlertSheet( @"Network Failure", @"OK", nil, nil, cheatWindow, nil, nil, nil, 0, @"The server has disconnected you." );
	}
}

- (void)clientError:(NSString *)error message:(NSString *)message
{
	NSBeginAlertSheet( error, @"OK", nil, nil, cheatWindow, nil, nil, nil, 0, message );
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   NSToolbar Delegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
*** A toolbar is no longer used, but the code still remains for possible future use. ***
 
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem		*item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

	if ( [itemIdentifier isEqualToString:@"Disconnect"] )
	{
		disconnectButton = item;
		
        [item setLabel:@"Disconnect"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"disconnect"]];
        [item setTarget:self];
		[item setToolTip:@"Click here to pause or unpause the program being cheated."];
    }
	else if ( [itemIdentifier isEqualToString:@"ServerPopup"] )
	{
		NSRect		fRect = [typePopup frame];
		NSSize		fSize = NSMakeSize( FLT_MAX, fRect.size.height );
		NSMenuItem	*menu = [[NSMenuItem alloc] initWithTitle:@"Server" action:@selector(serverPopup:) keyEquivalent:@""];

		[menu setSubmenu:[serverPopup menu]];
		
        [item setLabel:@"Server"];
        [item setPaletteLabel:[item label]];
        [item setView:serverPopup];
		[item setMinSize:fRect.size];
		[item setMaxSize:fSize];
		[item setMenuFormRepresentation:[menu autorelease]];
		[item autorelease];
    }

    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		@"Disconnect", @"ServerPopup", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:@"Disconnect", @"ServerPopup", nil];
}*/


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   NSTableView Data Source/Delegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)controlTextDidChange:(NSNotification *)aNotification
{
	[self updateSearchButton];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   NSTableView Data Source/Delegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (int)numberOfRowsInTableView:(NSTableView *)table
{
	return searchResultsAmountDisplayed;
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	return [NSString stringWithFormat:@"%0.8X", ((TCaddress *)searchResults)[row]];
}

- (void)tableView:(NSTableView *) setObjectValue:(id)object forTableColumn:(NSTableColumn *)column row:(int)row
{
	return;
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
	if ( [addressTable selectedRow] != -1 )
	{
		addressSelected = YES;
	}
	else
	{
		addressSelected = NO;
	}
	
	[self updateChangeButton];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   Global Browser Notifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)browserServerFound:(NSNotification *)note
{
	NSNetService				*service = (NSNetService *)[note object];
	
	NSString					*name = [service name];
	int							tag = [serverList count] - 1;
	NSMenuItem					*item;
	
	CMLog( @"server found" );
	
	if ( [serverMenu itemWithTitle:name] == nil )
	{
		item = [[NSMenuItem alloc] initWithTitle:[service name] action:@selector(serverMenuItem:) keyEquivalent:@""];
		
		[item setTag:tag];
		
		// if this is the first server, add a divider.
		if ( [serverMenu numberOfItems] <= 2 )
		{
			[serverMenu addItem:[NSMenuItem separatorItem]];
		}
		
		//[serverList addObject:service];
		[serverMenu addItem:[item autorelease]];
		
		// select the item if we are already connected to the server.
		// this could happen if the server rebroadcast as a different name.
		if ( connection && [[[service addresses] objectAtIndex:0] isEqualToData:connectionAddress] )
		{
			[serverPopup selectItemWithTitle:[service name]];
		}
	}
}

- (void)browserServerLost:(NSNotification *)note
{
	NSNetService				*service = (NSNetService *)[note object];
	NSString					*name = [service name];
	
	int							i, top = [serverMenu numberOfItems];
	
	for ( i = [serverMenu indexOfItemWithTitle:name] + 1; i < top; i++ )
	{
		[[serverMenu itemWithTitle:name] setTag:[[serverMenu itemWithTitle:name] tag] - 1];
	}
	
	[serverMenu removeAllItemsWithTitle:name];
	
	// if this is the last broadcast server, take away the divider.
	if ( [serverMenu numberOfItems] == 3 )
	{
		[serverMenu removeItemAtIndex:2];
	}
}


@end


// Internal Functions
void TCPlaySound( NSString *name )
{
	if ( TCGlobalPlaySounds )
	{
		[[NSSound soundNamed:name] play];
	}
}
