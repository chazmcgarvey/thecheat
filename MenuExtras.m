
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

#import "MenuExtras.h"


@implementation NSMenu ( MenuExtras )


- (void)removeItemWithTitle:(NSString *)title
{
	int			i, top = [self numberOfItems];

	for ( i = 0; i < top; i++ )
	{
		if ( [[[self itemAtIndex:i] title] isEqualToString:title] )
		{
			[self removeItemAtIndex:i];
			break;
		}
	}
}

- (void)removeAllItemsWithTitle:(NSString *)title
{
	int			i, top = [self numberOfItems] - 1;

	for ( i = top; i >= 0; i-- )
	{
		if ( [[[self itemAtIndex:i] title] isEqualToString:title] )
		{
			[self removeItemAtIndex:i];
		}
	}
}

- (void)removeItemWithTag:(int)tag
{
	int			i, top = [self numberOfItems];

	for ( i = 0; i < top; i++ )
	{
		if ( [[self itemAtIndex:i] tag] == tag )
		{
			[self removeItemAtIndex:i];
			break;
		}
	}
}

- (void)removeItemWithRepresentedObject:(id)object
{
	int			i, top = [self numberOfItems];
	
	for ( i = 0; i < top; i++ )
	{
		if ( [[[self itemAtIndex:i] representedObject] isEqual:object] )
		{
			[self removeItemAtIndex:i];
			break;
		}
	}
}


- (void)removeAllItems
{
	int			i, top = [self numberOfItems];

	for ( i = 0; i < top; i++ )
	{
		[self removeItemAtIndex:0];
	}
}


- (void)enableAllItems
{
	int			i, top = [self numberOfItems];

	for ( i = 0; i < top; i++ )
	{
		[[self itemAtIndex:i] setEnabled:YES];
	}
}

- (void)disableAllItems
{
	int			i, top = [self numberOfItems];

	for ( i = 0; i < top; i++ )
	{
		[[self itemAtIndex:i] setEnabled:NO];
	}
}


@end