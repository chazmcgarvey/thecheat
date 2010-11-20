
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

#import "Variable.h"

#ifndef _Conversions_h_
#define _Conversions_h_


#pragma mark Prototypes

/* STRING -> VALUE */
// return YES for a successful conversion
BOOL StringToInt64( NSString *string, SInt64 *value );
BOOL StringToInt32( NSString *string, SInt32 *value );
BOOL StringToInt16( NSString *string, SInt16 *value );
BOOL StringToInt8( NSString *string, SInt8 *value );

BOOL StringToUInt64( NSString *string, UInt64 *value );
BOOL StringToUInt32( NSString *string, UInt32 *value );
BOOL StringToUInt16( NSString *string, UInt16 *value );
BOOL StringToUInt8( NSString *string, UInt8 *value );

// general case:
BOOL StringToValue( NSString *string, void *value, TCVariableType type );

/* VALUE -> STRING */
NSString *Int64ToString( SInt64 value );
NSString *Int32ToString( SInt32 value );
NSString *Int16ToString( SInt16 value );
NSString *Int8ToString( SInt8 value );

NSString *UInt64ToString( UInt64 value );
NSString *UInt32ToString( UInt32 value );
NSString *UInt16ToString( UInt16 value );
NSString *UInt8ToString( UInt8 value );

// general case:
NSString *ValueToString( void *value, TCVariableType type );


#endif /* _Conversions_h_ */
