
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      CheatClient.h
// Created:   Mon Sep 22 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>
#import <Chaz/Chaz.h>

#include "cheat_types.h"
#include "cheat_globals.h"
#include "cheat_net.h"


@interface CheatClient : NSObject
{
	id					rootProxy;
	int					sockfd;
}

+ (NSConnection *)clientWithDelegate:(id)delegate server:(NSData *)server name:(NSString *)name;
+ (void)clientThread:(NSArray *)array;

- (id)initWithRootProxy:(id)proxy;

- (void)connectToServer:(NSData *)data name:(NSString *)name;
- (void)run;

@end