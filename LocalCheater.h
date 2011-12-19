
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

#import "Cheater.h"

#import "VMRegion.h"
#import "ThreadedTask.h"

#import "SearchContext.h"
#import "DumpContext.h"


@interface LocalCheater : Cheater
{
	NSMutableArray *_processes;
	Process *_target;
	
	BOOL _isTargetPaused;
	
	ThreadedTask *_searchTask;
	ThreadedTask *_dumpTask;
	
	NSMutableArray *_searchResults;
	NSMutableArray *_savedResults;
	unsigned _returnLimit;
	
	NSTimer *_cheatTimer;
	NSArray *_cheatVariables;
	
	NSTimer *_watchTimer;
	NSArray *_watchVariables;
	NSRange _watchRange;
	
	BOOL _shouldCopy;
}


// copying vs references
// ultimately, the client will need a separate copy
// of whatever is passed back to it, but we can use
// references instead of the delegate will make its
// own copies (or not use anything directly).
- (BOOL)shouldCopy;
- (void)setShouldCopy:(BOOL)flag;


@end


