
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      MyDocument.m
// Created:   Sun Sep 07 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "MyDocument.h"

#import "CheatClient.h"


// Internal Functions
void TCPlaySound( NSString *name );


@implementation MyDocument

- (id)init
{
    if ( self = [super init] )
	{
		NSNotificationCenter		*nc = [NSNotificationCenter defaultCenter];
		
		// initialize stuff
		sockfd = -1;
		serverList = [[NSMutableArray alloc] init];
		addressList = [[NSMutableArray alloc] init];
		
		// set up the network browser
		browser = [[NSNetServiceBrowser alloc] init];
		[browser setDelegate:self];
		[browser searchForServicesOfType:@"_cheat._tcp." inDomain:@"local."];

		// notifications to receive
		[nc addObserver:self selector:@selector(listenerStarted:) name:@"TCListenerStarted" object:nil];
		[nc addObserver:self selector:@selector(listenerStopped:) name:@"TCListenerStopped" object:nil];
		[nc addObserver:self selector:@selector(windowsOnTopChanged:) name:@"TCWindowsOnTopChanged" object:nil];

		[self connectToLocal];
	}
	
    return self;
}

- (NSString *)windowNibName
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
}


- (void)close
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
	
	[super close];
}


- (void)initialInterfaceSetup
{
	NSString			*localName = @"Local"; //[NSString stringWithFormat:@"%@ (local)", TCGlobalBroadcastName];
	
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


- (void)setStatusDisconnected
{
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
	[self setStatusText:@"Not Connected" duration:0];
	[statusBar stopAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change…"];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Not Connected"];
}

- (void)setStatusConnected
{
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
	[self setStatusText:@"Connected" duration:0];
	[statusBar stopAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change…"];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusCheating
{
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
	if ( searchResultsAmount < TCMaxSearchResults )
	{
		if ( searchResultsAmount == 1 )
		{
			[self setStatusText:[NSString stringWithFormat:@"Results: %i", searchResultsAmount] duration:0 color:[NSColor colorWithCalibratedRed:0.0f green:0.5f blue:0.0f alpha:1.0f]];
		}
		else if ( searchResultsAmount == 0 )
		{
			[self setStatusText:[NSString stringWithFormat:@"Results: %i", searchResultsAmount] duration:0 color:[NSColor colorWithCalibratedRed:0.5f green:0.0f blue:0.0f alpha:1.0f]];
		}
		else
		{
			[self setStatusText:[NSString stringWithFormat:@"Results: %i", searchResultsAmount] duration:0];
		}
	}
	else
	{
		[self setStatusText:[NSString stringWithFormat:@"Results: >%i", TCMaxSearchResults] duration:0];
	}
	[statusBar stopAnimation:self];
	[addressTable setEnabled:YES];
	[changeButton setTitle:@"Change…"];
	[self updateChangeButton];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusSearching
{
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
	[self setStatusText:@"Searching…" duration:0];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change…"];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusChanging
{
	lastStatus = status;
	status = STATUS_CHANGING;
	
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
	[self setStatusText:@"Changing…" duration:0];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusChangingLater
{
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
	[self setStatusText:@"Changing Later…" duration:0];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Cancel Change"];
	[changeButton setEnabled:YES];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusChangingContinuously
{
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
	[self setStatusText:@"Repeated Change" duration:0];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Stop Change"];
	[changeButton setEnabled:YES];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusUndoing
{
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
	[self setStatusText:@"Undoing…" duration:0];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change…"];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusRedoing
{
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
	[self setStatusText:@"Redoing…" duration:0];
	[statusBar startAnimation:self];
	[addressTable setEnabled:NO];
	[changeButton setTitle:@"Change…"];
	[changeButton setEnabled:NO];
	
	[[serverMenu itemAtIndex:0] setTitle:@"Disconnect"];
}

- (void)setStatusToLast
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
}

- (void)setStatusText:(NSString *)msg duration:(NSTimeInterval)seconds
{
	[self setStatusText:msg duration:seconds color:[NSColor blackColor]];
}

- (void)setStatusText:(NSString *)msg duration:(NSTimeInterval)seconds color:(NSColor *)color
{
	if ( seconds == 0 )
	{
		[statusText setTextColor:color];
		[statusText setStringValue:msg];
	}
	else
	{
		if ( statusTextTimer )
		{
			[statusTextTimer invalidate];
			[statusTextTimer release];
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
}


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
		NSLog( @"sendProcessListRequest failed on socket %i", sockfd );
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
		NSLog( @"sendClearSearch failed on socket %i", sockfd );
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
		NSLog( @"sendSearch:size: failed" );
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, data, size );

	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		NSLog( @"sendSearch:size: failed" );
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
		NSLog( @"sendChange:size: failed" );
	}
	
	ptr = buffer;
	
	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, data, size );
	
	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		NSLog( @"sendChange:size: failed" );
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
		NSLog( @"sendPauseTarget failed" );
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
		NSLog( @"sendUndoRequest failed" );
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
		NSLog( @"sendRedoRequest failed" );
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
		NSLog( @"sendSetTargetPID: failed" );
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, &tarPID, sizeof(tarPID) );

	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		NSLog( @"sendSetTargetPID: failed" );
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
	
	[self setStatusToLast];
	[self setStatusText:@"Search Finished" duration:1.5];
	[cheatWindow makeFirstResponder:searchTextField];
}

- (void)receivedVariableList:(NSData *)data
{
	char			*ptr = (char *)[data bytes];

	[self destroyResults];

	COPY_FROM_BUFFER( &searchResultsAmount, ptr, sizeof(searchResultsAmount) );

	if ( searchResultsAmount > 0 )
	{
		int				memSize = TCAddressSize*searchResultsAmount;
		
		if ( (searchResults = (TCaddress *)malloc( memSize )) == NULL )
		{
			NSLog( @"receivedVariableList failed: malloc failed" );
			searchResultsAmount = 0;
			return;
		}

		COPY_FROM_BUFFER( searchResults, ptr, memSize );
	}

	[addressTable reloadData];
}

- (void)receivedChangeFinished
{
	TCPlaySound( @"Tink" );
	
	[self setStatusToLast];
	[self setStatusText:@"Change Finished" duration:1.5];
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
	[self setStatusToLast];
}

- (void)receivedRedoFinished
{
	[self setStatusToLast];
}

- (void)receivedUndoRedoStatus:(NSData *)data
{
	char			*ptr = (char *)[data bytes];
	
	COPY_FROM_BUFFER( &undoCount, ptr, sizeof(undoCount) );
	COPY_FROM_BUFFER( &redoCount, ptr, sizeof(redoCount) );
	
	NSLog( @"UNDO: %i, REDO: %i", undoCount, redoCount );
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
	[self handleErrorMessage:@"The application that was being cheated has quit." fatal:NO];
	
	[self setStatusConnected];
}

- (void)receivedPauseFinished:(NSData *)data
{
	char			*ptr = (char *)[data bytes];

	COPY_FROM_BUFFER( &targetPaused, ptr, sizeof(targetPaused) );

	if ( targetPaused )
	{
		[self setStatusText:@"Target Paused" duration:1.5];
	}
	else
	{
		[self setStatusText:@"Target Resumed" duration:1.5];
	}
	
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
	int				dataSize = sizeof(type) + sizeof(size);
	
	data = (char *)malloc( dataSize );
	ptr = data;
	
	// copy the size and type of the variable.
	COPY_TO_BUFFER( ptr, &type, sizeof(type) );
	COPY_TO_BUFFER( ptr, &size, sizeof(size) );
	
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
	
	NSArray			*selectedAddresses = [[addressTable selectedRowEnumerator] allObjects];
	int				i, addressCount = [selectedAddresses count];
	
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
		COPY_TO_BUFFER( ptr, &((TCaddress *)searchResults)[ [[selectedAddresses objectAtIndex:i] intValue] ], sizeof(TCaddress) );
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
	
	[self setStatusChanging];
}


- (void)changeSheet:(NSWindow *)sheet returned:(int)returned context:(void *)context
{
	if ( returned == 1 )
	{
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
}


- (IBAction)searchButton:(id)sender
{
	[self search];
}

- (IBAction)clearSearchButton:(id)sender
{
	[self clearSearch];
	
	[self setStatusConnected];
	[self setStatusText:@"Search Cleared" duration:1.5];

	[self sendClearSearch];
}


- (IBAction)changeButton:(id)sender
{
	[changeTimer invalidate];
	[changeTimer release], changeTimer = nil;
	
	if ( status == STATUS_CHANGING_CONTINUOUSLY )
	{
		[self setStatusCheating];
	}
	else if ( status = STATUS_CHEATING )
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

	[self setStatusText:[NSString stringWithFormat:@"PID: %i", targetPID] duration:0];
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
	if ( searchResultsAmount > 0 )
	{
		free( searchResults );
		
		searchResultsAmount = 0;
	}
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self disconnect];

	[browser release];

	[serverList release];
	[addressList release];
	
	// clean up status timer stuff
	[savedStatusColor release];
	[savedStatusText release];
	[statusTextTimer invalidate];
	[statusTextTimer release];
	
	[changeTimer invalidate];
	[changeTimer release];
	
	[self destroyResults];

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
	if ( TCGlobalWindowsOnTop )
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
	return (searchResultsAmount <= TCMaxSearchResults) ? searchResultsAmount : TCMaxSearchResults;
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
%%%%%%%%%%%%%%%%%%%%%%   NSNetServiceBrowser Delegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)more
{
	// a server has broadcast; not much use until it's resolved.
	[service setDelegate:self];
	[service resolve];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)more
{
	[serverMenu removeAllItemsWithTitle:[service name]];
	
	// if this is the last broadcast server, take away the divider.
	if ( [serverMenu numberOfItems] == 3 )
	{
		[serverMenu removeItemAtIndex:2];
	}
}

- (void)netServiceDidResolveAddress:(NSNetService *)service
{
	NSString		*name = [service name];
	int				tag = [serverList count];
	NSMenuItem		*item;
	
	if ( [serverMenu itemWithTitle:name] == nil )
	{
		item = [[NSMenuItem alloc] initWithTitle:[service name] action:@selector(serverMenuItem:) keyEquivalent:@""];
		
		[item setTag:tag];
		
		// if this is the first server, add a divider.
		if ( [serverMenu numberOfItems] <= 2 )
		{
			[serverMenu addItem:[NSMenuItem separatorItem]];
		}
		
		[serverList addObject:service];
		[serverMenu addItem:[item autorelease]];
		
		// select the item if we are already connected to the server.
		// this could happen if the server rebroadcast as a different name.
		if ( connection && [[[service addresses] objectAtIndex:0] isEqualToData:connectionAddress] )
		{
			[serverPopup selectItemWithTitle:[service name]];
		}
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
