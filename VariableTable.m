
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
