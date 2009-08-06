
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


#import "Searching.h"


/*
 * WARNING! BEWARE! WATCH OUT!
 *
 * This source code file makes use of goto jump statements.  If goto statements
 * are disagreeable to you, you may want to skip over this file or you face the
 * possibility that you will be changed in a very deep and personal way.
 *
 * You have been warned.
 */


/* Here are some handy functions used in this file. */

void ReportSearchProgress( ThreadedTask *task, unsigned iteration, unsigned regions, int *progress )
{
	int newProgress = (iteration * 100) / regions;
	if ( newProgress > *progress ) {
		*progress = newProgress;
		[task reportProgress:newProgress];
	}
}


/*
 * This is a real gem. I have no idea where I got this, but it is a wicked
 * fast string searching algorithm.  Hope it's not patented...
 */
#define ASIZE 256
void *bmsearch( char *pat, int m, char *text, int n ) {
	int i,j,k,skip[ASIZE];if(m==0)return 0;
	for(k=0;k<ASIZE;k++)skip[k]=m;
	for(k=0;k<m-1;k++)skip[(int)pat[k]]=m-k-1;
	for(k=m-1;k<n;k+=skip[(int)text[k]&(ASIZE-1)]){
	for(j=m-1,i=k;j>=0&&text[i]==pat[j];j--)i--;
	if(j==-1)return(text+i+1);}
	return NULL;
}


#pragma mark -
#pragma mark Search Functions


int SearchIteration( ThreadedTask *task, unsigned iteration )
{
	SearchContext *context = [task context];
	VMRegion region;
	unsigned hitsPerRegion = 0;
	vm_size_t size;
	
	void *ptr, *top;
	TCAddress offset;
	
	region = VMNextRegionWithAttributes( context->process, context->lastRegion, VMREGION_READABLE | VMREGION_WRITABLE );
	if ( VMRegionIsNotNull( region ) ) {
		
		if ( context->bufferSize < VMRegionSize( region ) ) {
			char *buf = realloc( context->buffer, VMRegionSize( region ) );
			if ( buf ) {
				context->buffer = buf;
				context->bufferSize = VMRegionSize( region );
			}
			else {
				goto FAILURE;
			}
		}
		
		if ( !VMRegionBytes( region, context->buffer, &size ) ) {
			goto FAILURE;
		}
		
		ptr = context->buffer;
		top = context->buffer + VMRegionSize( region );
		offset = VMRegionAddress( region ) - (TCAddress)context->buffer;
		
		while ( ptr < top ) {
			char firstValue[context->value->_size];
			memcpy(firstValue, ptr, context->value->_size);
			
			if (context->value->_isEmulated)
			{
				if (context->value->_type == TCFloat)
				{
					CFSwappedFloat32 firstSwappedFloat = CFConvertFloat32HostToSwapped(*((float *)firstValue));
					memcpy(firstValue, &firstSwappedFloat, context->value->_size);
				}
				else if (context->value->_type == TCDouble)
				{
					CFSwappedFloat64 firstSwappedDouble = CFConvertDoubleHostToSwapped(*((double *)firstValue));
					memcpy(firstValue, &firstSwappedDouble, context->value->_size);
				}
			}
			
			if ( context->compareFunc(firstValue,context->value->_value) ) {
				if ( context->numberOfResults >= TCArrayElementCount(context->addresses) ) {
					TCArrayResize( context->addresses, TCArrayElementCount(context->addresses) + TC_BUFFER_SIZE / sizeof(TCAddress) );
					context->addressPtr = (TCAddress *)TCArrayBytes(context->addresses) + context->numberOfResults;
				}
				if ( context->numberOfResults >= TCArrayElementCount(context->values) ) {
					TCArrayResize( context->values, TCArrayElementCount(context->values) + TC_BUFFER_SIZE / TCArrayElementSize(context->values) );
					context->valuePtr = TCArrayBytes(context->values) + context->numberOfResults * TCArrayElementSize(context->values);
				}
				
				*context->addressPtr = (TCAddress)ptr + offset;
				memcpy( context->valuePtr, ptr, TCArrayElementSize( context->values ) );
				
				context->numberOfResults++;
				hitsPerRegion++;
				
				context->addressPtr++;
				context->valuePtr += TCArrayElementSize( context->values );
			}
			
			ptr += TCArrayElementSize( context->values );
		}
		
FAILURE:;
		if ( hitsPerRegion > 0 ) {
			TCAddress addr = VMRegionAddress( region );
			unsigned index = TCArrayElementCount( context->regions );
			unsigned newsize = index + 1;
			
			TCArrayResize( context->regions, newsize );
			TCArrayResize( context->perRegion, newsize );
			
			TCArraySetElementAtIndex( context->regions, index, &addr );
			TCArraySetElementAtIndex( context->perRegion, index, &hitsPerRegion );
		}
		
		ReportSearchProgress( task, iteration, context->regionCount, &context->progress );
		
		context->lastRegion = region;
		return 1;
	}
	else {
		free( context->buffer );
		context->buffer = NULL;
		TCArrayResize( context->addresses, context->numberOfResults );
		TCArrayResize( context->values, context->numberOfResults );
		return 0;
	}
}


