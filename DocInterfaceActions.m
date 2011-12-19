
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


@interface CheatDocument (DocumentActionsPrivateAPI )

- (void)_confirmTargetChange:(NSWindow *)sheet returnCode:(int)returnCode context:(void *)contextInfo;

@end


@implementation CheatDocument ( DocumentActions )


- (IBAction)ibSetLocalCheater:(id)sender
{
	ChazLog( @"Selected %@", sender );
	
	// if this is the current server, don't reconnect
	if ( ![self shouldConnectWithServer:sender] ) {
		return;
	}
	
	// disconnect and prepare to reconnect
	[self disconnectFromCheater];
	[self connectWithServer:sender];
	
	// create new local cheater
	_cheater = [[LocalCheater alloc] initWithDelegate:self];
	[(LocalCheater *)_cheater setShouldCopy:YES];
	
	// send initial messages
	[_cheater connect];
	[_cheater getProcessList];
	
	// send preferences to the cheater
	[_cheater limitReturnedResults:[[NSUserDefaults standardUserDefaults] integerForKey:TCHitsDisplayedPref]];
	
	[ibStatusText setDefaultStatus:[self defaultStatusString]];
}

- (IBAction)ibSetRemoteCheater:(id)sender
{
	ChazLog( @"Selected %@", sender );
	
	if ( ![self shouldConnectWithServer:sender] ) {
		return;
	}
	
	ChazLog( @"resolving rendezvous service..." );
	
	_resolvingService = [[sender representedObject] retain];
	[_resolvingService setDelegate:self];
	[_resolvingService resolve];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	NSArray *addresses;
	
	ChazLog( @"service resolved!" );
	
	// stop resolving
	[sender stop];
	
	if ( sender != _resolvingService ) {
		return;
	}
	
	[self disconnectFromCheater];
	[self connectWithServer:(NSMenuItem *)[ibServerPopup itemAtIndex:[ibServerPopup indexOfItemWithRepresentedObject:_resolvingService]]];
	
	addresses = [_resolvingService addresses];
	
	_resolvingService = nil;
	
	// create new remote cheater
	ChazLog( @"found %i addresses", [addresses count] );
	_cheater = [[RemoteCheater alloc] initWithDelegate:self];
	[(RemoteCheater *)_cheater connectToHostWithData:[addresses objectAtIndex:0]];
	
	// send initial messages
	[_cheater connect];
	[_cheater getProcessList];
	
	// send preferences to the cheater
	[_cheater limitReturnedResults:[[NSUserDefaults standardUserDefaults] integerForKey:TCHitsDisplayedPref]];
	
	[ibStatusText setDefaultStatus:[self defaultStatusString]];
	[self updateInterface];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	[sender stop];
	
	if ( sender != _resolvingService ) {
		return;
	}
	
	_resolvingService = nil;
	
	NSBeginInformationalAlertSheet( @"The Cheat can't find the server.", @"OK", nil, nil, ibWindow, self, NULL, NULL, NULL,
									@"The Cheat can't connect to the server \"%@\" because it can't be found.", [sender name] );
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	[sender release];
}

- (IBAction)ibSetCustomCheater:(id)sender
{
	RemoteCheater *cheater;
	ChazLog( @"Selected %@", [sender description] );
	
	if ( ![self shouldConnectWithServer:sender] ) {
		return;
	}
	
	cheater = [[RemoteCheater alloc] initWithDelegate:self];
	if ( ![(RemoteCheater *)cheater connectToHostWithData:[sender representedObject]] ) {
		NSBeginInformationalAlertSheet( @"The Cheat can't find the server.", @"OK", nil, nil, ibWindow, self, NULL, NULL, NULL,
										@"The Cheat can't connect to \"%@\" because there is no server at that address.", [sender title] );
		[cheater release];
		[self selectConnectedCheater];
		return;
	}
	
	[self disconnectFromCheater];
	[self connectWithServer:sender];
	
	_cheater = cheater;
	
	// send initial messages
	[_cheater connect];
	[_cheater getProcessList];
	
	// send preferences to the cheater
	[_cheater limitReturnedResults:[[NSUserDefaults standardUserDefaults] integerForKey:TCHitsDisplayedPref]];
	
	[ibStatusText setDefaultStatus:[self defaultStatusString]];
	[self updateInterface];
}

- (IBAction)ibSetNoCheater:(id)sender
{
	[self disconnectFromCheater];
	
	// nil server object
	[_serverObject release];
	_serverObject = nil;
	
	[ibStatusText setDefaultStatus:[self defaultStatusString]];
	[self updateInterface];
}

