
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


@interface BetterTableView : NSTableView
{
	BOOL _canDelete; // YES if deleting is enabled
	BOOL _canCopyPaste;
}

// override super
- (void)keyDown:(NSEvent *)theEvent;

// new stuff
- (BOOL)canDelete;
- (void)setCanDelete:(BOOL)flag;

- (BOOL)canCopyPaste;
- (void)setCanCopyPaste:(BOOL)flag;

// array of NSNumbers with the rows which are selected
- (NSArray *)selectedRows;

@end

@interface NSObject(BetterTableViewDelegate)

- (NSString *)tableViewPasteboardType:(NSTableView *)tableView;
- (NSData *)tableView:(NSTableView *)tableView copyRows:(NSArray *)rows;
- (void)tableView:(NSTableView *)tableView pasteRowsWithData:(NSData *)rowData;

- (void)tableView:(NSTableView *)tableView deleteRows:(NSArray *)rows;

- (BOOL)tableViewDidReceiveEnterKey:(NSTableView *)tableView;
- (BOOL)tableViewDidReceiveSpaceKey:(NSTableView *)tableView;

@end
