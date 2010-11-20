
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "CheatURLCommand.h"


@implementation CheatURLCommand

- (id)performDefaultImplementation
{
	NSDocumentController	*controller = [NSDocumentController sharedDocumentController];
	CheatDocument			*doc = [controller makeUntitledDocumentOfType:@"Cheat Document"];
	if ( !doc ) {
		ChazLog( @"nil document" );
	}
	[doc setMode:TCSearchMode];
	[doc setConnectOnOpen:NO];
	[controller addDocument:doc];
	[doc makeWindowControllers];
	[doc showWindows];
	[doc connectWithURL:[self directParameter]];
	return nil;
}

@end
