//
//  UpdatePrefs.m
//  The Cheat
//
//  Created by Chaz McGarvey on 2/21/05.
//  Copyright 2005 Chaz McGarvey. All rights reserved.
//

#import "UpdatePrefs.h"


@implementation UpdatePrefs


- (void)awakeFromNib
{
	// set initial states
	[ibAutoCheckButton setState:[[NSUserDefaults standardUserDefaults] boolForKey:TCUpdateCheckPref]];
}

- (IBAction)ibAutoCheckButton:(id)sender
{
	BOOL pref = [sender state];
	[[NSUserDefaults standardUserDefaults] setBool:pref forKey:TCUpdateCheckPref];
}

- (IBAction)ibCheckNowButton:(id)sender
{
	ChazCheckForUpdate( TCUpdateCheckURL, YES );
}


@end
