
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      SearchResults.h
// Created:   Sat Oct 04 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>

#include "cheat_types.h"


@interface SearchResults : NSObject
{
	TCtype			myType;
	TCsize			mySize;
	
	TCaddress		*myData;
	int				myAmount;
}

+ (id)resultsWithType:(TCtype)type size:(TCsize)size data:(TCaddress const *)data amount:(int)amount;
- (id)initWithType:(TCtype)type size:(TCsize)size data:(TCaddress const *)data amount:(int)amount;

- (TCtype)type;
- (TCsize)size;
- (TCaddress *)data;
- (int)amount;

@end