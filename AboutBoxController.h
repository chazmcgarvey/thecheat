
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      AboutBoxController.h
// Created:   Mon Nov 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Foundation/Foundation.h>


@interface AboutBoxController : NSWindowController
{
	IBOutlet NSWindow		*aboutWindow;
	IBOutlet NSTextField	*nameVersionText;
}

- (IBAction)launchWebsiteButton:(id)sender;
- (IBAction)launchEmailButton:(id)sender;

@end
