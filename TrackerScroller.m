//
//  TrackerScroller.m
//  The Cheat
//
//  Created by Chaz McGarvey on 12/28/04.
//  Copyright 2004 Chaz McGarvey. All rights reserved.
//

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
