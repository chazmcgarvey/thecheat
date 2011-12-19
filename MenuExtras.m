
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

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
