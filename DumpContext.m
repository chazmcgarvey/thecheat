
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "DumpContext.h"


@implementation DumpContext


- (id)initWithPID:(pid_t)pid
{
	if ( self = [super init] ) {
		process = pid;
		regionCount = VMCountRegionsWithAttributes( pid, VMREGION_READABLE );
		dump = [[NSMutableData alloc] init];
	}
	return self;
}

- (void)dealloc
{
	//[lastRegion release];
	[dump release];
	[super dealloc];
}


@end
