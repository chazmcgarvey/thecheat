//
//  DumpContext.h
//  The Cheat
//
//  Created by Chaz McGarvey on 12/6/04.
//  Copyright 2004 Chaz McGarvey. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VMRegion.h"


@interface DumpContext : NSObject
{
	// for fast access while iterating through the task loop.
	@public;
	
	pid_t process;
	unsigned regionCount;
	VMRegion lastRegion;
	
	NSMutableData *dump;
}

// Initialization

- (id)initWithPID:(pid_t)pid;


@end
