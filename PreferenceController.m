
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

/*
- (IBAction)playSoundsButton:(id)sender
{
	if ( [playSoundsButton state] == NSOnState )
	{
		TCGlobalPlaySounds = YES;
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:TCPlaySoundsPref];
	}
	else
	{
		TCGlobalPlaySounds = NO;
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:TCPlaySoundsPref];
	}
}

- (IBAction)windowsOnTopButton:(id)sender
{
	if ( [windowsOnTopButton state] == NSOnState )
	{
		TCGlobalWindowsOnTop = YES;
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:TCWindowsOnTopPref];
	}
	else
	{
		TCGlobalWindowsOnTop = NO;
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:TCWindowsOnTopPref];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"TCWindowsOnTopChanged" object:nil];
}

- (IBAction)updateAutomaticallyButton:(id)sender
{
	if ( [updateAutomaticallyButton state] == NSOnState )
	{
		TCGlobalUpdateCheck = YES;
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:TCUpdateCheckPref];
	}
	else
	{
		TCGlobalUpdateCheck = NO;
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:TCUpdateCheckPref];
	}
}

- (IBAction)allowRemoteButton:(id)sender
{
	if ( [allowRemoteButton state] == NSOnState )
	{
		TCGlobalAllowRemote = YES;
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:TCAllowRemotePref];
	}
	else
	{
		TCGlobalAllowRemote = NO;
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:TCAllowRemotePref];
	}

	[self interfaceUpdate];

	[delegate preferenceAllowRemoteChanged:TCGlobalAllowRemote];
}

- (IBAction)listenPortTextField:(id)sender
{
	TCGlobalListenPort = [listenPortTextField intValue];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:TCGlobalListenPort] forKey:TCListenPortPref];

	[delegate preferenceListenPortChanged:TCGlobalListenPort];
}

- (IBAction)broadcastNameTextField:(id)sender
{
	NSString			*name = [broadcastNameTextField stringValue];
	
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:TCBroadcastNamePref];

	[delegate preferenceBroadcastNameChanged:name];
}

- (IBAction)hitsDisplayedTextField:(id)sender
{
	TCGlobalHitsDisplayed = [hitsDisplayedTextField intValue];
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:TCGlobalHitsDisplayed] forKey:TCHitsDisplayedPref];
}
*/


- (IBAction)change:(id)sender
{
	[self interfaceUpdate];
}


- (IBAction)revert:(id)sender
{
	[self initialInterfaceSetup];
}

- (IBAction)cancel:(id)sender
{
	[self initialInterfaceSetup];
	[self close];
}

- (IBAction)save:(id)sender
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
	
	[self close];
}


@end