
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      CheatListener.m
// Created:   Wed Sep 24 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "CheatListener.h"

#import "CheatServer.h"

#include <string.h>


@implementation CheatListener


+ (NSConnection *)listenerWithDelegate:(id)del port:(int)port remote:(BOOL)remote
{
	NSPort				*rPort = [NSPort port], *sPort = [NSPort port];
	NSConnection		*connection;
	NSArray				*array;

	connection = [[NSConnection alloc] initWithReceivePort:rPort sendPort:sPort];
	[connection setRootObject:del];

	array = [NSArray arrayWithObjects:sPort, rPort, [NSNumber numberWithInt:port], [NSNumber numberWithBool:remote], nil];
	[NSThread detachNewThreadSelector:@selector(listenerThread:) toTarget:self withObject:array];

	return [connection autorelease];
}

+ (void)listenerThread:(NSArray *)array
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    NSConnection		*connection = [NSConnection connectionWithReceivePort:[array objectAtIndex:0] sendPort:[array objectAtIndex:1]];
    CheatListener		*object = [[self alloc] initWithRootProxy:[connection rootProxy]];

	[object listenOnPort:[[array objectAtIndex:2] intValue] remote:[[array objectAtIndex:3] boolValue]];
	[object run];
	[object cleanup];

    [object release];
    [pool release];
}


- (id)initWithRootProxy:(id)proxy
{
	if ( self = [super init] )
	{
		rootProxy = proxy;
		sockfd = -1;
	}

	return self;
}


- (void)listenOnPort:(int)port remote:(BOOL)remote
{
	short					family = remote? AF_INET : AF_UNIX;
	
	int						yes = 1;	// for setsockopt()

	if ( (sockfd = socket( family, SOCK_STREAM, 0 )) == -1 )
	{
		CMLog( @"ERROR: failed to start server because socket() failed" );
		[rootProxy listenerError:@"Network Error" message:@"Server couldn't start.  Local can't be cheated."];
		return;
	}

	if ( family == AF_INET )
	{
		struct sockaddr_in		addr;

		addr.sin_family = family;
		addr.sin_port = htonl( port );
		addr.sin_addr.s_addr = INADDR_ANY;

		if ( setsockopt( sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int) ) == -1 )
		{
			CMLog( @"ERROR: failed to start server because setsockopt() failed" );
			[rootProxy listenerError:@"Network Error" message:@"Server couldn't start.  Local can't be cheated."];
			return;
		}

		if ( bind( sockfd, (struct sockaddr *)(&addr), sizeof(struct sockaddr) ) == -1 )
		{
			CMLog( @"ERROR: failed to start server because bind() failed" );
			[rootProxy listenerError:@"Network Error" message:@"The cheat server could not start, probably because the port is already in use.  Local can not be cheated."];
			return;
		}
	}
	else
	{
		struct sockaddr_un		addr;

		addr.sun_family = family;
		strncpy( addr.sun_path, TCDefaultListenPath, 103 );

		remove( TCDefaultListenPath );

		if ( bind( sockfd, (struct sockaddr *)(&addr), sizeof(addr) ) == -1 )
		{
			CMLog( @"ERROR: failed to start server because bind() failed" );
			[rootProxy listenerError:@"Network Error" message:@"The cheat server could not start, probably because the path is already in use.  Local can not be cheated."];
			return;
		}
	}

	if ( listen( sockfd, 50 ) == -1 )
	{
		CMLog( @"ERROR: failed to start server because listen() failed" );
		[rootProxy listenerError:@"Network Error" message:@"Server couldn't start.  Local can't be cheated."];
		return;
	}

	listenRemote = remote;

	[rootProxy listenerListeningWithSocket:sockfd];
}

- (void)run
{
	int						result;

	CMLog( @"LISTENER start" );

	if ( listenRemote )
	{
		struct sockaddr_in		addr;
		int						addrLen;
		
		for (;;)
		{
			addrLen = sizeof(addr);
			
			if ( (result = accept( sockfd, (struct sockaddr *)(&addr), &addrLen )) == -1 )
			{
				break;
			}

			[rootProxy listenerReceivedNewConnection:result];
		}
	}
	else
	{
		struct sockaddr_un		addr;
		int						addrLen;

		for (;;)
		{
			addrLen = sizeof(addr);
			
			if ( (result = accept( sockfd, (struct sockaddr *)(&addr), &addrLen )) == -1 )
			{
				break;
			}

			[rootProxy listenerReceivedNewConnection:result];
		}
	}

	CMLog( @"LISTENER close" );

	[rootProxy listenerDisconnected];
}

- (void)cleanup
{
	if ( listenRemote )
	{
		remove( TCDefaultListenPath );
	}
}


@end