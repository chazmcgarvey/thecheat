
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      AppController.h
// Created:   Wed Aug 13 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>
#import <Chaz/Chaz.h>

#import "PreferenceControlling.h"
#import "NetTrafficControlling.h"
#import "ListenerDelegate.h"
#import "ServerDelegate.h"

#include "cheat_globals.h"


@class AboutBoxController;
@class PreferenceController;
@class NetTrafficController;


@interface AppController : NSApplication < PreferenceControlling, NetTrafficControlling, ListenerDelegate, ServerDelegate >
{
	BOOL					waitingToListen;
	NSConnection			*connection;
	int						connectionPort;
	BOOL					connectionRemote;
	int						sockfd;
	NSNetService			*service;

	NSMutableArray			*servers;

	AboutBoxController		*aboutBoxController;
	PreferenceController	*preferenceController;
	NetTrafficController	*netTrafficController;
	
	// global network browser
	NSNetServiceBrowser		*browser;
	NSMutableArray			*serverList;
}

- (void)listenOnPort:(int)port remote:(BOOL)remote;
- (void)stopListener;

- (void)broadcastWithName:(NSString *)name;
- (void)stopBroadcast;

- (IBAction)newSessionWindow:(id)sender;

- (IBAction)showAboutBoxWindow:(id)sender;
- (IBAction)showPreferenceWindow:(id)sender;
- (IBAction)showNetTrafficWindow:(id)sender;

- (IBAction)launchHelpFile:(id)sender;
- (IBAction)launchEmailMenu:(id)sender;
- (IBAction)launchWebsiteMenu:(id)sender;

- (IBAction)checkForUpdate:(id)sender;

- (NSArray *)serverList;

@end