
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
