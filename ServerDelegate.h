
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      ServerDelegate.h
// Created:   Thu Sep 25 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>

#include <sys/types.h>

@class CheatServer;


@protocol ServerDelegate

- (void)server:(CheatServer *)server connectedWithSocket:(int)sock;
- (void)serverDisconnected:(CheatServer *)server;

- (void)server:(CheatServer *)server changedAddress:(NSString *)address;
- (void)server:(CheatServer *)server changedAction:(NSString *)action;

- (NSArray *)serverProcessList;
- (pid_t)serverFirstProcess;

@end