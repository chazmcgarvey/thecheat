
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      AboutBoxController.m
// Created:   Mon Nov 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "AboutBoxController.h"

#include "cheat_shared.h"


@implementation AboutBoxController


- (id)init
{
	return [super initWithWindowNibName:@"AboutBox"];
}

- (void)windowDidLoad
{
	[aboutWindow center];
}

- (IBAction)launchWebsiteButton:(id)sender
{
	LaunchWebsite();
}

- (IBAction)launchEmailButton:(id)sender
{
	LaunchEmail();
}


@end
