
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

#import "Variable.h"


@interface Variable ( PrivateAPI )

- (void)_setType:(TCVariableType)type;
- (void)_setIntegerSign:(TCIntegerSign)sign;

@end


@implementation Variable


- (id)init
{
	return [self initWithType:TCInt32 integerSign:TCSigned];
}

- (id)initWithType:(TCVariableType)type
{
	return [self initWithType:type integerSign:TCSigned];
}

- (id)initWithType:(TCVariableType)type integerSign:(TCIntegerSign)sign // DESIGNATED
{
	if ( self = [super init] ) {
		_isValueValid = YES;
		_enabled = YES;
		[self _setType:type];
		[self _setIntegerSign:sign];
	}
	return self;
}


- (void)dealloc
{
	if ( _value ) {
		free( _value );
	}
	[super dealloc];
}


// #############################################################################
#pragma mark NSCoding
// #############################################################################

- (id)initWithCoder:(NSCoder *)coder
{
	if ( self = [super init] ) {
		[coder decodeValueOfObjCType:@encode(TCVariableType) at:&_type];
		[coder decodeValueOfObjCType:@encode(TCIntegerSign) at:&_integerSign];
		[coder decodeValueOfObjCType:@encode(TCAddress) at:&_address];
		[self setValue:[coder decodeBytesWithReturnedLength:&_size]];
		[coder decodeValueOfObjCType:@encode(BOOL) at:&_isValueValid];
		[coder decodeValueOfObjCType:@encode(BOOL) at:&_enabled];
		[coder decodeValueOfObjCType:@encode(int) at:&_tag];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeValueOfObjCType:@encode(TCVariableType) at:&_type];
	[coder encodeValueOfObjCType:@encode(TCIntegerSign) at:&_integerSign];
	[coder encodeValueOfObjCType:@encode(TCAddress) at:&_address];
	[coder encodeBytes:_value length:_size];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&_isValueValid];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&_enabled];
	[coder encodeValueOfObjCType:@encode(int) at:&_tag];
}


// #############################################################################
#pragma mark Accessors
// #############################################################################

- (TCVariableType)type
{
	return _type;
}

- (void)_setType:(TCVariableType)type
{
	_type = type;
	// set the size of the value
	switch ( _type ) {
		case TCInt64:
		case TCDouble: _size = 8;
			break;
		case TCInt32:
		case TCFloat: _size = 4;
			break;
		case TCInt16: _size = 2;
			break;
		case TCInt8: _size = 1;
			break;
	}
	
	if ( !_value ) {
		_value = calloc( 1, _size );
	}
}

- (TCIntegerSign)integerSign
{
	return _integerSign;
}

- (void)_setIntegerSign:(TCIntegerSign)sign
{
	_integerSign = sign;
}


- (NSString *)typeString
{
	switch ( _type ) {
		case TCDouble: return @"Double";
		case TCFloat: return @"Float";
		case TCString: return @"ASCII String";
	}
	if ( _integerSign == TCUnsigned ) {
		switch ( _type ) {
			case TCInt64: return @"64-bit Unsigned Integer";
			case TCInt32: return @"32-bit Unsigned Integer";
			case TCInt16: return @"16-bit Unsigned Integer";
			case TCInt8: return @"08-bit Unsigned Integer";
		}
	}
	else {
		switch ( _type ) {
			case TCInt64: return @"64-bit Integer";
			case TCInt32: return @"32-bit Integer";
			case TCInt16: return @"16-bit Integer";
			case TCInt8: return @"08-bit Integer";
		}
	}
	return @"";
}


- (TCAddress)address
{
	return _address;
}

- (void)setAddress:(TCAddress)addr
{
	_address = addr;
}


- (NSString *)addressString
{
	return [NSString stringWithFormat:@"%0.8X", _address];
}

- (BOOL)setAddressString:(NSString *)string
{
	NSScanner *scanner = [NSScanner scannerWithString:string];
	TCAddress address;
	
	if ( [scanner scanHexInt:(unsigned *)(&address)] ) {
		[self setAddress:address];
		return YES;
	}
	return NO;
}


