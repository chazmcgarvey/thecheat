
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      NetTrafficController.h
// Created:   Wed Sep 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>

#import "NetTrafficControlling.h"

#include "cheat_globals.h"


@interface NetTrafficController : NSWindowController
{
	id				delegate;
	
	IBOutlet id		netTrafficWindow;
	IBOutlet id		broadcastNameText;
	IBOutlet id		listenPortText;
	IBOutlet id		serverListTable;
	IBOutlet id		connectionCountText;
	IBOutlet id		killConnectionButton;
}

- (id)initWithDelegate:(id)del;

- (void)initialInterfaceSetup;
- (void)interfaceUpdate;

- (void)allowRemoteChanged:(BOOL)allow;
- (void)listenPortChanged:(int)port;
- (void)broadcastNameChanged:(NSString *)name;

- (void)connectionListChanged;

- (void)setConnectionCount:(int)count;

- (IBAction)killConnectionButton:(id)sender;

@end