
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

#include "cheat_global.h"

#import "StatusTextField.h"


@interface ServerPrefs : NSObject
{
	IBOutlet StatusTextField *ibStatusField;
	IBOutlet NSTextField *ibNameField;
	IBOutlet NSTextField *ibPortField;
	IBOutlet NSButton *ibStartButton;
	IBOutlet NSTableView *ibSessionTable;
	IBOutlet NSTextField *ibDefaultPortText;
	
	NSTimer *_tableTimer;
}

- (IBAction)ibSetListenPort:(id)sender;
- (IBAction)ibSetBroadcast:(id)sender;

- (IBAction)ibStartServer:(id)sender;

@end