int SearchIterationAgain( ThreadedTask *task, unsigned iteration )
{
	SearchContext *context = [task context];
	VMRegion region;
	unsigned hitsPerRegion = 0;
	vm_size_t size;
	
	void *ptr;
	unsigned i, top;
	
	if ( iteration < TCArrayElementCount( context->lastRegions ) ) {
		
		context->lastRegion = VMMakeRegion( context->process, *(context->lastRegionPtr), 0 );
		region = VMNextRegionWithAttributes( context->process, context->lastRegion, VMREGION_READABLE | VMREGION_WRITABLE );
		if ( VMRegionIsNotNull( region ) ) {
			if ( context->bufferSize < VMRegionSize( region ) ) {
				char *buf = realloc( context->buffer, VMRegionSize( region ) );
				if ( buf ) {
					context->buffer = buf;
					context->bufferSize = VMRegionSize( region );
				}
				else {
					goto FAILURE;
				}
			}
			
			if ( !VMRegionBytes( region, context->buffer, &size ) ) {
				goto FAILURE;
			}
			
			top = *context->lastPerRegionPtr;
			
			for ( i = 0; i < top; i++ ) {
				ptr = context->buffer + *context->lastAddressPtr - VMRegionAddress(region);
				
				char firstValue[context->value->_size];
				memcpy(firstValue, ptr, context->value->_size);
				
				if (context->value->_isEmulated)
				{
					if (context->value->_type == TCFloat)
					{
						CFSwappedFloat32 firstSwappedFloat = CFConvertFloat32HostToSwapped(*((float *)firstValue));
						memcpy(firstValue, &firstSwappedFloat, context->value->_size);
					}
					else if (context->value->_type == TCDouble)
					{
						CFSwappedFloat64 firstSwappedDouble = CFConvertDoubleHostToSwapped(*((double *)firstValue));
						memcpy(firstValue, &firstSwappedDouble, context->value->_size);
					}
				}
				
				if (ptr >= context->buffer && context->compareFunc(firstValue,context->value->_value)) {
					if ( context->numberOfResults >= TCArrayElementCount(context->addresses) ) {
						TCArrayResize( context->addresses, TCArrayElementCount(context->addresses) + TC_BUFFER_SIZE / sizeof(TCAddress) );
						context->addressPtr = (TCAddress *)TCArrayBytes(context->addresses) + context->numberOfResults;
					}
					if ( context->numberOfResults >= TCArrayElementCount(context->values) ) {
						TCArrayResize( context->values, TCArrayElementCount(context->values) + TC_BUFFER_SIZE / TCArrayElementSize(context->values) );
						context->valuePtr = TCArrayBytes(context->values) + context->numberOfResults * TCArrayElementSize(context->values);
					}
					
					*context->addressPtr = *context->lastAddressPtr;
					memcpy( context->valuePtr, ptr, TCArrayElementSize( context->values ) );
					
					context->numberOfResults++;
					hitsPerRegion++;
					
					context->addressPtr++;
					context->valuePtr += TCArrayElementSize( context->values );
				}
				
				context->lastAddressPtr++;
			}
		}
		
FAILURE:;
		context->lastRegionPtr++;
		context->lastPerRegionPtr++;
		
		if ( hitsPerRegion > 0 ) {
			TCAddress addr = VMRegionAddress( region );
			unsigned index = TCArrayElementCount( context->regions );
			unsigned newsize = index + 1;
			
			TCArrayResize( context->regions, newsize );
			TCArrayResize( context->perRegion, newsize );
			
			TCArraySetElementAtIndex( context->regions, index, &addr );
			TCArraySetElementAtIndex( context->perRegion, index, &hitsPerRegion );
		}
		
		ReportSearchProgress( task, iteration, context->regionCount, &context->progress );
		
		context->lastRegion = region;
		return 1;
	}
	else {
		free( context->buffer );
		context->buffer = NULL;
		TCArrayResize( context->addresses, context->numberOfResults );
		TCArrayResize( context->values, context->numberOfResults );
		return 0;
	}
}


