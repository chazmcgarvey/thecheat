//
//  VariableTable.h
//  The Cheat
//
//  Created by Chaz McGarvey on 12/28/04.
//  Copyright 2004 Chaz McGarvey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "ChazLog.h"

#import "BetterTableView.h"

#import "TrackerScroller.h"

/*
 * This class lets you get which rows are currently visible and has a delegate
 * method which is called when the visible rows changes.
 */


@interface VariableTable : BetterTableView
{
	BOOL _dontUpdate;
	BOOL _updatePending;
	NSRange _visibleRows;
}

- (NSRange)visibleRows;

@end


@interface NSObject ( VariableTableViewDelegate )

- (void)tableView:(NSTableView *)aTableView didChangeVisibleRows:(NSRange)rows;

@end