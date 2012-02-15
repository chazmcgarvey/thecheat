
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "CheatDocument.h"


@implementation CheatDocument ( DocCheaterDelegate )


- (void)cheaterDidConnect:(Cheater *)cheater
{
	ChazLog( @"cheaterDidConnect:" );
	[ibStatusText setDefaultStatus:[self defaultStatusString]];
	// update the interface
	[self updateInterface];
}

- (void)cheaterDidDisconnect:(Cheater *)cheater
{
	ChazLog( @"cheaterDidDisonnect:" );
	[self disconnectFromCheater];
	// update status
	[self showError:@"Disconnected by server."];
	[ibStatusBar setIndeterminate:NO];
	[ibStatusBar setDoubleValue:0.0];
	[ibStatusBar stopAnimation:self];
	// update the interface
	[self updateInterface];
}


- (void)cheaterRequiresAuthentication:(Cheater *)cheater
{
	ChazLog( @"cheaterRequiresAuthentication:" );
	
	[self ibRunPasswordSheet:nil];
}

- (void)cheaterRejectedPassword:(Cheater *)cheater
{
	ChazLog( @"cheaterRejectedPassword" );
	
	
}

- (void)cheaterAcceptedPassword:(Cheater *)cheater
{
	ChazLog( @"cheaterAcceptedPassword" );
	
	[ibStatusText setTemporaryStatus:@"Password Accepted"];
}


- (void)cheater:(Cheater *)cheater didFindProcesses:(NSArray *)processes
{
	NSMenu *processMenu;
	NSMenuItem *menuItem;
	
	unsigned i, len;
	
	Process *selectThis = nil;
	
	ChazLog( @"cheater:didFindProcesses:" );
	
	// create and set the server popup menu
	processMenu = [[NSMenu alloc] init];
	[processMenu setAutoenablesItems:YES];

	// add menu items
	// processes returned
	len = [processes count];
	for ( i = 0; i < len; i++ ) {
		Process *item = [processes objectAtIndex:i];
		
		menuItem = [[NSMenuItem alloc] init];
		[menuItem setTarget:self];
		[menuItem setAction:@selector(ibSetProcess:)];
		[menuItem setTitle:[item name]];
		[menuItem setImage:[item icon]];
		[menuItem setRepresentedObject:item];
		[processMenu addItem:menuItem];
		[menuItem release];
		
		// check and see if our document uses this application
		if ( [self isLoadedFromFile] && [[_cheatData process] sameApplicationAs:item] ) {
			selectThis = item;
		}
	}
	// set the menu
	[ibProcessPopup setMenu:processMenu];
	[processMenu release];
	
	// if we're loaded from a file, select the process matching
	// the one saved, if it is launched.
	if ( selectThis ) {
		[_cheater setTarget:selectThis];
	}
	// otherwise, select the global target
	else if ( (selectThis = [CheatDocument globalTarget]) ) {
		ChazLog( @"setting global target" );
		[_cheater setTarget:selectThis];
	}
	// otherwise, select the first process in this list
	else if ( len > 0 ) {
		[_cheater setTarget:[processes objectAtIndex:0]];
	}
}

- (void)cheater:(Cheater *)cheater didAddProcess:(Process *)process
{
	NSMenu *processMenu = [ibProcessPopup menu];
	NSMenuItem *menuItem;
	
	Process *savedTarget = [_cheatData process];
	
	// add the newly found process to the process popup
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTarget:self];
	[menuItem setAction:@selector(ibSetProcess:)];
	[menuItem setTitle:[process name]];
	[menuItem setImage:[process icon]];
	[menuItem setRepresentedObject:process];
	[processMenu addItem:menuItem];
	[menuItem release];
	
	// make this the target if appropiate
	if ( _status == TCIdleStatus &&
		 ![_searchData hasSearchedOnce] &&
		 [savedTarget sameApplicationAs:process] &&
		 ![savedTarget sameApplicationAs:_process] ) {
		[_cheater setTarget:process];
	}
}

- (void)cheater:(Cheater *)cheater didRemoveProcess:(Process *)process
{
	NSMenu *processes = [ibProcessPopup menu];
	// remove the service from the menu
	[processes removeItemWithRepresentedObject:process];
	
	// if this is the current process, select the first one
	if ( [_process isEqual:process] ) {
		[_process release];
		_process = nil;
		
		if ( [processes numberOfItems] > 0 ) {
			[_cheater setTarget:[[processes itemAtIndex:0] representedObject]];
		}
	}
}


