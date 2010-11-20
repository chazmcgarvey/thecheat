
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#ifndef _cheat_shared_H
#define _cheat_shared_H


// constants
#define TCDefaultListenPort ( 51835 )
#define TCUpdateCheckURL ( @"http://www.dogcows.com/pub/mac/software.plist" )

#define TCDefaultFadeAnimation (0.15)


// globals
float extern gFadeAnimationDuration;


// user default constants
NSString extern *TCFirstLaunchPref;
NSString extern *TCWindowsOnTopPref;
NSString extern *TCUpdateCheckPref;
NSString extern *TCDisplayValuesPref;
NSString extern *TCValueUpdatePref;
NSString extern *TCHitsDisplayedPref;
NSString extern *TCRunServerPref;
NSString extern *TCBroadcastNamePref;
NSString extern *TCListenPortPref;
NSString extern *TCFadeAnimationPref;
NSString extern *TCAskForSavePref;
NSString extern *TCSwitchVariablesPref;
NSString extern *TCAutoStartEditingVarsPref;

// notification constants
NSString extern *TCServiceFoundNote;
NSString extern *TCServiceRemovedNote;
NSString extern *TCServerStartedNote;
NSString extern *TCServerStoppedNote;
NSString extern *TCServerConnectionsChangedNote;
NSString extern *TCWindowsOnTopChangedNote;
NSString extern *TCDisplayValuesChangedNote;
NSString extern *TCHitsDisplayedChangedNote;


void LaunchWebsite();
void LaunchEmail();

int MacOSXVersion();
NSString *ApplicationVersion( NSString *appPath );


#endif