int SearchIterationLastValue( ThreadedTask *task, unsigned iteration )
{
	SearchContext *context = [task context];
	VMRegion region;
	unsigned hitsPerRegion = 0;
	vm_size_t size;
	
	void *ptr;
	unsigned i, top;
	
	if ( iteration < TCArrayElementCount( context->lastRegions ) ) {
		
		context->lastRegion = VMMakeRegion( context->process, *(context->lastRegionPtr), 0 );
		region = VMNextRegionWithAttributes( context->process, context->lastRegion, VMREGION_READABLE | VMREGION_WRITABLE );
		if ( VMRegionIsNotNull( region ) ) {
			
			if ( context->bufferSize < VMRegionSize( region ) ) {
				char *buf = realloc( context->buffer, VMRegionSize( region ) );
				if ( buf ) {
					context->buffer = buf;
					context->bufferSize = VMRegionSize( region );
				}
				else {
					goto FAILURE;
				}
			}
			
			if ( !VMRegionBytes( region, context->buffer, &size ) ) {
				goto FAILURE;
			}
			
			top = *context->lastPerRegionPtr;
			
			for ( i = 0; i < top; i++ ) {
				
				ptr = context->buffer + *context->lastAddressPtr - VMRegionAddress(region);
				if ( ptr >= context->buffer && context->compareFunc(ptr,context->lastValuePtr) ) {
					if ( context->numberOfResults >= TCArrayElementCount(context->addresses) ) {
						TCArrayResize( context->addresses, TCArrayElementCount(context->addresses) + TC_BUFFER_SIZE / sizeof(TCAddress) );
						context->addressPtr = (TCAddress *)TCArrayBytes(context->addresses) + context->numberOfResults;
					}
					if ( context->numberOfResults >= TCArrayElementCount(context->values) ) {
						TCArrayResize( context->values, TCArrayElementCount(context->values) + TC_BUFFER_SIZE / TCArrayElementSize(context->values) );
						context->valuePtr = TCArrayBytes(context->values) + context->numberOfResults * TCArrayElementSize(context->values);
					}
					
					*context->addressPtr = *context->lastAddressPtr;
					memcpy( context->valuePtr, ptr, TCArrayElementSize(context->values) );
					
					context->numberOfResults++;
					hitsPerRegion++;
					
					context->addressPtr++;
					context->valuePtr += TCArrayElementSize(context->values);
				}
				
				context->lastAddressPtr++;
				context->lastValuePtr += TCArrayElementSize(context->values);
			}
		}
		
FAILURE:;
		context->lastRegionPtr++;
		context->lastPerRegionPtr++;
		
		if ( hitsPerRegion > 0 ) {
			TCAddress addr = VMRegionAddress( region );
			unsigned index = TCArrayElementCount( context->regions );
			unsigned newsize = index + 1;
			
			TCArrayResize( context->regions, newsize );
			TCArrayResize( context->perRegion, newsize );
			
			TCArraySetElementAtIndex( context->regions, index, &addr );
			TCArraySetElementAtIndex( context->perRegion, index, &hitsPerRegion );
		}
		
		ReportSearchProgress( task, iteration, context->regionCount, &context->progress );
		
		context->lastRegion = region;
		return 1;
	}
	else {
		free( context->buffer );
		context->buffer = NULL;
		TCArrayResize( context->addresses, context->numberOfResults );
		TCArrayResize( context->values, context->numberOfResults );
		return 0;
	}
}



