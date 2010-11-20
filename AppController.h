
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import <Cocoa/Cocoa.h>
#import "ChazLog.h"
#include "cheat_global.h"

#import "ChazUpdate.h"

#import "CheatServer.h"


@class AboutBoxController;
@class HelpController;
@class PreferenceController;


@interface AppController : NSApplication
{
	CheatServer *_server;

	AboutBoxController *_aboutBoxController;
	HelpController *_helpController;
	PreferenceController *_preferenceController;
}

// Interface Actions
- (IBAction)newSearchWindow:(id)sender;
- (IBAction)newBlankCheatWindow:(id)sender;

- (IBAction)showAboutBoxWindow:(id)sender;
- (IBAction)showPreferenceWindow:(id)sender;

- (IBAction)launchHelpFile:(id)sender;
- (IBAction)launchEmailMenu:(id)sender;
- (IBAction)launchWebsiteMenu:(id)sender;

- (IBAction)checkForUpdate:(id)sender;

// Server Stuff
- (CheatServer *)cheatServer;
- (BOOL)startCheatServer;
- (void)stopCheatServer;

@end


