
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      ServerHolder.h
// Created:   Sun Sep 28 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>


@class CheatServer;


@interface ServerHolder : NSObject
{
	NSConnection		*connection;
	CheatServer			*server;
	int					sockfd;

	NSString			*address;
	NSString			*action;
}

+ (ServerHolder *)holderWithConnection:(NSConnection *)conn socket:(int)sock;
- (id)initWithConnection:(NSConnection *)conn socket:(int)sock;

- (NSConnection *)connection;
- (void)setConnection:(NSConnection *)conn;
- (CheatServer *)server;
- (void)setServer:(CheatServer *)serv;
- (int)sockfd;
- (void)setSockFD:(int)sock;

- (NSString *)address;
- (void)setAddress:(NSString *)addr;
- (NSString *)action;
- (void)setAction:(NSString *)act;

@end