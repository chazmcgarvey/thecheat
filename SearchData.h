
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
