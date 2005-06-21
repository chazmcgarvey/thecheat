
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
