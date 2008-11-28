
// **********************************************************************
// The Cheat - A universal game cheater for Mac OS X
// (C) 2003-2005 Chaz McGarvey (BrokenZipper)
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 1, or (at your option)
// any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
// 

#import "CheatDocument.h"


// GLOBALS
// service browsing globals
unsigned static _tc_document_count = 0;
NSNetServiceBrowser static *_tc_service_browser = nil;
NSMutableArray static *_tc_cheat_services = nil;
// global target
Process static *_tc_target = nil;


@interface CheatDocument ( PrivateAPI )

// mode switching
- (void)_switchTo:(NSView *)destination from:(NSView *)source;
// using the service browser
+ (void)_documentCreated;
+ (void)_documentDestroyed;
// service addition/removal
- (void)_cheatServiceFound:(NSNotification *)note;
- (void)_cheatServiceRemoved:(NSNotification *)note;
// interface
- (void)_setupInitialInterface;
// notifications
- (void)_displayValuesPrefChanged:(NSNotification *)note;
- (void)_windowOnTopPrefChanged:(NSNotification *)note;
- (void)_hitsDisplayedPrefChanged:(NSNotification *)note;

@end

@interface NSTableView ( PrivateAPI )

- (NSRange)_rowsInRectAssumingRowsCoverVisible:(NSRect)rect;

@end


@implementation CheatDocument


// #############################################################################
#pragma mark Initialization
// #############################################################################

- (id)init // designated
{
	if ( self = [super init] )
	{
		NSNotificationCenter *nc= [NSNotificationCenter defaultCenter];
		
		ChazLog( @"init doc %X", self );
		[CheatDocument _documentCreated];
		
		// register for service change notifications
		[nc addObserver:self selector:@selector(_cheatServiceFound:) name:TCServiceFoundNote object:nil];
		[nc addObserver:self selector:@selector(_cheatServiceRemoved:) name:TCServiceRemovedNote object:nil];
		
		_cheatData = [[CheatData alloc] init];
		_searchData = [[SearchData alloc] init];
		
		// show search mode when documents are first created
		_connectsOnOpen = YES;
		[self setMode:TCSearchMode];
	}
	return self;
}

- (id)initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)docType
{
	if ( self = [super initWithContentsOfFile:fileName ofType:docType] )
	{
		// if document opened from a file, show cheat mode by default
		[self setMode:TCCheatMode];
	}
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)aURL ofType:(NSString *)docType
{
	if ( self = [super initWithContentsOfURL:aURL ofType:docType] )
	{
		// if document opened from a URL, show cheat mode by default
		[self setMode:TCCheatMode];
	}
	return self;
}

- (void)dealloc
{
	ChazLog( @"dealloc doc %X", self );
	
	// unregister observers
	[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_cheater setDelegate:nil];
	[self disconnectFromCheater];
	
	[_cheatData release];
	[_searchData release];
	
	[_serverObject release];
	[_process release];
	
	// release the fade if one is occuring
	[_fadeView removeFromSuperview];
	[_fadeView release];
	
	[CheatDocument _documentDestroyed];
	
	[super dealloc];
}


// #############################################################################
#pragma mark Nib Loading
// #############################################################################

- (NSString *)windowNibName
{
    return @"CheatDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	
	NSNotificationCenter *nc= [NSNotificationCenter defaultCenter];
	
	// register for app launch/quit notifications
	[nc addObserver:self selector:@selector(_displayValuesPrefChanged:) name:TCDisplayValuesChangedNote object:nil];
	[nc addObserver:self selector:@selector(_windowOnTopPrefChanged:) name:TCWindowsOnTopChangedNote object:nil];
	[nc addObserver:self selector:@selector(_hitsDisplayedPrefChanged:) name:TCHitsDisplayedChangedNote object:nil];
	
	// setup window frame saving
	[ibWindow useOptimizedDrawing:YES];
	[ibWindow setFrameAutosaveName:@"TCCheatWindow"];
	
	// set options
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCWindowsOnTopPref] )
	{
		[ibWindow setLevel:NSPopUpMenuWindowLevel];
	}

	// display one of the modes
	if ( _mode == TCCheatMode ) {
		[self _switchTo:ibCheatContentView from:ibPlaceView];
	}
	else if ( _mode == TCSearchMode ) {
		[self _switchTo:ibSearchContentView from:ibPlaceView];
	}
	
	// configure the initial interface
	[self _setupInitialInterface];
	
	// update interface
	[ibStatusText setDefaultStatus:[self defaultStatusString]];
	[self updateInterface];
	
	// automatically connect to the local cheater
	if ( _connectsOnOpen ) {
		[self ibSetLocalCheater:nil];
	}
	
	ChazLog( @"superview: %@", [[ibSearchVariableTable superview] superview] );
}


// #############################################################################
#pragma mark Handling Files
// #############################################################################

