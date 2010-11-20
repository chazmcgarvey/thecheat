
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


@interface PreferenceController : NSWindowController
{
	NSToolbar		*_toolbar;
	
	NSView			*_contentView;
	IBOutlet NSView *ibGeneralView;
	IBOutlet NSView *ibServerView;
	IBOutlet NSView *ibUpdateCheckView;
}

- (void)chooseGeneral:(id)object;
- (void)chooseServer:(id)object;
- (void)chooseUpdate:(id)object;
- (void)switchToView:(NSView *)view;

- (void)initialInterfaceSetup;

@end
