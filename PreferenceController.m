
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      PreferenceController.m
// Created:   Wed Sep 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "PreferenceController.h"


@implementation PreferenceController


- (id)initWithDelegate:(id)del
{
	if ( self = [super initWithWindowNibName:@"Preferences"] )
	{
		[self setWindowFrameAutosaveName:@"TCPreferencWindowPosition"];
		
		delegate = del;
	}

	return self;
}

- (void)windowDidLoad
{
	[self initialInterfaceSetup];
}


- (void)initialInterfaceSetup
{
	[playSoundsButton setState:(TCGlobalPlaySounds)? NSOnState:NSOffState];
	[windowsOnTopButton setState:(TCGlobalWindowsOnTop)? NSOnState:NSOffState];
	[updateAutomaticallyButton setState:(TCGlobalUpdateCheck)? NSOnState:NSOffState];
	[allowRemoteButton setState:(TCGlobalAllowRemote)? NSOnState:NSOffState];
	[listenPortTextField setIntValue:TCGlobalListenPort];
	[broadcastNameTextField setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:TCBroadcastNamePref]];
	[hitsDisplayedTextField setIntValue:TCGlobalHitsDisplayed];
	
	[self interfaceUpdate];
}

- (void)interfaceUpdate
{
	if ( [allowRemoteButton state] )
	{
		[listenPortTextField setEnabled:YES];
		[broadcastNameTextField setEnabled:YES];
	}
	else
	{
		[listenPortTextField setEnabled:NO];
		[broadcastNameTextField setEnabled:NO];
	}
}


- (IBAction)change:(id)sender
{
	[self interfaceUpdate];
}


- (IBAction)revert:(id)sender
{
	[self initialInterfaceSetup];
}

- (IBAction)apply:(id)sender
{
	TCGlobalPlaySounds = [playSoundsButton state];
	[[NSUserDefaults standardUserDefaults] setBool:TCGlobalPlaySounds forKey:TCPlaySoundsPref];
	
	// send window information to the delegate so the necessary adjustments can be made
	[delegate preferenceSetWindowsOnTop:[windowsOnTopButton state]];
	
	TCGlobalWindowsOnTop = [windowsOnTopButton state];
	[[NSUserDefaults standardUserDefaults] setBool:TCGlobalWindowsOnTop forKey:TCWindowsOnTopPref];
	
	TCGlobalUpdateCheck = [updateAutomaticallyButton state];
	[[NSUserDefaults standardUserDefaults] setBool:TCGlobalUpdateCheck forKey:TCUpdateCheckPref];
	
	// send server information to the delegate so the server can be updated accordingly
	[delegate preferenceSetAllowRemote:[allowRemoteButton state] listenPort:[listenPortTextField intValue] broadcastName:[broadcastNameTextField stringValue]];
	
	TCGlobalAllowRemote = [allowRemoteButton state];
	[[NSUserDefaults standardUserDefaults] setBool:TCGlobalAllowRemote forKey:TCAllowRemotePref];
	
	TCGlobalListenPort = [listenPortTextField intValue];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:TCGlobalListenPort] forKey:TCListenPortPref];
	
	[[NSUserDefaults standardUserDefaults] setObject:[broadcastNameTextField stringValue] forKey:TCBroadcastNamePref];
	
	TCGlobalHitsDisplayed = [hitsDisplayedTextField intValue];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:TCGlobalHitsDisplayed] forKey:TCHitsDisplayedPref];
}


- (IBAction)cancel:(id)sender
{
	[self initialInterfaceSetup];
	[self close];
}

- (IBAction)save:(id)sender
{
	[self apply:self];
	[self close];
}


@end