- (IBAction)ibSetProcess:(id)sender
{
	if ( [_process isEqual:(Process *)[sender representedObject]] ) {
		// this process is already selected, do nothing
		return;
	}
	
	[_cheatData process];
	if ( [_searchData hasSearchedOnce] ) {
		NSBeginInformationalAlertSheet( @"Confirm target change.", @"OK", @"Cancel", nil, ibWindow, self, NULL,
										@selector(_confirmTargetChange:returnCode:context:), [[sender representedObject] retain],
										@"If you change the target now, your search will be cleared.  This cannot be undone.  Continue?" );
	}
	else {
		// request the change
		[_cheater setTarget:(Process *)[sender representedObject]];
	}
}

- (void)_confirmTargetChange:(NSWindow *)sheet returnCode:(int)returnCode context:(void *)contextInfo
{
	NSMenu *processMenu = [ibProcessPopup menu];
	Process *process = (Process *)contextInfo;
	
	if ( returnCode == NSAlertDefaultReturn ) {
		// clear the search
		[self ibClearSearch:nil];
		// request the change
		[_cheater setTarget:process];
	}
	else {
		// select the correct server menuitem
		[ibProcessPopup selectItemAtIndex:[processMenu indexOfItemWithRepresentedObject:_process]];
	}
	
	[process release];
}


- (IBAction)ibSetVariableType:(id)sender
{
	[_searchData setVariableType:[sender tag]];
	[self updateInterface];
}

- (IBAction)ibSetIntegerSign:(id)sender
{
	[_searchData setIntegerSign:[[sender selectedCell] tag]];
}

- (IBAction)ibSetOperator:(id)sender
{
	[_searchData setSearchOperator:[sender tag]];
}

- (IBAction)ibSetValueUsed:(id)sender
{
	[_searchData setValueUsed:[[sender selectedCell] tag]];
	[self updateInterface];
}

- (IBAction)ibClearSearch:(id)sender
{
	[_cheater clearSearch];
}

- (IBAction)ibSearch:(id)sender
{
	Variable *variable;

	// do the search
	if ( [_searchData valueUsed] == TCGivenValue ) {
		variable = [[Variable alloc] initWithType:[_searchData variableType] integerSign:[_searchData integerSign]];
		[variable setProcess:_process];
		[variable setStringValue:[ibSearchValueField stringValue]];
		if ( [variable isValueValid] && [variable valueSize] > 0 ) {
			_status = TCSearchingStatus;
			[ibStatusText setDefaultStatus:[NSString stringWithFormat:@"Searching %@'s memory%C", [_process name], 0x2026]];
			[ibStatusBar setIndeterminate:NO];
			
			[_searchData setSearchValue:variable];
			[_cheater searchForVariable:variable comparison:[_searchData searchOperator]];
			//[_cheater searchForVariable:[_searchData searchValue] comparison:[_searchData searchOperator]];
			[variable release];
		}
		else {
			NSBeginAlertSheet( @"Invalid Input", @"OK", nil, nil, ibWindow, nil, NULL, NULL, NULL,
							   @"The search value \"%@\" cannot be used with this type of search.", [ibSearchValueField stringValue] );
		}
	}
	else {
		_status = TCSearchingStatus;
		[ibStatusText setDefaultStatus:[NSString stringWithFormat:@"Searching %@'s memory%C", [_process name], 0x2026]];
		[ibStatusBar setIndeterminate:NO];
		
		[_cheater searchLastValuesComparison:[_searchData searchOperator]];
	}
	
	[self updateInterface];
}

- (IBAction)ibAddSearchVariable:(id)sender
{
	NSArray *rows;
	int i, top;
	
	// don't do anything if there is nothing selected
	if ( [ibSearchVariableTable selectedRow] == -1 ) {
		return;
	}
	
	rows = [ibSearchVariableTable selectedRows];
	top = [rows count];
	for ( i = 0; i < top; i++ ) {
		int rowIndex = [[rows objectAtIndex:i] unsignedIntValue];
		// transfer the search variable to the cheat data
		[_cheatData addVariable:[_searchData variableAtIndex:rowIndex]];
	}
	
	// update the variable table
	[ibCheatVariableTable reloadData];

	if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCSwitchVariablesPref] ) {
		[self switchToCheatMode];
		
		int rowIndex = [_cheatData variableCount]-1;
		if ( MacOSXVersion() >= 0x1030 ) {
			[ibCheatVariableTable selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
		}
		else {
			[ibCheatVariableTable selectRow:rowIndex byExtendingSelection:NO];
		}
		// start editing the last added variable
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCAutoStartEditingVarsPref] ) {
			if ( top > 1 ) {
				// edit multiple
				if ( MacOSXVersion() >= 0x1030 ) {
					[ibCheatVariableTable selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(rowIndex-top+1,top-1)]
									  byExtendingSelection:YES];
				}
				else {
					for ( i = 1; i < top; i++ ) {
						[ibCheatVariableTable selectRow:rowIndex-i byExtendingSelection:YES];
					}
				}
				[ibCheatVariableTable scrollRowToVisible:rowIndex];
				[self ibRunEditVariablesSheet:nil];
			}
			else {
				// edit one
				[ibCheatVariableTable editColumn:[ibCheatVariableTable columnWithIdentifier:@"value"]
											 row:rowIndex withEvent:nil select:YES];
			}
		}
	}
	
	// update interface
	[self setDocumentChanged];
	[self updateInterface];
}