int SearchStringIteration( ThreadedTask *task, unsigned iteration )
{
	SearchContext *context = [task context];
	VMRegion region;
	unsigned hitsPerRegion = 0;
	vm_size_t size;
	
	void *ptr, *top, *hit;
	TCAddress offset;
	
	region = VMNextRegionWithAttributes( context->process, context->lastRegion, VMREGION_READABLE | VMREGION_WRITABLE );
	if ( VMRegionIsNotNull( region ) ) {
		
		if ( context->bufferSize < VMRegionSize(region) ) {
			char *buf = realloc( context->buffer, VMRegionSize( region ) );
			if ( buf ) {
				context->buffer = buf;
				context->bufferSize = VMRegionSize(region);
			}
			else {
				goto FAILURE;
			}
		}
		
		if ( !VMRegionBytes( region, context->buffer, &size ) ) {
			goto FAILURE;
		}
		
		ptr = context->buffer;
		top = context->buffer + VMRegionSize( region );
		offset = VMRegionAddress( region ) - (TCAddress)context->buffer;
		
		do {
			hit = bmsearch( context->value->_value, context->value->_size, ptr, top - ptr );
			if ( hit ) {
				if ( context->numberOfResults >= TCArrayElementCount(context->addresses) ) {
					TCArrayResize( context->addresses, TCArrayElementCount(context->addresses) + TC_BUFFER_SIZE / sizeof(TCAddress) );
					context->addressPtr = (TCAddress *)TCArrayBytes(context->addresses) + context->numberOfResults;
				}
				if ( context->numberOfResults >= TCArrayElementCount(context->values) ) {
					TCArrayResize( context->values, TCArrayElementCount(context->values) + TC_BUFFER_SIZE / TCArrayElementSize(context->values) );
					context->valuePtr = TCArrayBytes(context->values) + context->numberOfResults * TCArrayElementSize(context->values);
				}
				
				*context->addressPtr = (TCAddress)hit + offset;
				memcpy( context->valuePtr, hit, context->value->_size );
				context->addressPtr++;
				context->valuePtr += context->value->_size;
				
				context->numberOfResults++;
				hitsPerRegion++;
			}
			
			ptr = hit + 1;
		}
		while ( hit );
		
FAILURE:;
		if ( hitsPerRegion > 0 ) {
			TCAddress addr = VMRegionAddress( region );
			unsigned index = TCArrayElementCount( context->regions );
			unsigned newsize = index + 1;
			
			TCArrayResize( context->regions, newsize );
			TCArrayResize( context->perRegion, newsize );
			
			TCArraySetElementAtIndex( context->regions, index, &addr );
			TCArraySetElementAtIndex( context->perRegion, index, &hitsPerRegion );
		}
		
		ReportSearchProgress( task, iteration, context->regionCount, &context->progress );
		
		context->lastRegion = region;
		return 1;
	}
	else {
		free( context->buffer );
		context->buffer = NULL;
		TCArrayResize( context->addresses, context->numberOfResults );
		TCArrayResize( context->values, context->numberOfResults );
		return 0;
	}
}