- (NSData *)dataRepresentationOfType:(NSString *)type
{
    return [NSArchiver archivedDataWithRootObject:_cheatData];
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type
{
	[_cheatData release];
	_cheatData = nil;
	
	if ( [type isEqualToString:@"Cheat Document"] ) {
		NS_DURING
			_cheatData = [[NSUnarchiver unarchiveObjectWithData:data] retain];
		NS_HANDLER
			if ( !_cheatData ) {
				// alert the user of the unparsable file
				NSBeep();
				NSRunAlertPanel( @"The Cheat can't read file.", @"The file \"%@\" can't be read.  It is probably not a cheat file, or it may be corrupted.", @"OK", nil, nil, [self fileName] );
				return NO;
			}
		NS_ENDHANDLER
	}
	
	[self updateInterface];
	
    return YES;
}


// #############################################################################
#pragma mark Service Finding
// #############################################################################

+ (NSArray *)cheatServices
{
	return [NSArray arrayWithArray:_tc_cheat_services];
}


- (void)_cheatServiceFound:(NSNotification *)note
{
	NSMenuItem *menuItem;
	NSNetService *item = [note object];
	
	// add the newly found service to the server popup
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTarget:self];
	[menuItem setAction:@selector(ibSetRemoteCheater:)];
	[menuItem setTitle:[item name]];
	[menuItem setRepresentedObject:item];
	[self addServer:menuItem];
	[menuItem release];
}

- (void)_cheatServiceRemoved:(NSNotification *)note
{
	NSNetService *item = [note object];
	
	// remove the service from the menu
	[self removeServerWithObject:item];
}


// using the service browser
+ (void)_documentCreated
{
	_tc_document_count++;
	
	if ( _tc_document_count == 1 ) {
		// first document created, so start the service browser
		[_tc_service_browser stop];
		[_tc_cheat_services release];
		// create and setup the browser
		_tc_service_browser = [[NSNetServiceBrowser alloc] init];
		[_tc_service_browser setDelegate:self];
		[_tc_service_browser searchForServicesOfType:@"_cheat._tcp." inDomain:@""];
		// create the service array
		_tc_cheat_services = [[NSMutableArray alloc] init];
	}
}

+ (void)_documentDestroyed
{
	_tc_document_count--;
	
	if ( _tc_document_count == 0 ) {
		// last document destroyed, so stop the service browser
		[_tc_service_browser stop];
		[_tc_cheat_services release];
		// set the globals to nil for safety
		_tc_service_browser = nil;
		_tc_cheat_services = nil;
	}
}


// NSNetServiceBrowser delegate methods
+ (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
	ChazLog( @"service browser will search" );
}

+ (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
	// if the browser stops we assume it needs to die.
	ChazLog( @"service browser did stop search" );
	[browser release];
}

+ (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorDict
{
	ChazLog( @"service browser failed with error code: %i", [[errorDict objectForKey:NSNetServicesErrorCode] intValue] );
}

+ (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	ChazLog( @"service browser found service: %@", [aNetService name] );
	
	// ignore if this is the local server.
	if ( [[(AppController *)NSApp cheatServer] isListening] &&
		 [[aNetService name] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:TCBroadcastNamePref]] ) {
		return;
	}
	
	[_tc_cheat_services addObject:aNetService];
	// send a notification for the new service
	[[NSNotificationCenter defaultCenter] postNotificationName:TCServiceFoundNote object:aNetService];
}

+ (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	ChazLog( @"service browser removed service: %@", [aNetService name] );
	
	[_tc_cheat_services removeObject:aNetService];
	// send a notification for the new service
	[[NSNotificationCenter defaultCenter] postNotificationName:TCServiceRemovedNote object:aNetService];
}


// #############################################################################
#pragma mark Changing Mode
// #############################################################################

- (void)setMode:(TCDocumentMode)mode
{
	// if the nib isn't loaded, change the mode
	if ( !ibWindow ) {
		_mode = mode;
	}
}


- (void)switchToCheatMode
{
	NSResponder *responder = [ibWindow firstResponder];
	
	if ( [responder isKindOfClass:[NSText class]] ) {
		/* Since text views et al. make the field editor the first
		responder, you have to take its delegate since that will
		be set to the actual text view. */
		responder = [(NSText *)responder delegate];
	}
	
	if ( _mode == TCCheatMode ) {
		return;
	}
	_mode = TCCheatMode;
	[self _switchTo:ibCheatContentView from:ibSearchContentView];
	
	// update the next key view
	[ibProcessPopup setNextKeyView:ibCheatVariableTable];
	// update current key view
	if ( !_lastResponder || _lastResponder == ibWindow ) {
		// set default responder
		[ibWindow makeFirstResponder:ibCheatVariableTable];
	}
	else {
		[ibWindow makeFirstResponder:_lastResponder];
	}
	_lastResponder = responder;
}

