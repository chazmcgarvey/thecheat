
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      ServerHolder.m
// Created:   Sun Sep 28 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "ServerHolder.h"

#import "CheatServer.h"


@implementation ServerHolder


+ (ServerHolder *)holderWithConnection:(NSConnection *)conn socket:(int)sock
{
	return [[[ServerHolder alloc] initWithConnection:conn socket:sock] autorelease];
}

- (id)initWithConnection:(NSConnection *)conn socket:(int)sock
{
	if ( self = [super init] )
	{
		connection = [conn retain];
		sockfd = sock;
	}

	return self;
}


- (NSConnection *)connection
{
	return connection;
}

- (void)setConnection:(NSConnection *)conn
{
	[connection release];
	connection = [conn retain];
}

- (CheatServer *)server
{
	return server;
}

- (void)setServer:(CheatServer *)serv
{
	[server release];
	server = [serv retain];
}


- (int)sockfd
{
	return sockfd;
}

- (void)setSockFD:(int)sock
{
	sockfd = sock;
}


- (NSString *)address
{
	return address;
}

- (void)setAddress:(NSString *)addr
{
	[address release];
	address = [addr retain];
}

- (NSString *)action
{
	return action;
}

- (void)setAction:(NSString *)act
{
	[action release];
	action = [act retain];
}


- (void)dealloc
{
	[connection release];
	[server release];

	[super dealloc];
}


@end