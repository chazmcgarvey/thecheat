
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

#import "GeneralPrefs.h"


@implementation GeneralPrefs


- (void)awakeFromNib
{
	// set initial states
	[ibWindowOrderButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:TCWindowsOnTopPref]];
	[ibAskForSaveButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:TCAskForSavePref]];
	if ( [[NSUserDefaults standardUserDefaults] floatForKey:TCFadeAnimationPref] > 0.0 ) {
		[ibFadeSmoothlyButton setState:NSOnState];
	}
	else {
		[ibFadeSmoothlyButton setState:NSOffState];
	}
	[ibDisplayValuesButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:TCDisplayValuesPref]];
	[ibValueUpdateField setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:TCValueUpdatePref]];
	[ibValueUpdateField setEnabled:[ibDisplayValuesButton state]];
	[ibResultsDisplayedField setIntValue:[[NSUserDefaults standardUserDefaults] integerForKey:TCHitsDisplayedPref]];
	
	[ibSwitchVariablesButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:TCSwitchVariablesPref]];
	[ibStartEditingVarsButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:TCAutoStartEditingVarsPref]];
	[ibStartEditingVarsButton setEnabled:[ibSwitchVariablesButton state]];
}


- (IBAction)ibWindowOrderButton:(id)sender
{
	BOOL pref = [sender state];
	[[NSUserDefaults standardUserDefaults] setBool:pref forKey:TCWindowsOnTopPref];
	// notify currently opened windows of the change
	[[NSNotificationCenter defaultCenter] postNotificationName:TCWindowsOnTopChangedNote object:[NSNumber numberWithBool:pref]];
}

- (IBAction)ibSetAskForSave:(id)sender
{
	BOOL pref = [sender state];
	[[NSUserDefaults standardUserDefaults] setBool:pref forKey:TCAskForSavePref];
}

- (IBAction)ibSetFadeSmoothly:(id)sender
{
	float fade;
	
	if ( [sender state] == NSOnState ) {
		fade = TCDefaultFadeAnimation;
	}
	else {
		fade = 0.0;
	}
	[[NSUserDefaults standardUserDefaults] setFloat:fade forKey:TCFadeAnimationPref];
	gFadeAnimationDuration = fade;
}

- (IBAction)ibDisplayValuesButton:(id)sender
{
	BOOL flag = [ibDisplayValuesButton state];
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:TCDisplayValuesPref];
	
	[ibValueUpdateField setEnabled:flag];
	
	// notify currently opened windows of the change
	[[NSNotificationCenter defaultCenter] postNotificationName:TCDisplayValuesChangedNote object:nil];
}

- (IBAction)ibSetValueUpdate:(id)sender
{
	float value = [sender floatValue];
	
	if ( value < 0.1 ) {
		value = 0.1;
		[sender setFloatValue:value];
	}
	
	[[NSUserDefaults standardUserDefaults] setFloat:value forKey:TCValueUpdatePref];
	
	// notify currently opened windows of the change
	[[NSNotificationCenter defaultCenter] postNotificationName:TCDisplayValuesChangedNote object:nil];
}

- (IBAction)ibSetResultsDisplayed:(id)sender
{
	int value = [ibResultsDisplayedField intValue];
	
	if ( value < 0 ) {
		value = 0;
		[ibResultsDisplayedField setIntValue:value];
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:TCHitsDisplayedPref];
	
	// notify currently opened windows of the change
	[[NSNotificationCenter defaultCenter] postNotificationName:TCHitsDisplayedChangedNote object:nil];
}


- (IBAction)ibSwitchVariablesButton:(id)sender
{
	BOOL flag = [ibSwitchVariablesButton state];
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:TCSwitchVariablesPref];
	
	[ibStartEditingVarsButton setEnabled:[ibSwitchVariablesButton state]];
	if ( !flag ) {
		[ibStartEditingVarsButton setState:NO];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:TCAutoStartEditingVarsPref];
	}
}

- (IBAction)ibStartEditingVarsButton:(id)sender
{
	BOOL flag = [ibStartEditingVarsButton state];
	[[NSUserDefaults standardUserDefaults] setBool:flag forKey:TCAutoStartEditingVarsPref];
}


@end
