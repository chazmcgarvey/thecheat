//
//  DumpContext.m
//  The Cheat
//
//  Created by Chaz McGarvey on 12/6/04.
//  Copyright 2004 Chaz McGarvey. All rights reserved.
//

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
