
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      CheatListener.h
// Created:   Wed Sep 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>
#import <Chaz/Chaz.h>

#import "ListenerDelegate.h"

#include "cheat_globals.h"
#include "cheat_net.h"

#include "stdio.h"

@class CheatServer;


@interface CheatListener : NSObject
{
	id				rootProxy;
	int				sockfd;

	BOOL			listenRemote;
}

+ (NSConnection *)listenerWithDelegate:(id)del port:(int)port remote:(BOOL)remote;
+ (void)listenerThread:(NSArray *)array;

- (id)initWithRootProxy:(id)proxy;

- (void)listenOnPort:(int)port remote:(BOOL)remote;
- (void)run;
- (void)cleanup;

@end