
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

#import "AppController.h"

#import "CheatDocument.h"
#import "AboutBoxController.h"
#import "HelpController.h"
#import "PreferenceController.h"

// Privilage elevation libs
#include <security/authorization.h>
#include <security/authorizationdb.h>
#include <security/authorizationtags.h>
#include <sys/types.h>
#include <unistd.h>

@implementation AppController


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Initialization
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


+ (void)initialize
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	
	TCFirstLaunchPref = [[NSString stringWithFormat:@"TC%@%@Pref", ChazAppName(), ChazAppVersion()] retain];
	NSString *broadcastName = [NSString stringWithFormat:@"%@'s Computer", NSFullUserName()];
	
	// register user defaults
	[defaults setObject:[NSNumber numberWithBool:NO] forKey:TCFirstLaunchPref];
	[defaults setObject:[NSNumber numberWithBool:NO] forKey:TCWindowsOnTopPref];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:TCUpdateCheckPref];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:TCDisplayValuesPref];
	[defaults setObject:[NSNumber numberWithFloat:1.0] forKey:TCValueUpdatePref];
	[defaults setObject:[NSNumber numberWithInt:1000] forKey:TCHitsDisplayedPref];
	[defaults setObject:[NSNumber numberWithBool:NO] forKey:TCRunServerPref];
	[defaults setObject:broadcastName forKey:TCBroadcastNamePref];
	[defaults setObject:[NSNumber numberWithInt:TCDefaultListenPort] forKey:TCListenPortPref];
	[defaults setObject:[NSNumber numberWithFloat:gFadeAnimationDuration] forKey:TCFadeAnimationPref];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:TCAskForSavePref];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:TCSwitchVariablesPref];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:TCAutoStartEditingVarsPref];

	// register it
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
	// set globals
	gFadeAnimationDuration = [[NSUserDefaults standardUserDefaults] floatForKey:TCFadeAnimationPref];
}

- (id)init
{
	if ( self = [super init] )
	{
		if( geteuid() != 0 )
		{		
			[self launchAuthPrgm];
			[self setDelegate:self];
		}
	}

	if( geteuid() != 0 )
	{
		NSRunAlertPanel(@"The Cheat must be run as root,", 
						@"Due to a limitation of Leopard, the application needs elevated privileges to run.",
						@"Exit", nil, nil );
		[self terminate: 0];
	}
	
	return self;
}

- (int) preAuthorize
{
	int err;
	AuthorizationFlags authFlags;
	
	
	NSLog (@"MyWindowController: preAuthorize");
	
	if (_authRef)
		return errAuthorizationSuccess;
	
	NSLog (@"MyWindowController: preAuthorize: ** calling AuthorizationCreate...**\n");
	
	authFlags = kAuthorizationFlagDefaults;
	err = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment, authFlags, &_authRef);
	if (err != errAuthorizationSuccess)
		return err;
	
	NSLog (@"MyWindowController: preAuthorize: ** calling AuthorizationCopyRights...**\n");
	
	_authItem.name = kAuthorizationRightExecute;
	_authItem.valueLength = 0;
	_authItem.value = NULL;
	_authItem.flags = 0;
	_authRights.count = 1;
	_authRights.items = (AuthorizationItem*) malloc (sizeof (_authItem));
	memcpy (&_authRights.items[0], &_authItem, sizeof (_authItem));
	authFlags = kAuthorizationFlagDefaults
	| kAuthorizationFlagExtendRights
	| kAuthorizationFlagInteractionAllowed
	| kAuthorizationFlagPreAuthorize;
	err = AuthorizationCopyRights (_authRef, &_authRights, kAuthorizationEmptyEnvironment, authFlags, NULL);
	
	return err;
}

- (int) launchAuthPrgm
{
	AuthorizationFlags authFlags;
	int err;
	
	// path
	NSString * path = [[NSBundle mainBundle] executablePath];
	if (![[NSFileManager defaultManager] isExecutableFileAtPath: path])
		return -1;
	
	// auth
	
	if (!_authRef)
	{
		err = [self preAuthorize];
		if (err != errAuthorizationSuccess)
			return err;
	}
	
	// launch
	
	NSLog (@"MyWindowController: launchWithPath: ** calling AuthorizationExecuteWithPrivileges...**\n");
	authFlags = kAuthorizationFlagDefaults;
	err = AuthorizationExecuteWithPrivileges (_authRef, [path cString], authFlags, NULL, NULL);
	if(err==0) [NSApp terminate:self];
	
	return err;
}