- (void)switchToSearchMode
{
	NSResponder *responder = [ibWindow firstResponder];
	
	if ( [responder isKindOfClass:[NSText class]] ) {
		responder = [(NSText *)responder delegate];
	}
	
	if ( _mode == TCSearchMode ) {
		return;
	}
	_mode = TCSearchMode;
	[self _switchTo:ibSearchContentView from:ibCheatContentView];
	
	// update the next key view
	[ibProcessPopup setNextKeyView:ibSearchTypePopup];
	// update current key view
	if ( !_lastResponder || _lastResponder == ibWindow ) {
		[ibWindow makeFirstResponder:ibSearchValueField];
	}
	else {
		[ibWindow makeFirstResponder:_lastResponder];
	}
	_lastResponder = responder;
}


- (void)_switchTo:(NSView *)destination from:(NSView *)source
{
	NSView *contentView = [ibWindow contentView];
	NSRect frame = [source frame];
	NSImage *fadeImage = nil;
	
	if ( gFadeAnimationDuration != 0.0 && [source lockFocusIfCanDraw] ) {
		// draw the view to the representation
		NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[source bounds]];
		[source unlockFocus];
		
		// create the image object
		fadeImage = [[NSImage alloc] initWithSize:frame.size];
		[fadeImage addRepresentation:imageRep];
		
		if ( _fadeView ) {
			// remove the old fade view
			[_fadeView removeFromSuperview];
			[_fadeView release];
		}
		
		// create the new fade view and start the fade
		_fadeView = [[FadeView alloc] initWithFrame:frame];
		[_fadeView setAutoresizingMask:[source autoresizingMask]];
		[_fadeView setDelegate:self];
		[_fadeView setImage:fadeImage];
		[_fadeView setFadeDuration:gFadeAnimationDuration];
		[contentView addSubview:_fadeView];
		[_fadeView startFadeAnimation];
		
		[fadeImage release];
	}
	
	// update view size of incoming view
	[destination setFrame:frame];
	// replace the views
	[contentView replaceSubview:source with:destination];
}


// FadeView Delegate
- (void)fadeViewFinishedAnimation:(FadeView *)theView
{
	[_fadeView removeFromSuperview];
	[_fadeView release];
	_fadeView = nil;
}


// #############################################################################
#pragma mark Accessors
// #############################################################################

- (NSString *)defaultStatusString
{
	if ( !_cheater ) {
		return @"Not Connected";
	}
	return [NSString stringWithFormat:@"Connected to %@.", [_cheater hostAddress]];
}

- (BOOL)isLoadedFromFile
{
	return ([self fileName] != nil);
}


- (void)addServer:(NSMenuItem *)item
{
	NSMenu *serverMenu = [ibServerPopup menu];
	
	if ( item ) {
		if ( [serverMenu numberOfItems] <= 2 ) {
			// separator line
			[serverMenu addItem:[NSMenuItem separatorItem]];
		}
		[serverMenu addItem:item];
	}
}

- (void)removeServerWithObject:(id)serverObject
{
	NSMenu *serverMenu = [ibServerPopup menu];
	
	if ( serverObject ) {
		[serverMenu removeItemWithRepresentedObject:serverObject];
		if ( [serverMenu numberOfItems] == 3 ) {
			// separator line
			[serverMenu removeItemAtIndex:2];
		}
	}
}


// #############################################################################
#pragma mark Interface
// #############################################################################

- (void)_setupInitialInterface
{
	NSMenu *serverMenu;
	NSMenuItem *menuItem;
	
	NSArray *cheatServices;
	unsigned i, len;
	
	// create and set the server popup menu
	serverMenu = [[NSMenu alloc] init];
	[serverMenu setAutoenablesItems:YES];
	// add menu items
	// local connection item
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTarget:self];
	[menuItem setAction:@selector(ibSetLocalCheater:)];
	[menuItem setTitle:@"On This Computer"];
	[menuItem setRepresentedObject:[NSNull null]];
	[serverMenu addItem:menuItem];
	[menuItem release];
	// arbitrary connection item
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTarget:self];
	[menuItem setAction:@selector(ibRunCustomServerSheet:)];
	[menuItem setTitle:[NSString stringWithFormat:@"Other Server%C", 0x2026]];
	[menuItem setKeyEquivalent:@"k"];
	[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
	[serverMenu addItem:menuItem];
	[menuItem release];
	// set the menu
	[ibServerPopup setMenu:serverMenu];
	[serverMenu release];
	
	// add current list of rendezvous services
	cheatServices = [CheatDocument cheatServices];
	len = [cheatServices count];
	for ( i = 0; i < len; i++ ) {
		NSNetService *item = [cheatServices objectAtIndex:i];
		menuItem = [[NSMenuItem alloc] init];
		[menuItem setTarget:self];
		[menuItem setAction:@selector(ibSetRemoteCheater:)];
		[menuItem setTitle:[item name]];
		[menuItem setRepresentedObject:item];
		[self addServer:menuItem];
		[menuItem release];
	}
	
	[ibSearchVariableTable setDoubleAction:@selector(ibAddSearchVariable:)];
	[ibSearchVariableTable setCanDelete:NO];
	
	// BUG: for some reason IB doesn't like to set the default selection
	// for an NSMatrix to anything but the first cell, so set this explicitly.
	[ibSearchValueUsedMatrix selectCellWithTag:TCGivenValue];
	
	// we use undoing/redoing for reverting search results
	[self setHasUndoManager:NO];
}

