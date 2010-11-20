
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

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

- (void)setProcess:(Process *)newProcess
{
	if (process != newProcess && [newProcess pid] > 0)
	{
		_isEmulated = [newProcess isEmulated];
		
		[newProcess retain];
		[process release];
		process = newProcess;
	}
}

- (Process *)process
{
	return process;
}

- (BOOL)isEmulated
{
	return _isEmulated;
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
		
		void *value = [coder decodeBytesWithReturnedLength:&_size];
		
		if (_type == TCString || _type == TCInt8)
		{
			[self setValue:value];
		}
		else if (_type == TCInt16)
		{
			int16_t newVariable = CFSwapInt16BigToHost(*((int16_t *)value));
			[self setValue:&newVariable];
		}
		else if (_type == TCInt32)
		{
			int32_t newVariable = CFSwapInt32BigToHost(*((int32_t *)value));
			[self setValue:&newVariable];
		}
		else if (_type == TCInt64)
		{
			int64_t newVariable = CFSwapInt64BigToHost(*((int64_t *)value));
			[self setValue:&newVariable];
		}
		else if (_type == TCFloat)
		{
#ifdef __LITTLE_ENDIAN__
			CFSwappedFloat32 newVariable = CFConvertFloat32HostToSwapped(*((float *)value));
			[self setValue:&(newVariable.v)];
			
#else
			[self setValue:value];
#endif
		}
		else if (_type == TCDouble)
		{
#ifdef __LITTLE_ENDIAN__
			CFSwappedFloat64 newVariable = CFConvertDoubleHostToSwapped(*((double *)value));
			[self setValue:&(newVariable.v)];
#else
			[self setValue:value];
#endif
		}
		
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
	
	if (_type == TCString || _type == TCInt8)
	{
		[coder encodeBytes:_value length:_size];
	}
	else if (_type == TCInt16)
	{
		int16_t newVariable = CFSwapInt16HostToBig(*((int16_t *)_value));
		[coder encodeBytes:&newVariable length:_size];
	}
	else if (_type == TCInt32)
	{
		int32_t newVariable = CFSwapInt32HostToBig(*((int32_t *)_value));
		[coder encodeBytes:&newVariable length:_size];
	}
	else if (_type == TCInt64)
	{
		int64_t newVariable = CFSwapInt64HostToBig(*((int64_t *)_value));
		[coder encodeBytes:&newVariable length:_size];
	}
	else if (_type == TCFloat)
	{
#ifdef __LITTLE_ENDIAN__
		CFSwappedFloat32 newVariable = CFConvertFloat32HostToSwapped(*((float *)_value));
		[coder encodeBytes:&newVariable length:_size];
#else
		[coder encodeBytes:&_value length:_size];
#endif
	}
	else if (_type == TCDouble)
	{
#ifdef __LITTLE_ENDIAN__
		CFSwappedFloat64 newVariable = CFConvertDoubleHostToSwapped(*((double *)_value));
		[coder encodeBytes:&newVariable length:_size];
#else
		[coder encodeBytes:_value length:_size];
#endif
	}
	
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
//		return [NSString stringWithFormat:@"%0.8X", _address];
	return [NSString stringWithFormat:(_address & 0xffffffff00000000ULL) ? @"%0.16qX": @"%0.8X", _address];
}

- (BOOL)setAddressString:(NSString *)string
{
	NSScanner *scanner = [NSScanner scannerWithString:string];
	TCAddress address;
	
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
	if ( [scanner scanHexLongLong:(unsigned long long *)(&address)] ) {
#else
	if ( [scanner scanHexInt:(unsigned *)(&address)] ) {
#endif
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
//			if ( [scanner scanInt:(int *)(&value)] ) {
			int integer;
			if ( [scanner scanInt:&integer] ) {
				value = integer;
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

// this only converts the byte order of the value at buffer if the process is running under rosetta on an intel mac
// floats and double's byte ordering should not be changed when searching for values because they may be swapped to '0.0'
void bigEndianValue(void *buffer, Variable *variable)
{
	if (variable->_isEmulated)
	{
		if (variable->_type == TCInt16)
		{
			int16_t newValue = CFSwapInt16HostToBig(*((int16_t *)buffer));
			memcpy(buffer, &newValue, sizeof(int16_t));
		}
		else if (variable->_type == TCInt32)
		{
			int32_t newValue = CFSwapInt32HostToBig(*((int32_t *)buffer));
			memcpy(buffer, &newValue, sizeof(int32_t));
		}
		else if (variable->_type == TCInt64)
		{
			int64_t newValue = CFSwapInt64HostToBig(*((int64_t *)buffer));
			memcpy(buffer, &newValue, sizeof(int64_t));
		}
		else if (variable->_type == TCFloat)
		{
			CFSwappedFloat32 newValue = CFConvertFloat32HostToSwapped(*((float *)buffer));
			memcpy(buffer, &(newValue.v), sizeof(float));
		}
		else if (variable->_type == TCDouble)
		{
			CFSwappedFloat64 newValue = CFConvertDoubleHostToSwapped(*((double *)buffer));
			memcpy(buffer, &(newValue.v), sizeof(double));
		}
	}
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


#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
- (NSInteger)tag
#else
- (int)tag
#endif
{
	return _tag;
}

#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
- (void)setTag:(NSInteger)tag
#else
- (void)setTag:(int)tag
#endif
{
	_tag = tag;
}


@end
