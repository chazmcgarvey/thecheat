
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

#import "Conversions.h"


BOOL StringToInt32( NSString *string, SInt32 *value )
{
	SInt32 integer = 0;
	int place = 1;
	unichar characters[16];
	int i, stringlen;
	BOOL hasReadNumbers = NO, doneReading = NO;
	
	// fart around with the string
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	stringlen = [string length];
	if ( stringlen == 0 || stringlen >= 16 ) {
		// the string has the wrong size to be processed further
		return NO;
	}
	// read the string
	[string getCharacters:characters];
	
	// parse the string backwards
	for ( i = stringlen-1; i >= 0; i-- ) {
		// if we're done reading but still in the loop, there's a problem
		if ( doneReading ) {
			return NO;
		}
		if ( characters[i] >= 0x30 && characters[i] <= 0x39 ) {
			// the character is a number, update our value
			integer += (characters[i]-48) * place;
			place *= 10;
			hasReadNumbers = YES;
		}
		else if ( characters[i] == 0x2C /*comma*/ ) {
			// ignore these characters
		}
		else if ( hasReadNumbers ) {
			// check for plus or minus signs
			if ( characters[i] == 0x2D ) {
				integer = -integer;
				doneReading = YES;
			}
			else if ( characters[i] == 0x2B ) {
				doneReading = YES;
			}
			else {
				return NO;
			}
		}
		else {
			// the character is invalid, abort
			return NO;
		}
	}
	
	// success, return the value
	*value = integer;
	return YES;
}

BOOL StringToInt16( NSString *string, SInt16 *value )
{
	SInt16 integer = 0;
	int place = 1;
	unichar characters[16];
	int i, stringlen;
	BOOL hasReadNumbers = NO, doneReading = NO;
	
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	stringlen = [string length];
	if ( stringlen == 0 || stringlen >= 16 ) {
		return NO;
	}
	[string getCharacters:characters];
	
	for ( i = stringlen-1; i >= 0; i-- ) {
		if ( doneReading ) {
			return NO;
		}
		if ( characters[i] >= 0x30 && characters[i] <= 0x39 ) {
			integer += (characters[i]-48) * place;
			place *= 10;
			hasReadNumbers = YES;
		}
		else if ( characters[i] == 0x2C /*comma*/ ) {
		}
		else if ( hasReadNumbers ) {
			if ( characters[i] == 0x2D ) {
				integer = -integer;
				doneReading = YES;
			}
			else if ( characters[i] == 0x2B ) {
				doneReading = YES;
			}
			else {
				return NO;
			}
		}
		else {
			return NO;
		}
	}
	
	*value = integer;
	return YES;
}

BOOL StringToInt8( NSString *string, SInt8 *value )
{
	SInt8 integer = 0;
	int place = 1;
	unichar characters[16];
	int i, stringlen;
	BOOL hasReadNumbers = NO, doneReading = NO;
	
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	stringlen = [string length];
	if ( stringlen == 0 || stringlen >= 16 ) {
		return NO;
	}
	[string getCharacters:characters];
	
	for ( i = stringlen-1; i >= 0; i-- ) {
		if ( doneReading ) {
			return NO;
		}
		if ( characters[i] >= 0x30 && characters[i] <= 0x39 ) {
			integer += (characters[i]-48) * place;
			place *= 10;
			hasReadNumbers = YES;
		}
		else if ( characters[i] == 0x2C /*comma*/ ) {
		}
		else if ( hasReadNumbers ) {
			if ( characters[i] == 0x2D ) {
				integer = -integer;
				doneReading = YES;
			}
			else if ( characters[i] == 0x2B ) {
				doneReading = YES;
			}
			else {
				return NO;
			}
		}
		else {
			return NO;
		}
	}
	
	*value = integer;
	return YES;
}


BOOL StringToUInt32( NSString *string, UInt32 *value )
{
	UInt32 integer = 0;
	int place = 1;
	unichar characters[16];
	int i, stringlen;
	BOOL hasReadNumbers = NO, doneReading = NO;
	
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	stringlen = [string length];
	if ( stringlen == 0 || stringlen >= 16 ) {
		return NO;
	}
	[string getCharacters:characters];
	
	for ( i = stringlen-1; i >= 0; i-- ) {
		if ( doneReading ) {
			return NO;
		}
		if ( characters[i] >= 0x30 && characters[i] <= 0x39 ) {
			integer += (characters[i]-48) * place;
			place *= 10;
			hasReadNumbers = YES;
		}
		else if ( characters[i] == 0x2C /*comma*/ ) {
		}
		else if ( hasReadNumbers ) {
			if ( characters[i] == 0x2D ) {
				integer = -integer;
				doneReading = YES;
			}
			else if ( characters[i] == 0x2B ) {
				doneReading = YES;
			}
			else {
				return NO;
			}
		}
		else {
			return NO;
		}
	}
	
	*value = integer;
	return YES;
}