- (void)cheater:(Cheater *)cheater didSetTarget:(Process *)target
{
	ChazLog( @"cheater:setTarget:" );
	
	// save a reference to the process
	[_process release];
	_process = [target retain];
	
	[CheatDocument setGlobalTarget:_process];
	
	// make sure the correct item is selected
	[ibProcessPopup selectItemAtIndex:[ibProcessPopup indexOfItemWithRepresentedObject:target]];
	//[ibProcessPopup selectItemWithTitle:[target name]];
	
	// apply the name and version to the document if the doc isn't saved
	if ( ![self isLoadedFromFile] ) {
		[_cheatData setProcess:target];
	}
	
	[ibStatusText setTemporaryStatus:[NSString stringWithFormat:@"Target is %@.", [target name]] duration:2.0];
	[self updateInterface];
}

- (void)cheaterPausedTarget:(Cheater *)cheater
{
	_isTargetPaused = YES;
	[ibStatusText setTemporaryStatus:@"Target Paused"];
}

- (void)cheaterResumedTarget:(Cheater *)cheater
{
	_isTargetPaused = NO;
	[ibStatusText setTemporaryStatus:@"Target Resumed"];
}


- (void)cheater:(Cheater *)cheater didFindVariables:(TCArray)variables actualAmount:(unsigned)count
{
	if ( _status == TCSearchingStatus ) {
		_status = TCIdleStatus;
		
		// do something with the variables
		[_searchData setAddresses:variables];
		[_searchData didAddResults];
		[ibSearchVariableTable reloadData];
		
		[self setActualResults:count];
		
		[ibStatusText setDefaultStatus:[self defaultStatusString]];
		if ( count == 1 ) {
			NSColor *green = [NSColor colorWithCalibratedRed:0.0 green:0.7 blue:0.0 alpha:1.0];
			[ibStatusText setTemporaryStatus:[NSString stringWithFormat:@"Search found one result.", count] color:green duration:6.0];
		}
		else if ( count == 0 ) {
			NSColor *red = [NSColor colorWithCalibratedRed:0.7 green:0.0 blue:0.0 alpha:1.0];
			[ibStatusText setTemporaryStatus:[NSString stringWithFormat:@"Search found no results.", count] color:red duration:6.0];
		}
		else {
			[ibStatusText setTemporaryStatus:[NSString stringWithFormat:@"Search found %i results.", count] duration:6.0];
		}
		[ibStatusBar setIndeterminate:NO];
		[ibStatusBar setDoubleValue:0.0];
		[ibStatusBar stopAnimation:self];
		
		[self updateInterface];
		if ( _mode == TCSearchMode ) {
			[ibWindow makeFirstResponder:ibSearchValueField];
		}
	}
}

- (void)cheater:(Cheater *)cheater didFindValues:(TCArray)values
{
	[_searchData setValues:values];
	[ibSearchVariableTable reloadData];
	
	[self watchVariables];
}

- (void)cheaterDidCancelSearch:(Cheater *)cheater
{
	ChazLog( @"cheaterDidCancelSearch:" );
	
	if ( _isCancelingTask ) {
		_status = TCIdleStatus;
		_isCancelingTask = NO;
		
		[ibStatusText setDefaultStatus:[self defaultStatusString]];
		[ibStatusText setTemporaryStatus:@"Search cancelled." duration:2.0];
		[ibStatusBar setIndeterminate:NO];
		[ibStatusBar setDoubleValue:0.0];
		[ibStatusBar stopAnimation:self];
		
		[self updateInterface];
		if ( _mode == TCSearchMode ) {
			[ibWindow makeFirstResponder:ibSearchValueField];
		}
	}
}

- (void)cheaterDidClearSearch:(Cheater *)cheater
{
	[_searchData clearResults];
	[ibSearchVariableTable reloadData];
	
	[self setActualResults:0];
	
	[ibStatusText setTemporaryStatus:@"The search was cleared." duration:2.0];
	[self updateInterface];
}


- (void)cheater:(Cheater *)cheater didDumpMemory:(NSData *)memoryDump
{
	NSSavePanel *panel;
	
	ChazLog( @"cheater:didDumpMemory:" );
	
	ChazLog( @"status: %i", _status );
	if ( _status == TCDumpingStatus ) {
		_status = TCIdleStatus;
		
		panel = [NSSavePanel savePanel];
		[panel setAllowedFileTypes:[NSArray arrayWithObjects: @"dump", nil]];
		[panel setExtensionHidden:NO];
		[panel setCanSelectHiddenExtension:YES];
        [panel setMessage:@"Dump files are huge!  Exercise patience while saving."];
		[panel beginSheetForDirectory:nil
								 file:[NSString stringWithFormat:[NSString stringWithFormat:@"%@.dump", [_process name]]]
					   modalForWindow:ibWindow
						modalDelegate:self
					   didEndSelector:@selector(saveMemoryDumpDidEnd:returnCode:contextInfo:)
						  contextInfo:memoryDump];
		[memoryDump retain];
	}
}

