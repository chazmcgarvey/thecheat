
// **********************************************************************
// The Cheat - A universal game cheater for Mac OS X
// (C) 2003-2004 Chaz McGarvey (BrokenZipper)
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