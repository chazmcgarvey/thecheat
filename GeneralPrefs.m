
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

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