- (void const *)value
{
	return _value;
}

- (void)setValue:(void const *)value
{
	if ( !_value ) {
		_value = malloc( _size );
	}
	
	_isValueValid = YES;
	memcpy( _value, value, _size );
}

- (void)setValue:(void const *)value size:(unsigned)size
{
	// make sure the size doesn't exceed the maximum
	size = MIN( size, TC_MAX_VAR_SIZE );
	// only string variables can have the value size changed
	if ( (_type == TCString) && (_size != size) && _value ) {
		void *newValue = realloc( _value, size );
		if ( newValue ) {
			_value = newValue;
			_size = size;
		}
	}
	_size = MIN( _size, size );
	
	[self setValue:value];
}


- (NSString *)stringValue
{
	switch ( _type ) {
		case TCDouble: return [NSString stringWithFormat:@"%.1lf", *(double *)[self value]];
		case TCFloat: return [NSString stringWithFormat:@"%.1f", *(float *)[self value]];
		case TCString: return [NSString stringWithCString:[self value] length:[self valueSize]];
	}
	if ( _integerSign == TCUnsigned ) {
		switch ( _type ) {
			case TCInt64: return [NSString stringWithFormat:@"%llu", *(UInt64 *)[self value]];
			case TCInt32: return [NSString stringWithFormat:@"%u", *(UInt32 *)[self value]];
			case TCInt16: return [NSString stringWithFormat:@"%u", *(UInt16 *)[self value]];
			case TCInt8: return [NSString stringWithFormat:@"%u", *(UInt8 *)[self value]];
		}
	}
	else {
		switch ( _type ) {
			case TCInt64: return [NSString stringWithFormat:@"%lli", *(SInt64 *)[self value]];
			case TCInt32: return [NSString stringWithFormat:@"%i", *(SInt32 *)[self value]];
			case TCInt16: return [NSString stringWithFormat:@"%i", *(SInt16 *)[self value]];
			case TCInt8: return [NSString stringWithFormat:@"%i", *(SInt8 *)[self value]];
		}
	}
	return @"foobar";
}

- (BOOL)setStringValue:(NSString *)string
{
	NSScanner *scanner = [NSScanner scannerWithString:string];
	
	// invalid until proven valid
	_isValueValid = NO;
	
	switch ( _type ) {
		case TCInt64:
		{
			SInt64 value;
			if ( [scanner scanLongLong:(long long *)(&value)] ) {
				[self setValue:&value];
			}
			break;
		}
		case TCInt32:
		{
			SInt32 value;
			if ( [scanner scanInt:(int *)(&value)] ) {
				[self setValue:&value];
			}
			break;
		}
		case TCInt16:
		{
			int integer;
			SInt16 value;
			if ( [scanner scanInt:&integer] ) {
				value = integer;
				[self setValue:&value];
			}
			break;
		}
		case TCInt8:
		{
			int integer;
			SInt8 value;
			if ( [scanner scanInt:&integer] ) {
				value = integer;
				[self setValue:&value];
			}
			break;
		}
		case TCString:
		{
			char *str = (char *)[string lossyCString];
			unsigned len = strlen( str );
			[self setValue:str size:len];
			break;
		}
		case TCFloat:
		{
			float value;
			if ( [scanner scanFloat:&value] ) {
				[self setValue:&value];
			}
			break;
		}
		case TCDouble:
		{
			double value;
			if ( [scanner scanDouble:&value] ) {
				[self setValue:&value];
			}
			break;
		}
	}
	return [self isValueValid];
}


- (unsigned)valueSize
{
	return _size;
}

- (BOOL)isValueValid
{
	return _isValueValid;
}


- (BOOL)isEnabled
{
	return _enabled;
}

- (void)setEnabled:(BOOL)enabled
{
	_enabled = enabled;
}


- (int)tag
{
	return _tag;
}

- (void)setTag:(int)tag
{
	_tag = tag;
}


@end
