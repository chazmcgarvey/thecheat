
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
#import "ChazLog.h"

#import "ChazUpdate.h"

#include "cheat_global.h"


@interface AboutBoxController : NSWindowController
{
	IBOutlet NSTextField *ibNameVersionText;
	IBOutlet NSButton *ibWebsiteButton;
	IBOutlet NSButton *ibEmailButton;
	IBOutlet NSTextField *ibDateText;
}

- (IBAction)ibWebsiteButton:(id)sender;
- (IBAction)ibEmailButton:(id)sender;

@end
