//
//  CheatURLCommand.m
//  The Cheat
//
//  Created by Chaz McGarvey on 2/19/05.
//  Copyright 2005 Chaz McGarvey. All rights reserved.
//

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
