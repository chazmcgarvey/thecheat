
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      MenuExtras.m
// Created:   Wed Sep 17 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "MenuExtras.h"


@implementation NSMenu (MenuExtras)

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