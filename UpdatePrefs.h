//
//  UpdatePrefs.h
//  The Cheat
//
//  Created by Chaz McGarvey on 2/21/05.
//  Copyright 2005 Chaz McGarvey. All rights reserved.
//

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
