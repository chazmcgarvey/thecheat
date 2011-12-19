
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "TrackerScroller.h"


@implementation TrackerScroller


- (id)delegate
{
	return _delegate;
}

- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}


- (void)mouseDown:(NSEvent *)theEvent
{
	if ( [_delegate respondsToSelector:@selector(scrollerDidStartScrolling:)] ) {
		[_delegate scrollerDidStartScrolling:self];
	}
	[super mouseDown:theEvent];
	if ( [_delegate respondsToSelector:@selector(scrollerDidStopScrolling:)] ) {
		[_delegate scrollerDidStopScrolling:self];
	}
}


@end