- (void)updateInterface
{
	if ( _cheatData )
	{
		// if there is cheat data, fill in the data information
		[ibWindow setTitle:[self displayName]];
		if ( [_cheatData process] ) {
			if ( [[_cheatData cheatInfo] isEqualToString:@""] ) {
				[ibCheatInfoText setStringValue:[NSString stringWithFormat:@"%@ %@",
					[_cheatData gameName],
					[_cheatData gameVersion]]];
			}
			else {
				[ibCheatInfoText setStringValue:[NSString stringWithFormat:@"%@ %@ - %@",
					[_cheatData gameName],
					[_cheatData gameVersion],
					[_cheatData cheatInfo]]];
			}
		}
		else {
			[ibCheatInfoText setStringValue:[_cheatData cheatInfo]];
		}
		
		[ibCheatRepeatButton setState:[_cheatData repeats]];
		[ibCheatRepeatField setDoubleValue:[_cheatData repeatInterval]];
	}
	
	// if we're connected...
	if ( _cheater )
	{
		if ( _status == TCIdleStatus )
		{
			// WINDOW
			[ibServerPopup setEnabled:YES];
			[ibProcessPopup setEnabled:YES];
			// SEARCH MODE
			[ibSearchValueUsedMatrix setEnabled:YES];
			if ( [_searchData hasSearchedOnce] ) {
				[ibSearchTypePopup setEnabled:NO];
				[ibSearchIntegerSignMatrix setEnabled:NO];
				[[ibSearchValueUsedMatrix cellWithTag:TCLastValue] setEnabled:YES];
				if ( [_searchData valueUsed] == TCGivenValue ) {
					[ibSearchValueField setEnabled:YES];
				}
				else {
					[ibSearchValueField setEnabled:NO];
				}
				[ibSearchClearButton setEnabled:YES];
				[ibSearchVariableTable setEnabled:YES];
				int selectedRows = [ibSearchVariableTable numberOfSelectedRows];
				if ( selectedRows > 0 ) {
					[ibSearchVariableButton setEnabled:YES];
				}
				else {
					[ibSearchVariableButton setEnabled:NO];
				}
			}
			else {
				[ibSearchTypePopup setEnabled:YES];
				if ( [_searchData isTypeInteger] ) {
					[ibSearchIntegerSignMatrix setEnabled:YES];
				}
				else {
					[ibSearchIntegerSignMatrix setEnabled:NO];
				}
				[[ibSearchValueUsedMatrix cellWithTag:TCLastValue] setEnabled:NO];
				[ibSearchValueUsedMatrix selectCellWithTag:[_searchData valueUsed]];
				[ibSearchValueField setEnabled:YES];
				[ibSearchClearButton setEnabled:NO];
				[ibSearchVariableTable setEnabled:NO];
				[ibSearchVariableButton setEnabled:NO];
			}
			if ( [_searchData variableType] != TCString ) {
				[ibSearchOperatorPopup setEnabled:YES];
			}
			else {
				[ibSearchOperatorPopup setEnabled:NO];
			}
			[ibSearchButton setTitle:@"Search"];
			[ibSearchButton setAction:@selector(ibSearch:)];
			[ibSearchButton setKeyEquivalent:@""];
			[ibSearchButton setEnabled:YES];
			// CHEAT MODE
			[ibCheatVariableTable setEnabled:YES];
			[ibCheatRepeatButton setEnabled:YES];
			[ibCheatRepeatAuxText setTextColor:[NSColor controlTextColor]];
			[ibCheatRepeatField setEnabled:[_cheatData repeats]];
			[ibCheatButton setTitle:@"Apply Cheat"];
			[ibCheatButton setAction:@selector(ibCheat:)];
			[ibCheatButton setKeyEquivalent:@"\r"];
			if ( [_cheatData enabledVariableCount] > 0 ) {
				[ibCheatButton setEnabled:YES];
				if ( [[_cheatData process] sameApplicationAs:_process] ) {
					[ibCheatButton setKeyEquivalent:@"\r"];
				}
				else {
					[ibCheatButton setKeyEquivalent:@""];
				}
			}
			else {
				[ibCheatButton setEnabled:NO];
			}
		}
		else
		{
			// WINDOW
			[ibServerPopup setEnabled:NO];
			[ibProcessPopup setEnabled:NO];
			// SEARCH MODE
			[ibSearchTypePopup setEnabled:NO];
			[ibSearchIntegerSignMatrix setEnabled:NO];
			[ibSearchOperatorPopup setEnabled:NO];
			[ibSearchValueUsedMatrix setEnabled:NO];
			[ibSearchValueField setEnabled:NO];
			[ibSearchClearButton setEnabled:NO];
			[ibSearchVariableTable setEnabled:NO];
			[ibSearchVariableButton setEnabled:NO];
			// CHEAT MODE
			[ibCheatVariableTable setEnabled:NO];
			[ibCheatRepeatButton setEnabled:NO];
			[ibCheatRepeatAuxText setTextColor:[NSColor disabledControlTextColor]];
			[ibCheatRepeatField setEnabled:NO];
			
			if ( _status == TCSearchingStatus ) {
				[ibSearchButton setTitle:@"Cancel"];
				[ibSearchButton setAction:@selector(ibCancelSearch:)];
				[ibSearchButton setKeyEquivalent:@"\E"];
				[ibSearchButton setEnabled:!_isCancelingTask];
				[ibCheatButton setTitle:@"Apply Cheat"];
				[ibCheatButton setAction:@selector(ibCheat:)];
				if ( [[_cheatData process] sameApplicationAs:_process] ) {
					[ibCheatButton setKeyEquivalent:@"\r"];
				}
				else {
					[ibCheatButton setKeyEquivalent:@""];
				}
				[ibCheatButton setEnabled:NO];
			}
			else if ( _status == TCCheatingStatus ) {
				[ibSearchButton setTitle:@"Search"];
				[ibSearchButton setAction:@selector(ibSearch:)];
				[ibSearchButton setKeyEquivalent:@""];
				[ibSearchButton setEnabled:NO];
				[ibCheatButton setTitle:@"Stop Cheat"];
				[ibCheatButton setAction:@selector(ibStopCheat:)];
				[ibCheatButton setKeyEquivalent:@"\E"];
				[ibCheatButton setEnabled:!_isCancelingTask];
			}
			else {
				[ibSearchButton setTitle:@"Search"];
				[ibSearchButton setAction:@selector(ibSearch:)];
				[ibSearchButton setKeyEquivalent:@""];
				[ibSearchButton setEnabled:NO];
				[ibCheatButton setTitle:@"Apply Cheat"];
				[ibCheatButton setAction:@selector(ibCheat:)];
				if ( [[_cheatData process] sameApplicationAs:_process] ) {
					[ibCheatButton setKeyEquivalent:@"\r"];
				}
				else {
					[ibCheatButton setKeyEquivalent:@""];
				}
				[ibCheatButton setEnabled:NO];
			}
		}
	}
	else
	{
		// WINDOW
		[ibServerPopup setEnabled:YES];
		[ibProcessPopup setEnabled:NO];
		// SEARCH MODE
		[ibSearchTypePopup setEnabled:NO];
		[ibSearchIntegerSignMatrix setEnabled:NO];
		[ibSearchOperatorPopup setEnabled:NO];
		[ibSearchValueUsedMatrix setEnabled:NO];
		[ibSearchValueField setEnabled:NO];
		[ibSearchButton setEnabled:NO];
		[ibSearchClearButton setEnabled:NO];
		[ibSearchVariableTable setEnabled:NO];
		[ibSearchVariableButton setEnabled:NO];
		// CHEAT MODE
		[ibCheatVariableTable setEnabled:NO];
		[ibCheatRepeatButton setEnabled:NO];
		[ibCheatRepeatAuxText setTextColor:[NSColor disabledControlTextColor]];
		[ibCheatRepeatField setEnabled:NO];
		[ibCheatButton setEnabled:NO];
	}
}


