
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


