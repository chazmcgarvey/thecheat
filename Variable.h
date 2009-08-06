
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

#import "CheaterTypes.h"
#import "Process.h"

#include <string.h>


#define TC_MAX_VAR_SIZE (256)

@interface Variable : NSObject < NSCoding >
{
	TCAddress _address;
	BOOL _isValueValid;
	BOOL _enabled;
	
	int _tag;
	
	Process *process;
	
	@public;
	// use the accessor methods unless you need fast access
	// do not change these variables directly or things will be screwed.
	TCVariableType _type;
	TCIntegerSign _integerSign;
	unsigned _size;
	void *_value;
	BOOL _isEmulated;
}

// #############################################################################
#pragma mark Initialization
// #############################################################################

// type and sign can't be changed once variable is created.

- (id)init; // default: TCInt32
- (id)initWithType:(TCVariableType)type; // default: TCSigned
- (id)initWithType:(TCVariableType)type integerSign:(TCIntegerSign)sign;

- (void)setProcess:(Process *)process;
- (Process *)process;

- (BOOL)isEmulated;

// #############################################################################
#pragma mark NSCoding
// #############################################################################

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

// #############################################################################
#pragma mark Accessors
// #############################################################################

- (TCVariableType)type;
- (TCIntegerSign)integerSign;
- (NSString *)typeString;

- (TCAddress)address;
- (void)setAddress:(TCAddress)addr;
- (NSString *)addressString;
- (BOOL)setAddressString:(NSString *)string;

- (void const *)value;
- (void)setValue:(void const *)value;
- (void)setValue:(void const *)value size:(unsigned)size;
- (NSString *)stringValue;
- (BOOL)setStringValue:(NSString *)value;

void bigEndianValue(void *buffer, Variable *variable);

- (unsigned)valueSize;
- (BOOL)isValueValid;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

- (int)tag;
- (void)setTag:(int)tag;

@end