int SearchStringIterationAgain( ThreadedTask *task, unsigned iteration )
{
	SearchContext *context = [task context];
	VMRegion region;
	unsigned hitsPerRegion = 0;
	vm_size_t size;
	
	void *ptr;
	unsigned i, top;
	
	if ( iteration < TCArrayElementCount( context->lastRegions ) ) {
		
		context->lastRegion = VMMakeRegion( context->process, *(context->lastRegionPtr), 0 );
		region = VMNextRegionWithAttributes( context->process, context->lastRegion, VMREGION_READABLE | VMREGION_WRITABLE );
		if ( VMRegionIsNotNull( region ) ) {
			
			if ( context->bufferSize < VMRegionSize( region ) ) {
				char *buf = realloc( context->buffer, VMRegionSize( region ) );
				if ( buf ) {
					context->buffer = buf;
					context->bufferSize = VMRegionSize( region );
				}
				else {
					goto FAILURE;
				}
			}
			
			if ( !VMRegionBytes( region, context->buffer, &size ) ) {
				goto FAILURE;
			}
			
			top = *context->lastPerRegionPtr;
			
			for ( i = 0; i < top; i++ ) {
				
				ptr = context->buffer + *context->lastAddressPtr - VMRegionAddress(region);
				
				if ( ptr >= context->buffer && memcmp( ptr, context->value->_value, MIN(TCArrayElementSize(context->values),context->buffer+VMRegionAddress(region)-ptr) ) == 0 ) {
					if ( context->numberOfResults >= TCArrayElementCount(context->addresses) ) {
						TCArrayResize( context->addresses, TCArrayElementCount(context->addresses) + TC_BUFFER_SIZE / sizeof(TCAddress) );
						context->addressPtr = (TCAddress *)TCArrayBytes(context->addresses) + context->numberOfResults;
					}
					if ( context->numberOfResults >= TCArrayElementCount(context->values) ) {
						TCArrayResize( context->values, TCArrayElementCount(context->values) + TC_BUFFER_SIZE / TCArrayElementSize(context->values) );
						context->valuePtr = TCArrayBytes(context->values) + context->numberOfResults * TCArrayElementSize(context->values);
					}
					
					*context->addressPtr = *context->lastAddressPtr;
					memcpy( context->valuePtr, ptr, TCArrayElementSize( context->values ) );
					context->addressPtr++;
					context->valuePtr += TCArrayElementSize( context->values );
					
					context->numberOfResults++;
					hitsPerRegion++;
				}
				
				context->lastAddressPtr++;
			}
		}
		
FAILURE:;
		context->lastRegionPtr++;
		context->lastPerRegionPtr++;
		
		if ( hitsPerRegion > 0 ) {
			TCAddress addr = VMRegionAddress( region );
			unsigned index = TCArrayElementCount( context->regions );
			unsigned newsize = index + 1;
			
			TCArrayResize( context->regions, newsize );
			TCArrayResize( context->perRegion, newsize );
			
			TCArraySetElementAtIndex( context->regions, index, &addr );
			TCArraySetElementAtIndex( context->perRegion, index, &hitsPerRegion );
		}
		
		ReportSearchProgress( task, iteration, context->regionCount, &context->progress );
		
		context->lastRegion = region;
		return 1;
	}
	else {
		free( context->buffer );
		context->buffer = NULL;
		TCArrayResize( context->addresses, context->numberOfResults );
		TCArrayResize( context->values, context->numberOfResults );
		return 0;
	}
}