- (IBAction)ibSetCheatRepeats:(id)sender
{
	[_cheatData setRepeats:[sender state]];
	
	// update interface
	[self setDocumentChanged];
	[self updateInterface];
}

- (IBAction)ibSetRepeatInterval:(id)sender
{
	[_cheatData setRepeatInterval:[sender doubleValue]];
	
	// update interface
	[self setDocumentChanged];
	[self updateInterface];
}

- (IBAction)ibCheat:(id)sender
{
	_status = TCCheatingStatus;
	[_cheater makeVariableChanges:[_cheatData enabledVariables] repeat:[_cheatData repeats] interval:[_cheatData repeatInterval]];
	
	// update status description
	if ( [_cheatData repeats] ) {
		[ibStatusText setDefaultStatus:[NSString stringWithFormat:@"Applying cheats to %@%C", [_process name], 0x2026]];
		[ibStatusBar setIndeterminate:YES];
		[ibStatusBar startAnimation:self];
		
		[self updateInterface];
	}
}


- (IBAction)ibRunPropertiesSheet:(id)sender
{
	// update fields
	[ibWindowTitleField setStringValue:[_cheatData windowTitle]];
	[ibCheatInfoField setStringValue:[_cheatData cheatInfo]];
	
	// display sheet
	[NSApp beginSheet:ibPropertiesSheet modalForWindow:ibWindow modalDelegate:nil didEndSelector:NULL contextInfo:nil];	
}

- (IBAction)ibEndPropertiesSheet:(id)sender
{
	[ibPropertiesSheet orderOut:sender];
	[NSApp endSheet:ibPropertiesSheet returnCode:0];
	
	if ( [sender tag] == 1 ) {
		// do not update anything if nothing has changed
		if ( [[ibWindowTitleField stringValue] isEqualToString:[_cheatData windowTitle]] &&
			 [[ibCheatInfoField stringValue] isEqualToString:[_cheatData cheatInfo]] ) {
			return;
		}
		// update data
		[_cheatData setWindowTitle:[ibWindowTitleField stringValue]];
		[_cheatData setCheatInfo:[ibCheatInfoField stringValue]];
		
		[self setDocumentChanged];
		[self updateInterface];
	}
}


- (IBAction)ibRunPasswordSheet:(id)sender
{
	
}

- (IBAction)ibEndPasswordSheet:(id)sender
{
	
}


- (IBAction)ibRunCustomServerSheet:(id)sender
{
	// update fields
	[ibServerField setStringValue:@""];
	[ibPortField setStringValue:[NSString stringWithFormat:@"%i", TCDefaultListenPort]];
	
	// display sheet
	[NSApp beginSheet:ibCustomServerSheet modalForWindow:ibWindow modalDelegate:nil didEndSelector:NULL contextInfo:nil];
}

- (IBAction)ibEndCustomServerSheet:(id)sender
{
	NSString *server = [ibServerField stringValue];
	int port = [[ibPortField stringValue] intValue];
	
	ChazLog( @"ibEndCustomServerSheet: %@:%i", server, port );
	
	[ibCustomServerSheet orderOut:sender];
	[NSApp endSheet:ibCustomServerSheet returnCode:0];
	
	if ( [sender tag] == 1 ) {
		[self connectWithURL:[NSString stringWithFormat:@"cheat://%@:%i", server, port]];
	}
}


