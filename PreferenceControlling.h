
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      PreferenceControlling.h
// Created:   Wed Sep 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>


@protocol PreferenceControlling

- (void)preferenceSetWindowsOnTop:(BOOL)windowsOnTop;
- (void)preferenceSetAllowRemote:(BOOL)allow listenPort:(int)port broadcastName:(NSString *)name;

/*
- (void)preferenceAllowRemoteChanged:(BOOL)allow;
- (void)preferenceListenPortChanged:(int)port;
- (void)preferenceBroadcastNameChanged:(NSString *)name;
*/

@end