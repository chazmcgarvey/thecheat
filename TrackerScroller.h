//
//  TrackerScroller.h
//  The Cheat
//
//  Created by Chaz McGarvey on 12/28/04.
//  Copyright 2004 Chaz McGarvey. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TrackerScroller : NSScroller
{
	id _delegate;
}

- (id)delegate;
- (void)setDelegate:(id)delegate;

@end


@interface NSObject ( TrackerScrollerDelegate )

- (void)scrollerDidStartScrolling:(TrackerScroller *)scroller;
- (void)scrollerDidStopScrolling:(TrackerScroller *)scroller;

@end