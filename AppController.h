
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

// Privilage elevation stuff
AuthorizationRef _authRef;
AuthorizationItem _authItem;
AuthorizationRights _authRights;
- (int) preAuthorize;
- (int) launchAuthPrgm;

// Server Stuff
- (CheatServer *)cheatServer;
- (BOOL)startCheatServer;
- (void)stopCheatServer;

@end


