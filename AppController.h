
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      AppController.h
// Created:   Wed Aug 13 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>

#import "PreferenceControlling.h"
#import "NetTrafficControlling.h"
#import "ListenerDelegate.h"
#import "ServerDelegate.h"

#include "cheat_globals.h"


@class AboutBoxController;
@class PreferenceController;
@class NetTrafficController;


@interface AppController : NSObject < PreferenceControlling, NetTrafficControlling, ListenerDelegate, ServerDelegate >
{
	BOOL					waitingToListen;
	NSConnection			*connection;
	int						connectionPort;
	BOOL					connectionRemote;
	int						sockfd;
	NSNetService			*service, *oldService;

	NSMutableArray			*servers;

	AboutBoxController		*aboutBoxController;
	PreferenceController	*preferenceController;
	NetTrafficController	*netTrafficController;
}

- (void)listenOnPort:(int)port remote:(BOOL)remote;
- (void)stopListener;

- (void)broadcastWithName:(NSString *)name;
- (void)stopBroadcast;

- (IBAction)showAboutBoxWindow:(id)sender;
- (IBAction)showPreferenceWindow:(id)sender;
- (IBAction)showNetTrafficWindow:(id)sender;

- (IBAction)launchHelpFile:(id)sender;
- (IBAction)launchWebsiteMenu:(id)sender;
- (IBAction)launchDebugEmailMenu:(id)sender;

@end