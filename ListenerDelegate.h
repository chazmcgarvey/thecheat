
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      ListenerDelegate.h
// Created:   Wed Sep 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>


@protocol ListenerDelegate

- (void)listenerListeningWithSocket:(int)sock;
- (void)listenerDisconnected;
- (void)listenerError:(NSString *)error message:(NSString *)message;

- (void)listenerReceivedNewConnection:(int)sock;

@end