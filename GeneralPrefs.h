
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
#include "cheat_global.h"


@interface GeneralPrefs : NSObject
{
	IBOutlet NSButton *ibWindowOrderButton;
	IBOutlet NSButton *ibAskForSaveButton;
	IBOutlet NSButton *ibFadeSmoothlyButton;
	IBOutlet NSButton *ibDisplayValuesButton;
	IBOutlet NSTextField *ibValueUpdateField;
	IBOutlet NSTextField *ibResultsDisplayedField;
	IBOutlet NSButton *ibSwitchVariablesButton;
	IBOutlet NSButton *ibStartEditingVarsButton;
}

- (IBAction)ibWindowOrderButton:(id)sender;
- (IBAction)ibSetAskForSave:(id)sender;
- (IBAction)ibSetFadeSmoothly:(id)sender;
- (IBAction)ibDisplayValuesButton:(id)sender;
- (IBAction)ibSetValueUpdate:(id)sender;
- (IBAction)ibSetResultsDisplayed:(id)sender;
- (IBAction)ibSwitchVariablesButton:(id)sender;
- (IBAction)ibStartEditingVarsButton:(id)sender;

@end