- (void)setActualResults:(unsigned)count
{
	unsigned recieved = [_searchData numberOfResults];
	
	if ( count == 0 ) {
		[ibSearchVariableTable setToolTip:@""];
	}
	else if ( recieved == count ) {
		if ( count == 1 ) {
			[ibSearchVariableTable setToolTip:[NSString stringWithFormat:@"Displaying one result."]];
		}
		else {
			[ibSearchVariableTable setToolTip:[NSString stringWithFormat:@"Displaying %i results.", count]];
		}
	}
	else if ( recieved < count ) {
		[ibSearchVariableTable setToolTip:[NSString stringWithFormat:@"Displaying %i of %i results.", recieved, count]];
	}
}


- (NSString *)displayName
{
	// override the default window title if there is a custom one
	NSString *title = [_cheatData windowTitle];
	
	if ( !title || [title isEqualToString:@""] ) {
		return [super displayName];
	}
	return title;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	//ChazLog( @"validate menuitem: %@", [menuItem title] );
	
	// the undo/redo
	if ( [menuItem action] == @selector(ibUndo:) ) {
		if ( [_searchData undoesLeft] > 0 ) {
			return YES;
		}
		else {
			return NO;
		}
	}
	if ( [menuItem action] == @selector(ibRedo:) ) {
		if ( [_searchData redoesLeft] > 0 ) {
			return YES;
		}
		else {
			return NO;
		}
	}
	
	// the add variables items
	if ( [menuItem action] == @selector(ibAddCheatVariable:) && _status == TCCheatingStatus ) {
		return NO;
	}

	// the 'pause' menu item
	if ( [menuItem tag] == 1000 ) {
		if ( !_cheater ) {
			return NO;
		}
		if ( _isTargetPaused ) {
			[menuItem setTitle:@"Resume Target"];
			[menuItem setAction:@selector(ibResumeTarget:)];
		}
		else {
			[menuItem setTitle:@"Pause Target"];
			[menuItem setAction:@selector(ibPauseTarget:)];
		}
	}
	
	// the 'memory dump' menu item
	else if ( [menuItem tag] == 1001 ) {
		if ( !_cheater || _status != TCIdleStatus ) {
			return NO;
		}
	}
	// the 'mode switch' menu item
	else if ( [menuItem tag] == 1002 ) {
		if ( _mode == TCSearchMode ) {
			[menuItem setTitle:@"Show Cheat Mode"];
		}
		else /* _mode == TCCheatMode */ {
			[menuItem setTitle:@"Show Search Mode"];
		}
	}
	// the 'edit variables' menu item
	else if ( [menuItem tag] == 1003 ) {
		return (_mode == TCCheatMode && [ibCheatVariableTable selectedRow] != -1);
	}
	// the 'clear search' menu item
	else if ( [menuItem tag] == 1004 ) {
		return [ibSearchClearButton isEnabled];
	}
	// the cancel menu item
	else if ( [menuItem tag] == 1005 ) {
		if ( !_cheater || _isCancelingTask ) {
			return NO;
		}
		if ( _status == TCSearchingStatus ) {
			[menuItem setTitle:@"Cancel Search"];
			[menuItem setAction:@selector(ibCancelSearch:)];
		}
		else if ( _status == TCCheatingStatus ) {
			[menuItem setTitle:@"Stop Cheat"];
			[menuItem setAction:@selector(ibStopCheat:)];
		}
		else if ( _status == TCDumpingStatus ) {
			[menuItem setTitle:@"Cancel Dump"];
			[menuItem setAction:@selector(ibCancelDump:)];
		}
		else {
			return NO;
		}
	}
	
	return [super validateMenuItem:menuItem];
}


