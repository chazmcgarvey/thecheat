
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


// This is my update system.  It is extremely simple to use.  Just pass the URL
// where the version information can be obtained.  The version information will
// be loaded in the background and a dialog will show up presenting the user
// with the results of the check.  If userRequested is NO, then the system will
// not do anything if an error occured or if there is no available update.
// Depending on the tags given in the version file, the presented dialog can
// have buttons which link to a "more info" page or a direct download, using the
// default web browser of the system.


// url can either be an NSURL or an NSString containing a valid URL.
void ChazCheckForUpdate( id url, BOOL userRequested ); // uses default app name.
void ChazCheckForUpdateWithName( id url, NSString *appName, BOOL userRequested );

// these return empty strings if they can't be determined.
NSString *ChazAppName(); // returns the name ChazCheckForUpdate() uses.
NSString *ChazAppVersion(); // returns the current version of the app.
NSDate *ChazAppBuildDate(); // returns the build date used to check for updates.


