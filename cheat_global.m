
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

#import "cheat_global.h"

#import <Carbon/Carbon.h>


// globals
float gFadeAnimationDuration = TCDefaultFadeAnimation;


// user default constants
NSString *TCFirstLaunchPref = nil;
NSString *TCWindowsOnTopPref = @"TCWindowsOnTopPref";
NSString *TCUpdateCheckPref = @"TCUpdateCheckPref";
NSString *TCDisplayValuesPref = @"TCDisplayValuesPref";
NSString *TCValueUpdatePref = @"TCValueUpdatePref";
NSString *TCHitsDisplayedPref = @"TCHitsDisplayedPref";
NSString *TCRunServerPref = @"TCRunServerPref";
NSString *TCBroadcastNamePref = @"TCBroadcastNamePref";
NSString *TCListenPortPref = @"TCListenPortPref";
NSString *TCFadeAnimationPref = @"TCFadeAnimationPref";
NSString *TCAskForSavePref = @"TCAskForSavePref";
NSString *TCSwitchVariablesPref = @"TCSwitchVariablesPref";
NSString *TCAutoStartEditingVarsPref = @"TCAutoStartEditingVarsPref";


// notification constants
NSString *TCServiceFoundNote = @"TCServiceFoundNote";
NSString *TCServiceRemovedNote = @"TCServiceRemovedNote";
NSString *TCServerStartedNote = @"TCServerStartedNote";
NSString *TCServerStoppedNote = @"TCServerStoppedNote";
NSString *TCServerConnectionsChangedNote = @"TCServerConnectionsChangedNote";
NSString *TCWindowsOnTopChangedNote = @"TCWindowsOnTopChangedNote";
NSString *TCDisplayValuesChangedNote = @"TCDisplayValuesChangedNote";
NSString *TCHitsDisplayedChangedNote = @"TCHitsDisplayedChangedNote";


void LaunchWebsite()
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.brokenzipper.com/"]];
}

void LaunchEmail()
{
	//[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:chaz@brokenzipper.com?subject=The%20Cheat%20Feedback"]];
	/* Ed Palma will act as a contact person for The Cheat. */
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.brokenzipper.com/contact.html"]];
}


int MacOSXVersion()
{
	SInt32 static		version = -1;
	
	if ( version != -1 ) {
		return (int)version;
	}
	
	// get the version
	if ( Gestalt( gestaltSystemVersion, &version ) != noErr ) {
		return -1;
	}
	return (int)version;
}

NSString *ApplicationVersion( NSString *appPath )
{
	NSString *tVersion = nil;
	NSBundle *tBundle = [NSBundle bundleWithPath:appPath];	
	
	if ( tBundle ) {
		NSDictionary		*tInfoDictionary;
		
		tInfoDictionary = [tBundle infoDictionary];
		
		if ( tInfoDictionary ) {
			tVersion = [tInfoDictionary objectForKey:@"CFBundleShortVersionString"];
			if ( !tVersion ) {
				tVersion = [tInfoDictionary objectForKey:@"CFBundleVersion"];
			}
		}
	}
	else {
		CFBundleRef		tBundleRef;
		short			resNum = 0;
		
		tBundleRef = CFBundleCreate( NULL, (CFURLRef)[NSURL fileURLWithPath:appPath] );
		
		if ( tBundleRef ) {
			resNum = CFBundleOpenBundleResourceMap( tBundleRef );
		}
		
		if ( resNum != 0 ) {
			VersRecHndl		tVersionHandle;
			unsigned long   tNumVersion;
			
			tVersionHandle = (VersRecHndl)Get1IndResource( 'vers', 1 );
			
			if ( tVersionHandle ) {
				tNumVersion = *((unsigned long *) &((*tVersionHandle)->numericVersion));
				
				if ( (tNumVersion & 0x00040000) != 0 ) {
					tVersion = [NSString stringWithFormat:@"%d.%d.%d", (tNumVersion & 0xFF000000)>>24, (tNumVersion & 0x00F00000)>>20, (tNumVersion & 0x000F0000)>>16];
				}
				else {
					tVersion = [NSString stringWithFormat:@"%d.%d", (tNumVersion & 0xFF000000)>>24, (tNumVersion & 0x00F00000)>>20];
				}
			}
			
		}
		if ( tBundleRef ) {
			CFBundleCloseBundleResourceMap( tBundleRef, resNum );
			// Release Memory
			CFRelease( tBundleRef );
		}
	}
	return tVersion;	
}
