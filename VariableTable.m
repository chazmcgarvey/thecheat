
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "VariableTable.h"


@interface VariableTable ( PrivateAPI )

- (void)_setVisibleRows:(NSRange)rows;

@end


@implementation VariableTable


- (void)awakeFromNib
{
	NSScrollView *scrollView = (NSScrollView *)[(NSClipView *)[self superview] superview];
	NSScroller *oldScroller = [[scrollView verticalScroller] retain];
	
	TrackerScroller *scroller = [[TrackerScroller alloc] initWithFrame:[oldScroller frame]];
	
	[scroller setControlSize:[oldScroller controlSize]];	
	[scroller setFloatValue:[oldScroller floatValue] knobProportion:[oldScroller knobProportion]];
	[scroller setControlTint:[oldScroller controlTint]];
	
	// set the new scroller
	[scrollView setHasVerticalScroller:NO];
	[scrollView setVerticalScroller:scroller];
	[scrollView setHasVerticalScroller:YES];
	
	[scroller setDelegate:self];
	[scroller release];
	[oldScroller release];
	
	/*if ( [super respondsToSelector:@selector(awakeFromNib)] ) {
		[super awakeFromNib];
	}*/
}


- (NSRange)visibleRows
{
	return _visibleRows;
}

- (void)_setVisibleRows:(NSRange)rows
{
	_visibleRows = rows;
}


- (void)reloadData
{   
	if ( _dontUpdate ) {
		_updatePending = YES;
		return;
	}
	
	[super reloadData];
	
	NSRange range = [self rowsInRect:[(NSClipView *)[self superview] documentVisibleRect]];
	id delegate = [self delegate];
	
	if ( !NSEqualRanges( range, _visibleRows ) ) {
		[self _setVisibleRows:range];
		if ( [delegate respondsToSelector:@selector(tableView:didChangeVisibleRows:)] ) {
			[delegate tableView:self didChangeVisibleRows:range];
		}
	}
}


- (void)keyDown:(NSEvent *)theEvent
{
	_dontUpdate = YES;
	[super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
	NSRange range = [self rowsInRect:[(NSClipView *)[self superview] documentVisibleRect]];
	id delegate = [self delegate];
	
	[super keyUp:theEvent];
	
	_dontUpdate = NO;
	
	if ( !NSEqualRanges( range, _visibleRows ) ) {
		[self _setVisibleRows:range];
		if ( [delegate respondsToSelector:@selector(tableView:didChangeVisibleRows:)] ) {
			[delegate tableView:self didChangeVisibleRows:range];
		}
	}
	else if ( _updatePending ) {
		[self reloadData];
		_updatePending = NO;
	}
}

- (void)scrollerDidStartScrolling:(TrackerScroller *)scroller
{
	_dontUpdate = YES;
}

- (void)scrollerDidStopScrolling:(TrackerScroller *)scroller
{
	NSRange range = [self rowsInRect:[(NSClipView *)[self superview] documentVisibleRect]];
	id delegate = [self delegate];
	
	_dontUpdate = NO;
	
	if ( !NSEqualRanges( range, _visibleRows ) ) {
		[self _setVisibleRows:range];
		if ( [delegate respondsToSelector:@selector(tableView:didChangeVisibleRows:)] ) {
			[delegate tableView:self didChangeVisibleRows:range];
		}
	}
	else if ( _updatePending ) {
		[self reloadData];
		_updatePending = NO;
	}
}


@end