- (IBAction)ibRunEditVariablesSheet:(id)sender
{
	int row = [ibCheatVariableTable selectedRow];
	Variable *var;
	
	// must have selected items
	if ( row == -1 ) {
		return;
	}
	
	var = [_cheatData variableAtIndex:row];
	
	// update field
	[ibNewValueField setStringValue:[var stringValue]];
	
	// display sheet
	[NSApp beginSheet:ibEditVariablesSheet modalForWindow:ibWindow modalDelegate:nil didEndSelector:NULL contextInfo:nil];
}

- (IBAction)ibEndEditVariablesSheet:(id)sender
{
	NSString *newValue = [ibNewValueField stringValue];
	NSArray *rows;
	int i, top;
	
	[ibEditVariablesSheet orderOut:sender];
	[NSApp endSheet:ibEditVariablesSheet returnCode:0];
	
	if ( [sender tag] == 0 ) {
		return;
	}
	if ( [newValue isEqualToString:@""] ) {
		newValue = nil;
	}
	
	rows = [ibCheatVariableTable selectedRows];
	top = [rows count];
	
	// change all selected variables with the new value
	if ( newValue ) {
		for ( i = 0; i < top; i++ ) {
			Variable *var = [_cheatData variableAtIndex:[[rows objectAtIndex:i] unsignedIntValue]];
			[var setStringValue:newValue];
		}
	}
	
	[ibCheatVariableTable reloadData];
	
	[self setDocumentChanged];
	[self updateInterface];
}


- (IBAction)ibPauseTarget:(id)sender
{
	[_cheater pauseTarget];
}

- (IBAction)ibResumeTarget:(id)sender
{
	[_cheater resumeTarget];
}


- (IBAction)ibCancelSearch:(id)sender
{
	_isCancelingTask = YES;
	[_cheater cancelSearch];
	
	[self updateInterface];
}

- (IBAction)ibStopCheat:(id)sender
{
	_isCancelingTask = YES;
	[_cheater stopChangingVariables];
	
	[self updateInterface];
}


- (IBAction)ibDumpMemory:(id)sender
{
	_status = TCDumpingStatus;
	[_cheater getMemoryDump];
	
	// display status
	[ibStatusText setDefaultStatus:[NSString stringWithFormat:@"Dumping %@'s memory%C", [_process name], 0x2026]];
	[ibStatusBar setIndeterminate:YES];
	[ibStatusBar startAnimation:self];
	
	[self updateInterface];
}

- (IBAction)ibCancelDump:(id)sender
{
	_isCancelingTask = YES;
	[_cheater cancelMemoryDump];
	
	[self updateInterface];
}


- (IBAction)ibAddCheatVariable:(id)sender
{
	ChazLog( @"ibAddCheatVariable:" );
	Variable *var = [[Variable alloc] initWithType:[sender tag]];
	// add the new variable to the doc data
	[_cheatData addVariable:var];
	[var release];
	// update the variable table
	[ibCheatVariableTable reloadData];
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCSwitchVariablesPref] ) {
		[self switchToCheatMode];
		
		int row = [_cheatData variableCount]-1;
		if ( MacOSXVersion() >= 0x1030 ) {
			[ibCheatVariableTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		}
		else {
			[ibCheatVariableTable selectRow:row byExtendingSelection:NO];
		}
		// start editing new variable
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCAutoStartEditingVarsPref] ) {
			[ibCheatVariableTable editColumn:[ibCheatVariableTable columnWithIdentifier:@"address"] row:row withEvent:nil select:YES];
		}
	}
	
	// update interface
	[self setDocumentChanged];
	[self updateInterface];
}

- (IBAction)ibSetVariableEnabled:(id)sender
{
	NSArray *rows;
	int i, top;
	
	BOOL flag;
	
	ChazLog( @"ibSetVariableEnabled: %i", [sender selectedRow] );
	
	flag = [[_cheatData variableAtIndex:[ibCheatVariableTable selectedRow]] isEnabled];
	
	rows = [ibCheatVariableTable selectedRows];
	top = [rows count];
	
	for ( i = 0; i < top; i++ ) {
		Variable *var = [_cheatData variableAtIndex:[[rows objectAtIndex:i] unsignedIntValue]];
		[var setEnabled:!flag];
	}
	
	// update interface
	[ibCheatVariableTable reloadData];
	[self setDocumentChanged];
	[self updateInterface];
}


- (IBAction)ibToggleSearchCheat:(id)sender
{
	if ( _mode == TCCheatMode ) {
		[self switchToSearchMode];
	}
	else if ( _mode == TCSearchMode ) {
		[self switchToCheatMode];
	}
}


- (IBAction)ibUndo:(id)sender
{
	[_cheater undo];
}

- (IBAction)ibRedo:(id)sender
{
	[_cheater redo];
}


@end