BOOL StringToUInt16( NSString *string, UInt16 *value )
{
	UInt16 integer = 0;
	int place = 1;
	unichar characters[16];
	int i, stringlen;
	BOOL hasReadNumbers = NO, doneReading = NO;
	
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	stringlen = [string length];
	if ( stringlen == 0 || stringlen >= 16 ) {
		return NO;
	}
	[string getCharacters:characters];
	
	for ( i = stringlen-1; i >= 0; i-- ) {
		if ( doneReading ) {
			return NO;
		}
		if ( characters[i] >= 0x30 && characters[i] <= 0x39 ) {
			integer += (characters[i]-48) * place;
			place *= 10;
			hasReadNumbers = YES;
		}
		else if ( characters[i] == 0x2C /*comma*/ ) {
		}
		else if ( hasReadNumbers ) {
			if ( characters[i] == 0x2D ) {
				integer = -integer;
				doneReading = YES;
			}
			else if ( characters[i] == 0x2B ) {
				doneReading = YES;
			}
			else {
				return NO;
			}
		}
		else {
			return NO;
		}
	}
	
	*value = integer;
	return YES;
}

BOOL StringToUInt8( NSString *string, UInt8 *value )
{
	UInt8 integer = 0;
	int place = 1;
	unichar characters[16];
	int i, stringlen;
	BOOL hasReadNumbers = NO, doneReading = NO;
	
	string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	stringlen = [string length];
	if ( stringlen == 0 || stringlen >= 16 ) {
		return NO;
	}
	[string getCharacters:characters];
	
	for ( i = stringlen-1; i >= 0; i-- ) {
		if ( doneReading ) {
			return NO;
		}
		if ( characters[i] >= 0x30 && characters[i] <= 0x39 ) {
			integer += (characters[i]-48) * place;
			place *= 10;
			hasReadNumbers = YES;
		}
		else if ( characters[i] == 0x2C /*comma*/ ) {
		}
		else if ( hasReadNumbers ) {
			if ( characters[i] == 0x2D ) {
				integer = -integer;
				doneReading = YES;
			}
			else if ( characters[i] == 0x2B ) {
				doneReading = YES;
			}
			else {
				return NO;
			}
		}
		else {
			return NO;
		}
	}
	
	*value = integer;
	return YES;
}


BOOL StringToFloat( NSString *string, float *value )
{
	float decimal;
	int stringlen;
	
	stringlen = [string length];
	if ( stringlen == 0 ) {
		return NO;
	}
	
	decimal = [string floatValue];
	
	*value = decimal;
	return YES;
}

BOOL StringToDouble( NSString *string, double *value )
{
	double decimal;
	int stringlen;
	
	stringlen = [string length];
	if ( stringlen == 0 ) {
		return NO;
	}
	
	decimal = [string doubleValue];
	
	*value = decimal;
	return YES;
}


// general case:
BOOL StringToValue( NSString *string, void *value, VariableType type )
{
	switch ( type ) {
		case Integer64Type:
			return StringToInt64( string, value );
		case Integer32Type:
			return StringToInt32( string, value );
		case Integer16Type:
			return StringToInt16( string, value );
		case Integer08Type:
			return StringToInt8( string, value );
		case UInteger64Type:
			return StringToUInt64( string, value );
		case UInteger32Type:
			return StringToUInt32( string, value );
		case UInteger16Type:
			return StringToUInt16( string, value );
		case UInteger08Type:
			return StringToUInt8( string, value );
	}
	return NO;
}


NSString *Int32ToString( SInt32 value )
{
	return [NSString stringWithFormat:@"%i", value];
}

NSString *Int16ToString( SInt16 value )
{
	return [NSString stringWithFormat:@"%i", value];
}

NSString *Int8ToString( SInt8 value )
{
	return [NSString stringWithFormat:@"%i", value];
}


NSString *UInt32ToString( UInt32 value )
{
	return [NSString stringWithFormat:@"%u", value];
}

NSString *UInt16ToString( UInt16 value )
{
	return [NSString stringWithFormat:@"%u", value];
}

NSString *UInt8ToString( UInt8 value )
{
	return [NSString stringWithFormat:@"%u", value];
}


NSString *FloatToString( float value )
{
	return [NSString stringWithFormat:@"%f", value];
}

NSString *DoubleToString( double value )
{
	return [NSString stringWithFormat:@"%f", value];
}

// general case:
NSString *ValueToString( void *value, VariableType type )
{
	switch ( type ) {
		case Integer64Type:
			return Int64ToString( *(SInt64 *)value );
		case Integer32Type:
			return Int32ToString( *(SInt32 *)value );
		case Integer16Type:
			return Int16ToString( *(SInt16 *)value );
		case Integer08Type:
			return Int8ToString( *(SInt8 *)value );
		case UInteger64Type:
			return UInt64ToString( *(UInt64 *)value );
		case UInteger32Type:
			return UInt32ToString( *(UInt32 *)value );
		case UInteger16Type:
			return UInt16ToString( *(UInt16 *)value );
		case UInteger08Type:
			return UInt8ToString( *(UInt8 *)value );
	}
	return NO;
}


