
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

#import "BetterTableView.h"


@interface BetterTableView ( PrivateAPI )

- (NSString *)_copyString;

- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)delete:(id)sender;

@end


@implementation BetterTableView


- (id)init
{
	if ( self = [super init] ) {
		_canCopyPaste = YES;
		_canDelete = YES;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ( self = [super initWithCoder:coder] ) {
		_canCopyPaste = YES;
		_canDelete = YES;
	}
	return self;
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL selector = [menuItem action];
	
	if ( selector == @selector(selectAll:) ) {
		return YES;
	}
	// support copy/paste
	if ( _canCopyPaste ) {
		if ( selector == @selector(paste:) ) {
			id delegate = [self delegate];
			NSPasteboard *pb = [NSPasteboard generalPasteboard];
			NSString *type = nil;
			// allow the delegate specify the type of data
			if ( [delegate respondsToSelector:@selector(tableViewPasteboardType:)] ) {
				type = [delegate tableViewPasteboardType:self];
			}
			if ( type && [pb availableTypeFromArray:[NSArray arrayWithObject:type]] ) {
				return YES;
			}
		}
		if ( [self selectedRow] != -1 ) {
			if ( selector == @selector(copy:) ) {
				return YES;
			}
			else if ( selector == @selector(cut:) || selector == @selector(delete:) ) {
				return _canDelete;
			}
		}
	}
	return NO;
}

- (IBAction)copy:(id)sender
{
	if ( _canCopyPaste && [self selectedRow] != -1 ) {
		id delegate = [self delegate];
		NSPasteboard *pb = [NSPasteboard generalPasteboard];
		NSString *type = nil;
		// allow the delegate specify the type of data
		if ( [delegate respondsToSelector:@selector(tableViewPasteboardType:)] ) {
			type = [delegate tableViewPasteboardType:self];
		}
		if ( type ) {
			[pb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, type, nil] owner:self];
			// allow the delegate to copy data
			if ( [delegate respondsToSelector:@selector(tableView:copyRows:)] ) {
				[pb setData:[delegate tableView:self copyRows:[self selectedRows]] forType:type];
			}
		}
		else {
			[pb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:self];
		}
		[pb setString:[self _copyString] forType:NSStringPboardType];
	}
}

- (IBAction)paste:(id)sender
{
	if (  _canCopyPaste ) {
		id delegate = [self delegate];
		NSPasteboard *pb = [NSPasteboard generalPasteboard];
		NSString *type = nil;
		// allow the delegate specify the type of data
		if ( [delegate respondsToSelector:@selector(tableViewPasteboardType:)] ) {
			type = [delegate tableViewPasteboardType:self];
		}
		if ( type && [pb availableTypeFromArray:[NSArray arrayWithObject:type]] ) {
			// allow the delegate to paste data
			if ( [delegate respondsToSelector:@selector(tableView:pasteRowsWithData:)] ) {
				[delegate tableView:self pasteRowsWithData:[pb dataForType:type]];
			}
		}
	}
}

- (IBAction)cut:(id)sender
{
	[self copy:sender];
	[self delete:sender];
}

- (IBAction)delete:(id)sender
{
	if ( _canDelete && [self selectedRow] != -1 ) {
		id delegate = [self delegate];
		if ( [delegate respondsToSelector:@selector(tableView:deleteRows:)] ) {
			[delegate tableView:self deleteRows:[self selectedRows]];
		}
	}
}


- (void)keyDown:(NSEvent *)theEvent
{	
	unsigned short keyCode = [theEvent keyCode];
	// if something is selected and deleting is enabled and the delete key was pressed
	if ( _canDelete && [self selectedRow] != -1 && (keyCode == 0x75 || keyCode == 0x33) ) {
		// a delete key was pressed
		[self delete:nil];
		return;
	}
	else if ( keyCode == 0x24 || keyCode == 0x4C ) {
		id delegate = [self delegate];
		if ( [delegate respondsToSelector:@selector(tableViewDidReceiveEnterKey:)] ) {
			if ( [delegate tableViewDidReceiveEnterKey:self] ) {
				return;
			}
		}
	}
	else if ( keyCode == 0x31 ) {
		// space key
		id delegate = [self delegate];
		if ( [delegate respondsToSelector:@selector(tableViewDidReceiveSpaceKey:)] ) {
			if ( [delegate tableViewDidReceiveSpaceKey:self] ) {
				return;
			}
		}
	}
	[super keyDown:theEvent];
}


// NEW STUFF HERE

- (BOOL)canDelete
{
	return _canDelete;
}

- (void)setCanDelete:(BOOL)flag
{
	_canDelete = flag;
}


- (BOOL)canCopyPaste
{
	return _canCopyPaste;
}

- (void)setCanCopyPaste:(BOOL)flag
{
	_canCopyPaste = flag;
}


- (NSArray *)selectedRows
{
	return [[self selectedRowEnumerator] allObjects];
}


// PRIVATE METHODS

- (NSString *)_copyString
{
	NSArray *rows, *columns;
	int i, j, top, columnCount;
	NSMutableString *string;
	id delegate = [self delegate];
	
	// check delegate
	if ( ![delegate respondsToSelector:@selector(tableView:objectValueForTableColumn:row:)] ) {
		return @"";
	}
	
	string = [[NSMutableString alloc] init];
	
	columns = [self tableColumns];
	columnCount = [self numberOfColumns];
	
	// loop thru all selected cells and put the text into the string
	rows = [self selectedRows];
	top = [rows count];
	for ( i = 0; i < top; i++ ) {
		int row = [[rows objectAtIndex:i] unsignedIntValue];
		for ( j = 0; j < columnCount; j++ ) {
			id object = [delegate tableView:self objectValueForTableColumn:[columns objectAtIndex:j] row:row];
			[string appendFormat:@"%@%@", j > 0? @"\t" : @"", object];
		}
		if ( i + 1 != top ) {
			[string appendString:@"\n"];
		}
	}
	return [string autorelease];
}


@end
