
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


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
