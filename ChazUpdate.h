
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


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


