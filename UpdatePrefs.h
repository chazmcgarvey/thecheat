
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
#import "cheat_global.h"

#import "ChazUpdate.h"


@interface UpdatePrefs : NSObject
{
	IBOutlet NSButton *ibAutoCheckButton;
}

- (IBAction)ibAutoCheckButton:(id)sender;
- (IBAction)ibCheckNowButton:(id)sender;

@end
