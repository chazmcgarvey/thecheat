
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      PreferenceController.h
// Created:   Wed Sep 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>

#import "PreferenceControlling.h"

#include "cheat_globals.h"


@interface PreferenceController : NSWindowController
{
	id				delegate;
	
	IBOutlet id		prefsWindow;
	IBOutlet id		playSoundsButton;
	IBOutlet id		windowsOnTopButton;
	IBOutlet id		allowRemoteButton;
	IBOutlet id		broadcastNameTextField;
	IBOutlet id		listenPortTextField;
}

- (id)initWithDelegate:(id)del;

- (void)initialInterfaceSetup;
- (void)interfaceUpdate;

- (IBAction)playSoundsButton:(id)sender;
- (IBAction)windowsOnTopButton:(id)sender;
- (IBAction)allowRemoteButton:(id)sender;
- (IBAction)listenPortTextField:(id)sender;
- (IBAction)broadcastNameTextField:(id)sender;

@end