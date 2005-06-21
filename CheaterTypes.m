
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