- (void)setDocumentChanged
{
	// only count document changes if there are variables
	// and if the pref is set
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCAskForSavePref] &&
		 ([_cheatData variableCount] > 0 || [self isLoadedFromFile]) ) {
		[self updateChangeCount:NSChangeDone];
	}
}


- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if ( aTableView == ibCheatVariableTable ) {
		return [_cheatData variableCount];
	}
	else if ( aTableView == ibSearchVariableTable ) {
		return [_searchData numberOfResults];
	}
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	
	if ( aTableView == ibCheatVariableTable ) {
		Variable *variable = [_cheatData variableAtIndex:rowIndex];
		
		if ( [identifier isEqualToString:@"enable"] ) {
			return [NSNumber numberWithBool:[variable isEnabled]];
		}
		else if ( [identifier isEqualToString:@"variable"] ) {
			return [variable typeString];
		}
		else if ( [identifier isEqualToString:@"address"] ) {
			return [variable addressString];
		}
		else if ( [identifier isEqualToString:@"value"] ) {
			return [variable stringValue];
		}
	}
	else if ( aTableView == ibSearchVariableTable ) {
		return [_searchData stringForRow:rowIndex];
	}
	return @"";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	
	if ( aTableView == ibCheatVariableTable ) {
		Variable *variable = [_cheatData variableAtIndex:rowIndex];
		
		if ( [identifier isEqualToString:@"address"] ) {
			if ( [variable setAddressString:anObject] ) {
				[self setDocumentChanged];
			}
		}
		else if ( [identifier isEqualToString:@"value"] ) {
			if ( [variable setStringValue:anObject] ) {
				[self setDocumentChanged];
			}
		}
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *aTableView = [aNotification object];
	
	if ( aTableView == ibSearchVariableTable ) {
		int selectedRows = [aTableView numberOfSelectedRows];
		if ( selectedRows > 1 ) {
			[ibSearchVariableButton setTitle:@"Add Variables"];
		}
		else if (  selectedRows == 1 ) {
			[ibSearchVariableButton setTitle:@"Add Variable"];
		}
	}
}


