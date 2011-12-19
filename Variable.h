
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

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
	
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
	NSInteger _tag;
#else
	int _tag;
#endif

	Process *process;
	
	@public;
	// use the accessor methods unless you need fast access
	// do not change these variables directly or things will be screwed.
	TCVariableType _type;
	TCIntegerSign _integerSign;
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
	NSUInteger _size;
#else
	unsigned int _size;
#endif
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

#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
- (NSInteger)tag;
- (void)setTag:(NSInteger)tag;
#else
- (int)tag;
- (void)setTag:(int)tag;
#endif

@end