- (void)saveMemoryDumpDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSData *dump = (NSData *)contextInfo;
	
	[ibStatusText setDefaultStatus:[self defaultStatusString]];
	
	if ( returnCode == NSOKButton ) {
		// write the file
		[dump writeToFile:[sheet filename] atomically:YES];
		
		[ibStatusText setTemporaryStatus:[NSString stringWithFormat:@"Successfully dumped %@'s memory.", [_process name]]];
	}
	else {
		[ibStatusText setTemporaryStatus:@"Dumping memory cancelled."];
	}
	
	[dump release];
	
	[ibStatusBar stopAnimation:self];
	[ibStatusBar setIndeterminate:NO];
	
	[self updateInterface];
	if ( _mode == TCSearchMode ) {
		[ibWindow makeFirstResponder:ibSearchValueField];
	}
}

- (void)cheaterDidCancelMemoryDump:(Cheater *)cheater
{
	ChazLog( @"cheaterDidCancelMemoryDump:" );
	
	if ( _isCancelingTask ) {
		_status = TCIdleStatus;
		_isCancelingTask = NO;
		
		[ibStatusText setDefaultStatus:[self defaultStatusString]];
		[ibStatusText setTemporaryStatus:@"Dumping memory cancelled."];
		[ibStatusBar stopAnimation:self];
		[ibStatusBar setIndeterminate:NO];
		
		[self updateInterface];
		if ( _mode == TCSearchMode ) {
			[ibWindow makeFirstResponder:ibSearchValueField];
		}
	}
}


- (void)cheater:(Cheater *)cheater didChangeVariables:(unsigned)changeCount
{
	ChazLog( @"CHEATER changed %u variables.", changeCount );
	if ( ![_cheatData repeats] ) {
		_status = TCIdleStatus;
	}
	
	if ( changeCount == 0 ) {
		[ibStatusText setTemporaryStatus:@"No variables were changed." duration:2.0];
	}
	else if ( changeCount == 1 ) {
		[ibStatusText setTemporaryStatus:@"Changed one variable." duration:2.0];
	}
	else {
		[ibStatusText setTemporaryStatus:[NSString stringWithFormat:@"Changed %i variables.", changeCount] duration:2.0];
	}
	
	[self updateInterface];
}

- (void)cheaterDidStopChangingVariables:(Cheater *)cheater
{
	_status = TCIdleStatus;
	_isCancelingTask = NO;
	
	[ibStatusText setDefaultStatus:[self defaultStatusString]];
	[ibStatusBar stopAnimation:self];
	[ibStatusBar setIndeterminate:NO];
	
	[self updateInterface];
	if ( _mode == TCSearchMode ) {
		[ibWindow makeFirstResponder:ibSearchValueField];
	}
}


- (void)cheater:(Cheater *)cheater didReportProgress:(int)progress
{
	if ( _status == TCSearchingStatus && !_isCancelingTask ) {
		[ibStatusBar setDoubleValue:(double)progress];
	}
}


- (void)cheater:(Cheater *)cheater didRevertToVariables:(TCArray)variables actualAmount:(unsigned)count
{
	// do something with the variables
	[_searchData setAddresses:variables];
	[ibSearchVariableTable reloadData];
	
	[self setActualResults:count];
	
	[self updateInterface];
}


- (void)cheaterDidUndo:(Cheater *)cheater
{
	[_searchData didUndo];
	
	[ibStatusText setTemporaryStatus:@"Reverted to previous results." duration:2.0];
}

- (void)cheaterDidRedo:(Cheater *)cheater
{
	[_searchData didRedo];
	
	[ibStatusText setTemporaryStatus:@"Reverted to saved results." duration:2.0];
}


- (void)cheater:(Cheater *)cheater variableAtIndex:(unsigned)index didChangeTo:(Variable *)variable
{
	[_searchData setValue:variable atIndex:index];
	[ibSearchVariableTable reloadData];
}


- (void)cheater:(Cheater *)cheater didFailLastRequest:(NSString *)reason
{
	_status = TCIdleStatus;
	
	// echo the reason to the status
	[self showError:reason];
	[ibStatusBar setIndeterminate:NO];
	[ibStatusBar setDoubleValue:0.0];
	[ibStatusBar stopAnimation:self];
	
	[self updateInterface];
}

- (void)cheater:(Cheater *)cheater echo:(NSString *)message
{
	// echo the message to the status
	[ibStatusText setTemporaryStatus:message duration:7.0];
}


@end