int SearchStringIterationLastValue( ThreadedTask *task, unsigned iteration )
{
	SearchContext *context = [task context];
	VMRegion region;
	unsigned hitsPerRegion = 0;
	vm_size_t size;
	
	void *ptr;
	unsigned i, top;
	
	if ( iteration < TCArrayElementCount( context->lastRegions ) ) {
		
		context->lastRegion = VMMakeRegion( context->process, *(context->lastRegionPtr), 0 );
		region = VMNextRegionWithAttributes( context->process, context->lastRegion, VMREGION_READABLE | VMREGION_WRITABLE );
		if ( VMRegionIsNotNull( region ) ) {
			
			if ( context->bufferSize < VMRegionSize( region ) ) {
				char *buf = realloc( context->buffer, VMRegionSize( region ) );
				if ( buf ) {
					context->buffer = buf;
					context->bufferSize = VMRegionSize( region );
				}
				else {
					goto FAILURE;
				}
			}
			
			if ( !VMRegionBytes( region, context->buffer, &size ) ) {
				goto FAILURE;
			}
			
			top = *context->lastPerRegionPtr;
			
			for ( i = 0; i < top; i++ ) {
				
				ptr = context->buffer + *context->lastAddressPtr - VMRegionAddress(region);
				if ( ptr >= context->buffer && memcmp( ptr, context->lastValuePtr, MIN(TCArrayElementSize(context->values),context->buffer+VMRegionAddress(region)-ptr) ) == 0 ) {
					if ( context->numberOfResults >= TCArrayElementCount(context->addresses) ) {
						TCArrayResize( context->addresses, TCArrayElementCount(context->addresses) + TC_BUFFER_SIZE / sizeof(TCAddress) );
						context->addressPtr = (TCAddress *)TCArrayBytes(context->addresses) + context->numberOfResults;
					}
					if ( context->numberOfResults >= TCArrayElementCount(context->values) ) {
						TCArrayResize( context->values, TCArrayElementCount(context->values) + TC_BUFFER_SIZE / TCArrayElementSize(context->values) );
						context->valuePtr = TCArrayBytes(context->values) + context->numberOfResults * TCArrayElementSize(context->values);
					}
					
					*context->addressPtr = *context->lastAddressPtr;
					memcpy( context->valuePtr, ptr, TCArrayElementSize(context->values) );
					context->addressPtr++;
					context->valuePtr += TCArrayElementSize(context->values);
					
					context->numberOfResults++;
					hitsPerRegion++;
				}
				
				context->lastAddressPtr++;
				context->lastValuePtr += TCArrayElementSize(context->lastValues);
			}
		}
		
FAILURE:;
		context->lastRegionPtr++;
		context->lastPerRegionPtr++;
		
		if ( hitsPerRegion > 0 ) {
			TCAddress addr = VMRegionAddress( region );
			unsigned index = TCArrayElementCount( context->regions );
			unsigned newsize = index + 1;
			
			TCArrayResize( context->regions, newsize );
			TCArrayResize( context->perRegion, newsize );
			
			TCArraySetElementAtIndex( context->regions, index, &addr );
			TCArraySetElementAtIndex( context->perRegion, index, &hitsPerRegion );
		}
		
		ReportSearchProgress( task, iteration, context->regionCount, &context->progress );
		
		context->lastRegion = region;
		return 1;
	}
	else {
		free( context->buffer );
		context->buffer = NULL;
		TCArrayResize( context->addresses, context->numberOfResults );
		TCArrayResize( context->values, context->numberOfResults );
		return 0;
	}
}



#pragma mark -
#pragma mark Comparison Functions



BOOL EqualInt64( void const *first, void const *second ) {
	return *(SInt64 *)first == *(SInt64 *)second;
}
BOOL EqualInt32( void const *first, void const *second ) {
	return *(SInt32 *)first == *(SInt32 *)second;
}
BOOL EqualInt16( void const *first, void const *second ) {
	return *(SInt16 *)first == *(SInt16 *)second;
}
BOOL EqualInt8( void const *first, void const *second ) {
	return *(SInt8 *)first == *(SInt8 *)second;
}
BOOL EqualUInt64( void const *first, void const *second ) {
	return *(UInt64 *)first == *(UInt64 *)second;
}
BOOL EqualUInt32( void const *first, void const *second ) {
	return *(UInt32 *)first == *(UInt32 *)second;
}
BOOL EqualUInt16( void const *first, void const *second ) {
	return *(UInt16 *)first == *(UInt16 *)second;
}
BOOL EqualUInt8( void const *first, void const *second ) {
	return *(UInt8 *)first == *(UInt8 *)second;
}
BOOL EqualFloat( void const *first, void const *second ) {
	return TC_EPSILON > ABS( *(float *)first - *(float *)second );
}
BOOL EqualDouble( void const *first, void const *second ) {
	return TC_EPSILON > ABS( *(double *)first - *(double *)second );
}

