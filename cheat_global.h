
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

#ifndef _cheat_shared_H
#define _cheat_shared_H


// constants
#define TCDefaultListenPort ( 51835 )
#define TCUpdateCheckURL ( @"http://www.brokenzipper.com/software.plist" )

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