- (void)dealloc
{
	ChazLog( @"AppController deallocated!!" );
	[self stopCheatServer];
	[super dealloc];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark NSApplication Delegate
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// check if this is the first launch
	if ( ![[NSUserDefaults standardUserDefaults] boolForKey:TCFirstLaunchPref] ) {
		// FIRST LAUNCH
		[self showAboutBoxWindow:self];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:TCFirstLaunchPref];
	}
	
	// if should check for updates on launch
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCUpdateCheckPref] ) {
		ChazCheckForUpdate( TCUpdateCheckURL, NO );
	}
	
	// automaticall start the cheat server if the pref is set
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:TCRunServerPref] ) {
		if ( ![self startCheatServer] ) {
			// inform the user that the server won't start
			NSRunAlertPanel( @"The Cheat could not start the server.",
							 @"The cheat server failed to start.  Check the server settings and start it manually.",
							 @"OK", nil, nil );
			// open server prefs
			[self showPreferenceWindow:self];
			[_preferenceController chooseServer:self];
		}
	}
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Interface Actions
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (IBAction)newSearchWindow:(id)sender
{
	NSDocumentController	*controller = [NSDocumentController sharedDocumentController];
	CheatDocument			*doc = [controller makeUntitledDocumentOfType:@"Cheat Document"];
	if ( !doc ) {
		ChazLog( @"nil document" );
	}
	[doc setMode:TCSearchMode];
	[controller addDocument:doc];
	[doc makeWindowControllers];
	[doc showWindows];
}

- (IBAction)newBlankCheatWindow:(id)sender
{
	NSDocumentController	*controller = [NSDocumentController sharedDocumentController];
	CheatDocument			*doc = [controller makeUntitledDocumentOfType:@"Cheat Document"];
	if ( !doc ) {
		ChazLog( @"nil document" );
	}
	[doc setMode:TCCheatMode];
	[controller addDocument:doc];
	[doc makeWindowControllers];
	[doc showWindows];
}

- (IBAction)showAboutBoxWindow:(id)sender
{
	if ( !_aboutBoxController ) {
		_aboutBoxController = [[AboutBoxController alloc] init];
	}
	[_aboutBoxController showWindow:self];
}

- (IBAction)showPreferenceWindow:(id)sender
{
	if ( !_preferenceController ) {
		_preferenceController = [[PreferenceController alloc] init];
	}
	[_preferenceController showWindow:self];
}


- (IBAction)launchHelpFile:(id)sender
{
	if ( !_helpController ) {
		_helpController = [[HelpController alloc] init];
	}
	[_helpController showWindow:self];
}

- (IBAction)launchEmailMenu:(id)sender
{
	LaunchEmail();
}

- (IBAction)launchWebsiteMenu:(id)sender
{
	LaunchWebsite();
}


- (IBAction)checkForUpdate:(id)sender
{
	ChazCheckForUpdate( TCUpdateCheckURL, YES );
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark CheatServer Stuff
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (CheatServer *)cheatServer
{
	if ( !_server ) {
		_server = [[CheatServer alloc] initWithDelegate:self];
	}
	return _server;
}

- (BOOL)startCheatServer
{
	ChazLog( @"cheat server starting..." );
	
	// start the server with saved settings
	int port = [[NSUserDefaults standardUserDefaults] integerForKey:TCListenPortPref];
	NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:TCBroadcastNamePref];
	if ( [name isEqualToString:@""] ) {
		name = nil;
	}
	
	// stop the cheat server if it's running
	[self stopCheatServer];
	
	// start the server
	if ( [[self cheatServer] listenOnPort:port broadcast:name] ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:TCServerStartedNote object:[self cheatServer]];
		return YES;
	}
	return NO;
}

- (void)stopCheatServer
{
	if ( _server ) {
		[_server stop];
		[[NSNotificationCenter defaultCenter] postNotificationName:TCServerStoppedNote object:[self cheatServer]];
	}
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark CheatServerDelegate
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (void)serverDisconnectedUnexpectedly:(CheatServer *)theServer
{
	ChazLog( @"server disconnected unexpectedly." );
	[self stopCheatServer];
}

- (void)server:(CheatServer *)theServer failedToBroadcastName:(NSString *)theName
{
	NSBeginInformationalAlertSheet( @"The cheat server can not broadcast.",  @"OK", nil, nil, [_preferenceController window], nil, NULL, NULL, NULL,
									@"The Cheat can't broadcast as \"%@\" because that name is in use by another server.  The server will continue running with broadcasting disabled.", theName );
}

- (void)serverChildrenChanged:(CheatServer *)theServer
{
	[[NSNotificationCenter defaultCenter] postNotificationName:TCServerConnectionsChangedNote object:theServer];
}


@end