BOOL NotEqualInt64( void const *first, void const *second ) {
	return *(SInt64 *)first != *(SInt64 *)second;
}
BOOL NotEqualInt32( void const *first, void const *second ) {
	return *(SInt32 *)first != *(SInt32 *)second;
}
BOOL NotEqualInt16( void const *first, void const *second ) {
	return *(SInt16 *)first != *(SInt16 *)second;
}
BOOL NotEqualInt8( void const *first, void const *second ) {
	return *(SInt8 *)first != *(SInt8 *)second;
}
BOOL NotEqualUInt64( void const *first, void const *second ) {
	return *(UInt64 *)first != *(UInt64 *)second;
}
BOOL NotEqualUInt32( void const *first, void const *second ) {
	return *(UInt32 *)first != *(UInt32 *)second;
}
BOOL NotEqualUInt16( void const *first, void const *second ) {
	return *(UInt16 *)first != *(UInt16 *)second;
}
BOOL NotEqualUInt8( void const *first, void const *second ) {
	return *(UInt8 *)first != *(UInt8 *)second;
}
BOOL NotEqualFloat( void const *first, void const *second ) {
	return TC_EPSILON <= ABS( *(float *)first - *(float *)second );
}
BOOL NotEqualDouble( void const *first, void const *second ) {
	return TC_EPSILON <= ABS( *(double *)first - *(double *)second );
}

BOOL LessThanInt64( void const *first, void const *second ) {
	return *(SInt64 *)first < *(SInt64 *)second;
}
BOOL LessThanInt32( void const *first, void const *second ) {
	return *(SInt32 *)first < *(SInt32 *)second;
}
BOOL LessThanInt16( void const *first, void const *second ) {
	return *(SInt16 *)first < *(SInt16 *)second;
}
BOOL LessThanInt8( void const *first, void const *second ) {
	return *(SInt8 *)first < *(SInt8 *)second;
}
BOOL LessThanUInt64( void const *first, void const *second ) {
	return *(UInt64 *)first < *(UInt64 *)second;
}
BOOL LessThanUInt32( void const *first, void const *second ) {
	return *(UInt32 *)first < *(UInt32 *)second;
}
BOOL LessThanUInt16( void const *first, void const *second ) {
	return *(UInt16 *)first < *(UInt16 *)second;
}
BOOL LessThanUInt8( void const *first, void const *second ) {
	return *(UInt8 *)first < *(UInt8 *)second;
}
BOOL LessThanFloat( void const *first, void const *second ) {
	return *(float *)first < *(float *)second;
}
BOOL LessThanDouble( void const *first, void const *second ) {
	return *(double *)first < *(double *)second;
}

BOOL GreaterThanInt64( void const *first, void const *second ) {
	return *(SInt64 *)first > *(SInt64 *)second;
}
BOOL GreaterThanInt32( void const *first, void const *second ) {
	return *(SInt32 *)first > *(SInt32 *)second;
}
BOOL GreaterThanInt16( void const *first, void const *second ) {
	return *(SInt16 *)first > *(SInt16 *)second;
}
BOOL GreaterThanInt8( void const *first, void const *second ) {
	return *(SInt8 *)first > *(SInt8 *)second;
}
BOOL GreaterThanUInt64( void const *first, void const *second ) {
	return *(UInt64 *)first > *(UInt64 *)second;
}
BOOL GreaterThanUInt32( void const *first, void const *second ) {
	return *(UInt32 *)first > *(UInt32 *)second;
}
BOOL GreaterThanUInt16( void const *first, void const *second ) {
	return *(UInt16 *)first > *(UInt16 *)second;
}
BOOL GreaterThanUInt8( void const *first, void const *second ) {
	return *(UInt8 *)first > *(UInt8 *)second;
}
BOOL GreaterThanFloat( void const *first, void const *second ) {
	return *(float *)first > *(float *)second;
}
BOOL GreaterThanDouble( void const *first, void const *second ) {
	return *(double *)first > *(double *)second;
}





