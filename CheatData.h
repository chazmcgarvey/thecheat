
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import <Cocoa/Cocoa.h>

#import "Process.h"
#import "Variable.h"


@interface CheatData : NSObject < NSCoding >
{
	NSString *myWindowTitle;
	NSString *myCheatInfo;
	
	Process *myProcess;
	NSMutableArray *myVariables;
	
	BOOL myRepeats;
	NSTimeInterval myRepeatInterval;
}

// #############################################################################
#pragma mark NSCoding
// #############################################################################

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;


// #############################################################################
#pragma mark Accessing Properties
// #############################################################################

- (NSString *)windowTitle;
- (NSString *)cheatInfo;
- (NSString *)gameName;
- (NSString *)gameVersion;
- (Process *)process;
- (BOOL)repeats;
- (NSTimeInterval)repeatInterval;

- (void)setWindowTitle:(NSString *)title;
- (void)setCheatInfo:(NSString *)info;
- (void)setProcess:(Process *)process;
- (void)setRepeats:(BOOL)repeats;
- (void)setRepeatInterval:(NSTimeInterval)interval;


// #############################################################################
#pragma mark Variables
// #############################################################################

- (NSArray *)variables;
- (unsigned)variableCount;
- (unsigned)indexOfVariable:(Variable *)variable;
- (Variable *)variableAtIndex:(unsigned)index;
- (Variable *)lastVariable;

- (void)addVariable:(Variable *)variable;
- (void)insertVariable:(Variable *)variable atIndex:(unsigned)index;

- (void)removeAllVariables;
- (void)removeVariable:(Variable *)variable;
- (void)removeVariableAtIndex:(unsigned)index;

- (NSArray *)enabledVariables;
- (unsigned)enabledVariableCount;


@end
