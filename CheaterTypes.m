//
//  CheaterTypes.m
//  The Cheat
//
//  Created by Chaz McGarvey on 12/29/04.
//  Copyright 2004 Chaz McGarvey. All rights reserved.
//

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


