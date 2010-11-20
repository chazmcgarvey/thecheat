
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "CheaterTypes.h"


TCArray TCMakeArray( unsigned count, unsigned size )
{
	TCArray array = (TCArray)malloc( sizeof(struct _TCArray) );
	
	if ( array ) {
		array->_bytes = malloc( count * size );
		
		if ( array->_bytes ) {
			array->_count = count;
			array->_size = size;
			array->_ownsBytes = YES;
		}
		else {
			free( array );
			return NULL;
		}
	}
	return array;
}

TCArray TCMakeArrayWithBytes( unsigned count, unsigned size, void *bytes )
{
	TCArray array = TCMakeArray( count, size );
	
	if ( array && bytes ) {
		memcpy( array->_bytes, bytes, count * size );
	}
	return array;
}

void TCReleaseArray( TCArray array )
{
	if ( array && array->_ownsBytes ) {
		free( array->_bytes );
		free( array );
	}
}


void TCArrayAppendArray( TCArray array, TCArray other )
{
	unsigned oldCount = array->_count;
	unsigned count = oldCount + other->_count;
	
	if ( array->_size != other->_size ) {
		return;
	}
	
	TCArrayResize( array, count );
	if ( array->_count == count ) {
		memcpy( array->_bytes + oldCount * array->_size, other->_bytes, other->_count * other->_size );
	}
}


NSString *TCStringFromArray( TCArray array )
{
	return [NSString stringWithFormat:@"{%p,%u,%u}", array->_bytes, array->_count, array->_size];
}


