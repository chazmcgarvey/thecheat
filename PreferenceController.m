
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
	[self interfaceUpdate];
}


- (void)initialInterfaceSetup
{
	[playSoundsButton setState:(TCGlobalPlaySounds)? NSOnState:NSOffState];
	[windowsOnTopButton setState:(TCGlobalWindowsOnTop)? NSOnState:NSOffState];
	[allowRemoteButton setState:(TCGlobalAllowRemote)? NSOnState:NSOffState];
	[listenPortTextField setIntValue:TCGlobalListenPort];
	[broadcastNameTextField setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:TCBroadcastNamePref]];
}

- (void)interfaceUpdate
{
	if ( TCGlobalAllowRemote )
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


@end