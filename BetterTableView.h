
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
