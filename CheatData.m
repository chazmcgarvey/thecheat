
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import "CheatData.h"


@implementation CheatData


// #############################################################################
#pragma mark Initialization
// #############################################################################

- (id)init
{
	if ( self = [super init] )
	{
		// set defaults
		[self setWindowTitle:@""];
		[self setCheatInfo:@""];
		[self setProcess:[[[Process alloc] initWithName:@"No Target Set" version:@""] autorelease]];
		
		myRepeats = NO;
		myRepeatInterval = 5.0;
		
		// create objects
		myVariables = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	// release objects
	[myWindowTitle release];
	[myCheatInfo release];
	[myProcess release];
	[myVariables release];
	
	[super dealloc];
}


// #############################################################################
#pragma mark NSCoding
// #############################################################################

- (id)initWithCoder:(NSCoder *)coder
{
	if ( self = [super init] )
	{
		[self setWindowTitle:[coder decodeObject]];
		[self setCheatInfo:[coder decodeObject]];
		[self setProcess:[coder decodeObject]];
		myVariables = [[coder decodeObject] retain];	
		[coder decodeValueOfObjCType:@encode(BOOL) at:&myRepeats];
		[coder decodeValueOfObjCType:@encode(NSTimeInterval) at:&myRepeatInterval];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:myWindowTitle];
	[coder encodeObject:myCheatInfo];
	[coder encodeObject:myProcess];
	[coder encodeObject:myVariables];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&myRepeats];
	[coder encodeValueOfObjCType:@encode(NSTimeInterval) at:&myRepeatInterval];
}


// #############################################################################
#pragma mark Accessing Properties
// #############################################################################


- (NSString *)windowTitle
{
	return myWindowTitle;
}

- (NSString *)cheatInfo
{
	return myCheatInfo;
}

- (NSString *)gameName
{
	return [myProcess name];
}

- (NSString *)gameVersion
{
	return [myProcess version];
}

- (Process *)process
{
	return myProcess;
}

- (BOOL)repeats
{
	return myRepeats;
}

- (NSTimeInterval)repeatInterval
{
	return myRepeatInterval;
}


- (void)setWindowTitle:(NSString *)title
{
	if ( !title ) {
		title = [NSString stringWithString:@""];
	}
	[title retain];
	[myWindowTitle release];
	myWindowTitle = title;
}

- (void)setCheatInfo:(NSString *)info
{
	if ( !info ) {
		info = [NSString stringWithString:@"Description not provided."];
	}
	[info retain];
	[myCheatInfo release];
	myCheatInfo = info;
}

- (void)setProcess:(Process *)process
{
	[process retain];
	[myProcess release];
	myProcess = process;
}

- (void)setRepeats:(BOOL)repeats
{
	myRepeats = repeats;
}

- (void)setRepeatInterval:(NSTimeInterval)interval
{
	myRepeatInterval = interval;
}


// #############################################################################
#pragma mark Variables
// #############################################################################

- (NSArray *)variables
{
	return [NSArray arrayWithArray:myVariables];
}

- (unsigned)variableCount
{
	return [myVariables count];
}

- (unsigned)indexOfVariable:(Variable *)variable
{
	return [myVariables indexOfObject:variable];
}

- (Variable *)variableAtIndex:(unsigned)index
{
	return [myVariables objectAtIndex:index];
}

- (Variable *)lastVariable
{
	return [myVariables lastObject];
}


- (void)addVariable:(Variable *)variable
{
	[myVariables addObject:variable];
}

- (void)insertVariable:(Variable *)variable atIndex:(unsigned)index
{
	[myVariables insertObject:variable atIndex:index];
}


- (void)removeAllVariables
{
	[myVariables removeAllObjects];
}

- (void)removeVariable:(Variable *)variable
{
	[myVariables removeObject:variable];
}

- (void)removeVariableAtIndex:(unsigned)index
{
	[myVariables removeObjectAtIndex:index];
}


- (NSArray *)enabledVariables
{
	NSMutableArray *vars;
	int i, top;
	
	top = [myVariables count];
	vars = [[NSMutableArray alloc] init];
	
	for ( i = 0; i < top; i++ ) {
		Variable *var = [myVariables objectAtIndex:i];
		if ( [var isEnabled] ) {
			[vars addObject:var];
		}
	}
	return [vars autorelease];
}

- (unsigned)enabledVariableCount
{
	return [[self enabledVariables] count];
}


@end
