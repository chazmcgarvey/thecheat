
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      cheat_shared.m
// Created:   Mon Nov 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "cheat_shared.h"


void LaunchWebsite()
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.brokenzipper.com/"]];
}

void LaunchEmail()
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:chaz@brokenzipper.com?subject=The%20Cheat%20Feedback"]];
}