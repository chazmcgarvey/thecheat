//
//  SearchData.h
//  The Cheat
//
//  Created by Chaz McGarvey on 12/13/04.
//  Copyright 2004 Chaz McGarvey. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CheaterTypes.h"

#import "Cheater.h"
#import "Variable.h"


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
