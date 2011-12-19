
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import "ServerPrefs.h"

#include "cheat_global.h"

#import "AppController.h"

#import "CheatServer.h"
#import "ServerChild.h"


@interface ServerPrefs ( PrivateAPI )

- (void)_serverStarted:(NSNotification *)note;
- (void)_serverStopped:(NSNotification *)note;
- (void)_childrenChanged:(NSNotification *)note;

@end


@implementation ServerPrefs


- (id)init
{
	if ( self = [super init] ) {
		NSNotificationCenter *nc= [NSNotificationCenter defaultCenter];
		
		// register for server notifications
		[nc addObserver:self selector:@selector(_serverStarted:) name:TCServerStartedNote object:nil];
		[nc addObserver:self selector:@selector(_serverStopped:) name:TCServerStoppedNote object:nil];
		[nc addObserver:self selector:@selector(_childrenChanged:) name:TCServerConnectionsChangedNote object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)awakeFromNib
{
	[ibDefaultPortText setStringValue:[NSString stringWithFormat:@"Default cheat port is %i.", TCDefaultListenPort]];
	
	// set initial states
	[ibNameField setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:TCBroadcastNamePref]];
	[ibPortField setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:TCListenPortPref]];
	
	if ( [[NSApp cheatServer] isListening] ) {
		[self _serverStarted:nil];
	}
	else {
		[self _serverStopped:nil];
	}
}



- (IBAction)ibSetListenPort:(id)sender
{
	short unsigned port = [ibPortField intValue];
	
	if ( port < 1024 ) {
		port = TCDefaultListenPort;
		[sender setIntValue:port];
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:[ibPortField intValue] forKey:TCListenPortPref];
}

- (IBAction)ibSetBroadcast:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[ibNameField stringValue] forKey:TCBroadcastNamePref];
}

- (IBAction)ibStartServer:(id)sender
{
	CheatServer *server = [NSApp cheatServer];
	
	[self ibSetListenPort:nil];
	[self ibSetBroadcast:nil];
	
	if ( [server isListening] ) {
		// stop it
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:TCRunServerPref];
		[NSApp stopCheatServer];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:TCRunServerPref];
		if ( ![NSApp startCheatServer] ) {
			// cheat server failed to start
			NSBeginAlertSheet( @"The Cheat could not start the server.", @"OK", nil, nil, [sender window], nil, NULL, NULL, NULL,
							 @"The cheat server failed to start.  Make sure the port is not in use by another program and try again." );
		}
	}
}


- (int)numberOfRowsInTableView:(NSTableView *)table
{
	CheatServer *server = [NSApp cheatServer];
	if ( [server isListening] ) {
		return [server childCount];
	}
	return 0;
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	NSString *identifier = [column identifier];
	ServerChild *child;
	
	child = [[[NSApp cheatServer] children] objectAtIndex:row];
	
	return [child valueForKey:identifier];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)column row:(int)row
{
	
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn
{
	return NO;
}

- (void)tableView:(NSTableView *)aTableView deleteRows:(NSArray *)rows
{
	int i, len;
	
	len = [rows count];
	for ( i = len-1; i >= 0; i-- ) {
		[[NSApp cheatServer] removeChildAtIndex:[[rows objectAtIndex:i] unsignedIntValue]];
	}
	// reselect the last item if the selection is now invalid
	len = [[NSApp cheatServer] childCount] - 1;
	if ( [aTableView selectedRow] > len ) {
		[aTableView selectRow:len byExtendingSelection:NO];
	}
	[aTableView reloadData];
}


- (void)_serverStarted:(NSNotification *)note
{
	CheatServer *server = [NSApp cheatServer];
	int port;
	// server is running
	port = [server port];
	if ( port != TCDefaultListenPort ) {
		[ibStatusField setDefaultStatus:[NSString stringWithFormat:@"cheat://%@:%i", [server host], port]];
	}
	else {
		[ibStatusField setDefaultStatus:[NSString stringWithFormat:@"cheat://%@", [server host]]];
	}
	[ibNameField setEnabled:NO];
	[ibPortField setEnabled:NO];
	[ibStartButton setTitle:@"Stop Server"];
	[ibSessionTable reloadData];
	
	_tableTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_childrenChanged:)
												  userInfo:nil repeats:YES] retain];
}

- (void)_serverStopped:(NSNotification *)note
{
	// server is not running
	[ibStatusField setDefaultStatus:@"Not Running"];
	[ibNameField setEnabled:YES];
	[ibPortField setEnabled:YES];
	[ibStartButton setTitle:@"Start Server"];
	[ibSessionTable reloadData];
	
	[_tableTimer invalidate];
	[_tableTimer release];
	_tableTimer = nil;
}

- (void)_childrenChanged:(NSNotification *)note
{
	[ibSessionTable reloadData];
}


@end