- (BOOL)tableViewDidReceiveEnterKey:(NSTableView *)tableView
{
	if ( tableView == ibSearchVariableTable ) {
		[ibSearchVariableButton performClick:nil];
		return YES;
	}
	return NO;
}

- (BOOL)tableViewDidReceiveSpaceKey:(NSTableView *)tableView
{
	if ( tableView == ibCheatVariableTable ) {
		[self ibSetVariableEnabled:nil];
		return YES;
	}
	return NO;
}

- (NSString *)tableViewPasteboardType:(NSTableView *)tableView
{
	return @"TCVariablePboardType";
}

- (NSData *)tableView:(NSTableView *)tableView copyRows:(NSArray *)rows
{
	NSMutableArray *vars;
	int i, top;
	
	top = [rows count];
	vars = [[NSMutableArray alloc] initWithCapacity:top];
	
	// add the new variables
	if ( tableView == ibSearchVariableTable ) {
		for ( i = 0; i < top; i++ ) {
			unsigned index = [[rows objectAtIndex:i] unsignedIntValue];
			[vars addObject:[_searchData variableAtIndex:index]];
		}
	}
	else {
		for ( i = 0; i < top; i++ ) {
			unsigned index = [[rows objectAtIndex:i] unsignedIntValue];
			[vars addObject:[_cheatData variableAtIndex:index]];
		}
	}
	
	return [NSArchiver archivedDataWithRootObject:[vars autorelease]];
}

- (void)tableView:(NSTableView *)tableView pasteRowsWithData:(NSData *)rowData
{
	NSArray *vars = [NSUnarchiver unarchiveObjectWithData:rowData];
	int i, top, lastRow;
	
	if ( tableView == ibSearchVariableTable ) {
		NSBeep();
		return;
	}
	
	top = [vars count];
	for ( i = 0; i < top; i++ ) {
		Variable *var = [vars objectAtIndex:i];
		[_cheatData addVariable:var];
	}
	
	lastRow = [_cheatData variableCount]-1;
	[tableView reloadData];
	if ( MacOSXVersion() >= 0x1030 ) {
		[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastRow] byExtendingSelection:NO];
	}
	else {
		[tableView selectRow:lastRow byExtendingSelection:NO];
	}
	[tableView scrollRowToVisible:lastRow];
	
	[self setDocumentChanged];
	[self updateInterface];
}

- (void)tableView:(NSTableView *)tableView deleteRows:(NSArray *)rows
{
	int i, len;
	
	if ( tableView == ibCheatVariableTable ) {
		len = [rows count];
		for ( i = len-1; i >= 0; i-- ) {
			[_cheatData removeVariableAtIndex:[[rows objectAtIndex:i] unsignedIntValue]];
		}
		// reselect the last item if the selection is now invalid
		len = [_cheatData variableCount] - 1;
		if ( [tableView selectedRow] > len ) {
			if ( MacOSXVersion() >= 0x1030 ) {
				[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:len] byExtendingSelection:NO];
			}
			else {
				[tableView selectRow:len byExtendingSelection:NO];
			}
		}
		[tableView reloadData];
		
		[self setDocumentChanged];
		[self updateInterface];
	}
}

// VariableTable Delegate
- (void)tableView:(NSTableView *)aTableView didChangeVisibleRows:(NSRange)rows
{
	ChazLog( @"new visible rows: %@", NSStringFromRange( rows ) );
	if ( [_searchData valuesLoaded] ) {
		[self watchVariables];
	}
}


// #############################################################################
#pragma mark Utility
// #############################################################################

+ (void)setGlobalTarget:(Process *)target
{
	[target retain];
	[_tc_target release];
	_tc_target = target;
}

+ (Process *)globalTarget
{
	return _tc_target;
}


- (void)showError:(NSString *)error
{
	NSColor *red = [NSColor colorWithCalibratedRed:0.7 green:0.0 blue:0.0 alpha:1.0];
	NSBeep();
	[ibStatusText setDefaultStatus:[self defaultStatusString]];
	[ibStatusText setTemporaryStatus:[NSString stringWithFormat:@"Error: %@", error] color:red duration:7.0];
}


- (BOOL)shouldConnectWithServer:(NSMenuItem *)item
{
	id serverObject;
	
	if ( _resolvingService ) {
		// don't connect if a service is being resolved
		[ibServerPopup selectItemAtIndex:[ibServerPopup indexOfItemWithRepresentedObject:_resolvingService]];
		return NO;
	}
	
	if ( [item respondsToSelector:@selector(representedObject)] ) {
		serverObject = [item representedObject];
	}
	else {
		serverObject = [NSNull null];
	}
	
	if ( [_serverObject isEqual:serverObject] ) {
		// already connected, don't connect
		return NO;
	}
	return YES;
}

