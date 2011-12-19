
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import <Cocoa/Cocoa.h>

#import "ThreadedTask.h"
#import "SearchContext.h"

#import "VMRegion.h"


extern __inline__ void ReportSearchProgress( ThreadedTask *task, unsigned iteration, unsigned regions, int *progress );



/*
 * Search iteration functions:
 * The first set is the generic one, the other is for strings.
 */

int SearchIteration( ThreadedTask *task, unsigned iteration );
int SearchIterationAgain( ThreadedTask *task, unsigned iteration );
int SearchIterationLastValue( ThreadedTask *task, unsigned iteration );

int SearchStringIteration( ThreadedTask *task, unsigned iteration );
int SearchStringIterationAgain( ThreadedTask *task, unsigned iteration );
int SearchStringIterationLastValue( ThreadedTask *task, unsigned iteration );


/*
 * Compare functions...
 * "Function( first, second)" -> "first [operator] second"
 */
BOOL EqualInt64( void const *first, void const *second );
BOOL EqualInt32( void const *first, void const *second );
BOOL EqualInt16( void const *first, void const *second );
BOOL EqualInt8( void const *first, void const *second );
BOOL EqualUInt64( void const *first, void const *second );
BOOL EqualUInt32( void const *first, void const *second );
BOOL EqualUInt16( void const *first, void const *second );
BOOL EqualUInt8( void const *first, void const *second );
BOOL EqualFloat( void const *first, void const *second );
BOOL EqualDouble( void const *first, void const *second );

BOOL NotEqualInt64( void const *first, void const *second );
BOOL NotEqualInt32( void const *first, void const *second );
BOOL NotEqualInt16( void const *first, void const *second );
BOOL NotEqualInt8( void const *first, void const *second );
BOOL NotEqualUInt64( void const *first, void const *second );
BOOL NotEqualUInt32( void const *first, void const *second );
BOOL NotEqualUInt16( void const *first, void const *second );
BOOL NotEqualUInt8( void const *first, void const *second );
BOOL NotEqualFloat( void const *first, void const *second );
BOOL NotEqualDouble( void const *first, void const *second );

BOOL LessThanInt64( void const *first, void const *second );
BOOL LessThanInt32( void const *first, void const *second );
BOOL LessThanInt16( void const *first, void const *second );
BOOL LessThanInt8( void const *first, void const *second );
BOOL LessThanUInt64( void const *first, void const *second );
BOOL LessThanUInt32( void const *first, void const *second );
BOOL LessThanUInt16( void const *first, void const *second );
BOOL LessThanUInt8( void const *first, void const *second );
BOOL LessThanFloat( void const *first, void const *second );
BOOL LessThanDouble( void const *first, void const *second );

BOOL GreaterThanInt64( void const *first, void const *second );
BOOL GreaterThanInt32( void const *first, void const *second );
BOOL GreaterThanInt16( void const *first, void const *second );
BOOL GreaterThanInt8( void const *first, void const *second );
BOOL GreaterThanUInt64( void const *first, void const *second );
BOOL GreaterThanUInt32( void const *first, void const *second );
BOOL GreaterThanUInt16( void const *first, void const *second );
BOOL GreaterThanUInt8( void const *first, void const *second );
BOOL GreaterThanFloat( void const *first, void const *second );
BOOL GreaterThanDouble( void const *first, void const *second );

/* Strings are handled by special iteration functions. */



