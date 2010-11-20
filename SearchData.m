
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "SearchData.h"


@implementation SearchData


- (id)init
{
	if ( self = [super init] ) {
		[self setVariableType:TCInt32];
		[self setIntegerSign:TCSigned];
		[self setSearchOperator:TCEqual];
		[self setValueUsed:TCGivenValue];
		
		_undoes = -1;
		_redoes = 0;
	}
	return self;
}

- (void)dealloc
{
	[_variableValue release];
	TCReleaseArray( _addresses );
	TCReleaseArray( _values );
	[super dealloc];
}


- (void)setProcess:(Process *)process
{
	[process retain];
	[_process release];
	_process = process;
}


- (TCVariableType)variableType
{
	return _variableType;
}

- (void)setVariableType:(TCVariableType)varType
{
	// can't change the variable type when there has been a search
	if ( ![self hasSearchedOnce] ) {
		_variableType = varType;
	}
}


- (TCIntegerSign)integerSign
{
	return _integerSign;
}

- (void)setIntegerSign:(TCIntegerSign)sign
{
	// can't change the integer sign when there has been a search
	if ( ![self hasSearchedOnce] ) {
		_integerSign = sign;
	}
}


- (TCSearchOperator)searchOperator
{
	return _operator;
}

- (void)setSearchOperator:(TCSearchOperator)op
{
	_operator = op;
}


- (TCSearchType)valueUsed
{
	if ( ![self hasSearchedOnce] ) {
		// if there is no search, then use search value no matter what
		_value = TCGivenValue;
	}
	return _value;
}

- (void)setValueUsed:(TCSearchType)value
{
	_value = value;
}


- (Variable *)searchValue
{
	if ( !_variableValue ) {
		// create a zero value if there is none
		_variableValue = [[Variable alloc] init];
		[_variableValue setProcess:_process];
	}
	return _variableValue;
}

- (void)setSearchValue:(Variable *)value
{
	[value retain];
	[_variableValue release];
	_variableValue = value;
}


- (unsigned)numberOfResults
{
	if ( _addresses ) {
		return TCArrayElementCount( _addresses );
	}
	return 0;
}

- (TCArray)addresses
{
	return _addresses;
}

- (void)setAddresses:(TCArray)addresses
{
	TCReleaseArray( _addresses );
	_addresses = addresses;
	
	if ( !_addresses ) {
		// clear the undoes and redoes if the search is cleared
		_undoes = -1;
		_redoes = 0;
	}
	
	// clear the stored values
	[self setValues:NULL];
}

- (TCArray)values
{
	return _values;
}

- (void)setValues:(TCArray)values
{
	TCReleaseArray( _values );
	_values = values;
}

- (void)setValue:(Variable *)value atIndex:(unsigned)index
{
	if ( _values ) {
		if ( index < TCArrayElementCount( _values ) ) {
			TCArraySetElementAtIndex( _values, index, [value value] );
		}
	}
	
}

- (BOOL)valuesLoaded
{
	return ( _values != NULL );
}

- (Variable *)variableAtIndex:(unsigned)index
{
	if ( [self hasSearchedOnce] ) {
		Variable *var = [[Variable alloc] initWithType:[self variableType] integerSign:[self integerSign]];
		[var setAddress:*(TCAddress *)TCArrayElementAtIndex( [self addresses], index )];
		if ( [self valuesLoaded] ) {
			[var setValue:TCArrayElementAtIndex( [self values], index ) size:TCArrayElementSize([self values])];
		}
		return [var autorelease];
	}
	return nil;
}

- (NSString *)stringForRow:(unsigned)rowIndex
{
	Variable *var = [self variableAtIndex:rowIndex];
	
	if ( var ) {
		if ( [self valuesLoaded] ) {
			if ( [var type] == TCString ) {
				return [NSString stringWithFormat:@"%@ = \"%@\"", [var addressString], [var stringValue]];
			}
			else {
				return [NSString stringWithFormat:@"%@ = %@", [var addressString], [var stringValue]];
			}
		}
		else {
			return [var addressString];
		}
	}
	return @"";
}


- (BOOL)hasSearchedOnce
{
	return ( _addresses != NULL );
}


- (int)undoesLeft
{
	return _undoes;
}

- (int)redoesLeft
{
	return _redoes;
}

- (void)didAddResults
{
	_undoes++;
	_redoes = 0;
}

- (void)didUndo
{
	_undoes--;
	_redoes++;
}

- (void)didRedo
{
	_undoes++;
	_redoes--;
}


- (BOOL)isTypeInteger
{
	return _variableType <= TCInt8;
}


- (void)clearResults
{
	[self setAddresses:NULL];
}


@end
