
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
#import <Foundation/foundation.h>
#import <SecurityFoundation/SFAuthorization.h>
#import <Security/AuthorizationTags.h>
#include "ChazLog.h"
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>


/*
 * I think this function was ripped from the iHaxGamez project, so it
 * remains licensed under the GPL.
 */
void authMe(char * FullPathToMe)
{
	// get authorization as root

	OSStatus myStatus;
	
	// set up Authorization Item
	AuthorizationItem myItems[1];
	myItems[0].name = kAuthorizationRightExecute;
	myItems[0].valueLength = 0;
	myItems[0].value = NULL;
	myItems[0].flags = 0;
	
	// Set up Authorization Rights
	AuthorizationRights myRights;
	myRights.count = sizeof (myItems) / sizeof (myItems[0]);
	myRights.items = myItems;
	
	// set up Authorization Flags
	AuthorizationFlags myFlags;
	myFlags =
		kAuthorizationFlagDefaults |
		kAuthorizationFlagInteractionAllowed |
		kAuthorizationFlagExtendRights;
	
	// Create an Authorization Ref using Objects above. NOTE: Login bod comes up with this call.
	AuthorizationRef myAuthorizationRef;
	myStatus = AuthorizationCreate (&myRights, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
	
	if (myStatus == errAuthorizationSuccess)
	{
		// prepare communication path - used to signal that process is loaded
		FILE *myCommunicationsPipe = NULL;
		char myReadBuffer[] = " ";

		// run this app in GOD mode by passing authorization ref and comm pipe (asynchoronous call to external application)
		myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef,FullPathToMe,kAuthorizationFlagDefaults,nil,&myCommunicationsPipe);

		// external app is running asynchronously - it will send to stdout when loaded
		if (myStatus == errAuthorizationSuccess)
		{
			read (fileno (myCommunicationsPipe), myReadBuffer, sizeof (myReadBuffer));
			fclose(myCommunicationsPipe);
		}
		
		// release authorization reference
		myStatus = AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDestroyRights);
	}
}

/*
 * I think this function was ripped from the iHaxGamez project, so it
 * remains licensed under the GPL.
 */
bool checkExecutablePermissions(void)
{
	NSDictionary	*applicationAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[[NSBundle mainBundle] executablePath] traverseLink: YES];
	
	// We expect 2755 as octal (1517 as decimal, -rwxr-sr-x as extended notation)
	return ([applicationAttributes filePosixPermissions] == 1517 && [[applicationAttributes fileGroupOwnerAccountName] isEqualToString: @"procmod"]);
}

/*
 * I think this function was ripped from the iHaxGamez project, so it
 * remains licensed under the GPL.
 */
bool amIWorthy(void)
{
	// running as root?
	AuthorizationRef myAuthRef;
	OSStatus stat = AuthorizationCopyPrivilegedReference(&myAuthRef,kAuthorizationFlagDefaults);
	
	return stat == errAuthorizationSuccess || checkExecutablePermissions();
}

int main( int argc, char *argv[] )
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	ChazLogDisable();
	
	ChazDebugSetup();
	ChazMapLogToDebug();
	
#ifdef __ppc__
	// PPC machines whose operating system is below leopard do not need authorization
	SInt32 osxMajorVersion;
	Gestalt(gestaltSystemVersionMinor, &osxMajorVersion);
	if (osxMajorVersion < 5)
	{
		[pool release];
		return NSApplicationMain(argc,  (const char **) argv);
	}
#endif
	
	if (amIWorthy())
	{
#ifndef _DEBUG
		printf("Don't forget to flush! ;-) "); // signal back to close caller
#endif
		fflush(stdout);
		
		[pool release];
		return NSApplicationMain(argc,  (const char **) argv);
	}
	else
	{
		authMe(argv[0]);
		[pool release];
		return 0;
	}
	
	ChazDebugCleanup();
}
