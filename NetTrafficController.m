
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      NetTrafficController.m
// Created:   Wed Sep 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "NetTrafficController.h"

#import "CheatServer.h"

#import "ServerHolder.h"


@implementation NetTrafficController


- (id)initWithDelegate:(id)del
{
	if ( self = [super initWithWindowNibName:@"NetTraffic"] )
	{
		[self setWindowFrameAutosaveName:@"TCNetTrafficWindowPosition"];
		
		delegate = del;
	}

	return self;
}

- (void)windowDidLoad
{
	[self initialInterfaceSetup];
	[self interfaceUpdate];
}


- (void)initialInterfaceSetup
{
	//[netTrafficWindow setResizeIncrements:NSMakeSize( 1.0, 17.0 )];
	
	[self allowRemoteChanged:TCGlobalAllowRemote];
	[self listenPortChanged:TCGlobalListenPort];
	[self setConnectionCount:[delegate netTrafficConnectionCount]];
	[serverListTable reloadData];
}

- (void)interfaceUpdate
{
	NSArray				*array = [[serverListTable selectedRowEnumerator] allObjects];
	
	if ( [array count] == 0 )
	{
		[killConnectionButton setEnabled:NO];
	}
	else
	{
		[killConnectionButton setEnabled:YES];
		
		if ( [array count] > 1 )
		{
			[killConnectionButton setTitle:@"Kill Connections"];
		}
		else
		{
			[killConnectionButton setTitle:@"Kill Connection"];
		}
	}
}


- (void)allowRemoteChanged:(BOOL)allow
{
	if ( allow )
	{
		[self broadcastNameChanged:TCGlobalBroadcastName];
		[self listenPortChanged:TCGlobalListenPort];
	}
	else
	{
		[broadcastNameText setStringValue:@"Not accepting new connections from remote clients."];
		[listenPortText setStringValue:@"Listening for local connections only."];
	}
}

- (void)listenPortChanged:(int)port
{
	if ( TCGlobalAllowRemote )
	{
		[listenPortText setStringValue:[NSString stringWithFormat:@"Listening on port %i.", port]];
	}
}

- (void)broadcastNameChanged:(NSString *)name
{
	if ( TCGlobalAllowRemote )
	{
		[broadcastNameText setStringValue:[NSString stringWithFormat:@"Broadcasting service as \"%@.\"", name]];
	}
}


- (void)connectionListChanged
{
	[self setConnectionCount:[delegate netTrafficConnectionCount]];
	[serverListTable reloadData];
}


- (void)setConnectionCount:(int)count
{
	[connectionCountText setStringValue:[NSString stringWithFormat:@"Now serving %i clients.", count]];
}


- (IBAction)killConnectionButton:(id)sender
{
	NSArray				*array = [[serverListTable selectedRowEnumerator] allObjects];
	int					i;
	
	for ( i = [array count] - 1; i >= 0; i-- )
	{
		[delegate netTrafficKillConnection:[(NSNumber *)[array objectAtIndex:i] intValue]];
	}
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   NSTableView Data Source/Delegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (int)numberOfRowsInTableView:(NSTableView *)table
{
	return [delegate netTrafficConnectionCount];
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	ServerHolder		*holder = [[delegate netTrafficConnectionList] objectAtIndex:row];
	
	if ( [[column identifier] isEqualToString:@"IP Address"] )
	{
		return [holder address];
	}
	else if ( [[column identifier] isEqualToString:@"Current Action"] )
	{
		return [holder action];
	}

	return @"Unknown";
}

- (void)tableView:(NSTableView *) setObjectValue:(id)object forTableColumn:(NSTableColumn *)column row:(int)row
{
	return;
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
	[self interfaceUpdate];
}


@end