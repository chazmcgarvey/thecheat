
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
	IBOutlet id		updateAutomaticallyButton;
	IBOutlet id		allowRemoteButton;
	IBOutlet id		broadcastNameTextField;
	IBOutlet id		listenPortTextField;
	IBOutlet id		hitsDisplayedTextField;
}

- (id)initWithDelegate:(id)del;

- (void)initialInterfaceSetup;
- (void)interfaceUpdate;

- (IBAction)change:(id)sender;

- (IBAction)revert:(id)sender;
- (IBAction)apply:(id)sender;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end