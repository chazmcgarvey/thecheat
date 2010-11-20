
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

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
