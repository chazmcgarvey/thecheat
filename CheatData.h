
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