- (void)selectConnectedCheater
{
	int index = [ibServerPopup indexOfItemWithRepresentedObject:_serverObject];
	if ( index != -1 ) {
		[ibServerPopup selectItemAtIndex:index];
	}
}

- (void)connectWithServer:(NSMenuItem *)item
{
	id serverObject;
	
	if ( [item respondsToSelector:@selector(representedObject)] ) {
		serverObject = [item representedObject];
	}
	else {
		serverObject = [NSNull null];
	}
	
	// save a reference to the server object
	[serverObject retain];
	[_serverObject release];
	_serverObject = serverObject;
}

- (void)disconnectFromCheater
{
	NSMenu *blankMenu;
	
	// don't do anything if we are already disconnected
	if ( !_cheater ) {
		return;
	}
	
	_status = TCIdleStatus;
	
	// clear the search
	[_searchData clearResults];
	
	//[ibSearchVariableTable reloadData]; // this can cause a crash, so commenting it out for now.
	// clear the selected process
	[_process release];
	_process = nil;
	[_serverObject release];
	_serverObject = nil;
	
	if ( ![self isLoadedFromFile] ) {
		[_cheatData setProcess:nil];
	}
	
	// clear the process menu
	blankMenu = [[NSMenu alloc] initWithTitle:@""];
	[blankMenu addItemWithTitle:@"" action:NULL keyEquivalent:@""];
	[ibProcessPopup setMenu:blankMenu];
	[blankMenu release];
	
	// kill the connection
	[_cheater disconnect];
	[_cheater release];
	_cheater = nil;
}


- (void)setConnectOnOpen:(BOOL)flag
{
	_connectsOnOpen = flag;
}

- (void)connectWithURL:(NSString *)url
{
	NSMenu *serverMenu = [ibServerPopup menu];
	NSURL *theUrl = [NSURL URLWithString:url];
	
	NSString *host;
	int port;
	
	NSData *addrData;
	int indexIfAlreadyExists;
	
	host = [theUrl host];
	port = [[theUrl port] intValue];
	
	if ( !host ) {
		NSBeginInformationalAlertSheet( @"The Cheat can't parse the URL.", @"OK", nil, nil, ibWindow, self, NULL, NULL, NULL,
										@"The Cheat can't connect to the server because \"%@\" is not a valid URL.", url );
		goto FAILURE;
	}
	
	// use default port number
	if ( !port ) {
		port = TCDefaultListenPort;
	}
	
	addrData = [MySocket addressWithHost:host port:port];
	if ( !addrData ) {
		NSBeginInformationalAlertSheet( @"The Cheat can't find the server.", @"OK", nil, nil, ibWindow, self, NULL, NULL, NULL,
										@"The Cheat can't connect to the server \"%@\" because it can't be found.", host );
		goto FAILURE;
	}
	
	indexIfAlreadyExists = [serverMenu indexOfItemWithRepresentedObject:addrData];
	if ( indexIfAlreadyExists == -1 ) {
		NSMenuItem *menuItem;
		// add the newly found service to the server popup
		menuItem = [[NSMenuItem alloc] init];
		[menuItem setTarget:self];
		[menuItem setAction:@selector(ibSetCustomCheater:)];
		[menuItem setTitle:[NSString stringWithFormat:@"%@:%i", host, port]];
		[menuItem setRepresentedObject:addrData];
		[self addServer:menuItem];
		// select new item
		[self ibSetCustomCheater:menuItem];
		// cleanup
		[menuItem release];
	}
	else {
		// select matching item
		[self ibSetCustomCheater:[serverMenu itemAtIndex:indexIfAlreadyExists]];
	}
	
FAILURE:;
	[self selectConnectedCheater];
}


- (void)watchVariables
{
	NSRange range;
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCDisplayValuesPref] ) {
		float interval = [[NSUserDefaults standardUserDefaults] floatForKey:TCValueUpdatePref];
		
		range = [ibSearchVariableTable visibleRows];
		[_cheater watchVariablesAtIndex:range.location count:range.length interval:interval];
	}
	else {
		[_cheater stopWatchingVariables];
	}
}


// #############################################################################
#pragma mark Notifications
// #############################################################################

- (void)_displayValuesPrefChanged:(NSNotification *)note
{
	[self watchVariables];
}

- (void)_windowOnTopPrefChanged:(NSNotification *)note
{
	ChazLog( @"_windowOnTopPrefChanged" );
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCWindowsOnTopPref] ) {
		[ibWindow setLevel:NSPopUpMenuWindowLevel];
	}
	else {
		[ibWindow setLevel:NSNormalWindowLevel];
	}
}

- (void)_hitsDisplayedPrefChanged:(NSNotification *)note
{
	// send preferences to the cheater
	[_cheater limitReturnedResults:[[NSUserDefaults standardUserDefaults] integerForKey:TCHitsDisplayedPref]];
}


@end
