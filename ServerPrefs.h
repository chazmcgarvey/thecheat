
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
