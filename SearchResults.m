
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      SearchResults.m
// Created:   Sat Oct 04 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "SearchResults.h"


@implementation SearchResults


+ (id)resultsWithType:(TCtype)type size:(TCsize)size data:(TCaddress const *)data amount:(int)amount
{
	return [[[SearchResults alloc] initWithType:type size:size data:data amount:amount] autorelease];
}

- (id)initWithType:(TCtype)type size:(TCsize)size data:(TCaddress const *)data amount:(int)amount
{
	if ( self = [self init] )
	{
		myType = type;
		mySize = size;
		myData = (TCaddress *)data;
		myAmount = amount;
	}

	return self;
}


- (TCtype)type
{
	return myType;
}

- (TCsize)size
{
	return mySize;
}

- (TCaddress *)data
{
	return myData;
}

- (int)amount
{
	return myAmount;
}


- (void)dealloc
{
	if ( myData )
	{
		free( myData );
	}
	
	[super dealloc];
}


@end