
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


#import <Cocoa/Cocoa.h>
#include "ChazLog.h"

#import "CheaterTypes.h"
#import "Searching.h"
#import "VMRegion.h"
#import "Variable.h"


#define TC_BUFFER_SIZE (8192)
// used when buffers are expanded; use a multiple for 4096 because
// the virtual memory system uses those sizes for optimization.

#define TC_EPSILON (0.1)
// defines the accuracy for floating point comparisons


@interface SearchContext : NSObject
{
	/*
	 * So here's the big, bad, rather ugly search context class.
	 * There is quite a bit to keep track of, as you can see.
	 */
	
	TCVariableType _variableType;
	TCIntegerSign _integerSign;
	TCSearchOperator _operator;
	TCSearchType _searchType;
	
	// for fast access while iterating through the task loop.
	@public;
	
	pid_t process; // the pid of the process being searched
	unsigned regionCount; // estimation of the # of regions used for progress reporting
	VMRegion lastRegion; // used to find the next region to search
	
	Variable *value; // the value to compare against (TCGivenValue searches)
	BOOL (*compareFunc)(void const *, void const*); // comparison function
	
	TCArray addresses; // array to store hit addresses
	TCArray values; // parallel array to store hit values
	TCArray regions; // array of addresses, one for each region which contains a hit
	TCArray perRegion; // number of variables found for each region
	unsigned numberOfResults; // actual number of hits so far
	
	TCArray lastAddresses; // the addresses of variables to check
	TCArray lastValues; // the values to compare against (TCLastValue searches)
	TCArray lastRegions; // optimizes "again" searches
	TCArray lastPerRegion; // parallels lastRegions
	
	void *buffer; // the working buffer for reading in memory from the other app
	unsigned bufferSize; // size of the working buffer
	
	// pointers
	void *valuePtr, *lastValuePtr;
	TCAddress *addressPtr, *lastAddressPtr;
	TCAddress *lastRegionPtr;
	unsigned *lastPerRegionPtr;
	
	int progress; // 0-100
}

// Initialization

// this initializer must be used to create a context for a first-time search
- (id)initWithPID:(pid_t)pid searchOperator:(TCSearchOperator)op value:(Variable *)val;
// these initializers take data from the last search that was performed
- (id)initWithLastContext:(SearchContext *)context searchOperator:(TCSearchOperator)op;
- (id)initWithLastContext:(SearchContext *)context searchOperator:(TCSearchOperator)op value:(Variable *)val;

// Accessors

- (TCVariableType)variableType;
- (TCIntegerSign)integerSign;
- (TCSearchOperator)searchOperator;

- (BOOL (*)(void const *, void const *))compareFunction;
- (int (*)(id, unsigned))iterationFunction;


@end
