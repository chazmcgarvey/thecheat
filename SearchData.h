
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

#import "CheaterTypes.h"

#import "Cheater.h"
#import "Variable.h"

#import "Process.h"

@interface SearchData : NSObject
{
	TCVariableType _variableType;
	TCIntegerSign _integerSign;
	TCSearchOperator _operator;
	TCSearchType _value;
	
	Variable *_variableValue;
	
	TCArray _addresses;
	TCArray _values;
	
	Process *_process;
	
	int _undoes;
	int _redoes;
}

// ACCESSORS
- (void)setProcess:(Process *)process;

- (TCVariableType)variableType;
- (void)setVariableType:(TCVariableType)varType;

- (TCIntegerSign)integerSign;
- (void)setIntegerSign:(TCIntegerSign)sign;

- (TCSearchOperator)searchOperator;
- (void)setSearchOperator:(TCSearchOperator)op;

- (TCSearchType)valueUsed;
- (void)setValueUsed:(TCSearchType)value;

- (Variable *)searchValue;
- (void)setSearchValue:(Variable *)value;

- (unsigned)numberOfResults;
- (TCArray)addresses;
- (void)setAddresses:(TCArray)addresses;
- (TCArray)values;
- (void)setValues:(TCArray)values;
- (void)setValue:(Variable *)value atIndex:(unsigned)index;
- (BOOL)valuesLoaded;
- (Variable *)variableAtIndex:(unsigned)index;
- (NSString *)stringForRow:(unsigned)rowIndex;

- (BOOL)hasSearchedOnce;

- (int)undoesLeft;
- (int)redoesLeft;
- (void)didAddResults;
- (void)didUndo;
- (void)didRedo;

// this is convenient
- (BOOL)isTypeInteger;

// ACTIONS
- (void)clearResults;


@end
