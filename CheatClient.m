
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      CheatClient.m
// Created:   Mon Sep 22 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "CheatClient.h"

#import "MyDocument.h"


@implementation CheatClient


+ (NSConnection *)clientWithDelegate:(id)delegate server:(NSData *)server name:(NSString *)name
{
	NSPort				*rPort = [NSPort port], *sPort = [NSPort port];
	NSConnection		*connection;
	NSArray				*array;

	connection = [[NSConnection alloc] initWithReceivePort:rPort sendPort:sPort];
	[connection setRootObject:delegate];

	array = [NSArray arrayWithObjects:sPort, rPort, server, name, nil];
	[NSThread detachNewThreadSelector:@selector(clientThread:) toTarget:self withObject:array];

	return [connection autorelease];
}

+ (void)clientThread:(NSArray *)array
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    NSConnection		*connection = [NSConnection connectionWithReceivePort:[array objectAtIndex:0] sendPort:[array objectAtIndex:1]];
    CheatClient			*object = [[self alloc] initWithRootProxy:[connection rootProxy]];

	[object connectToServer:[array objectAtIndex:2] name:[array objectAtIndex:3]];
	[object run];
    
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


- (void)connectToServer:(NSData *)data name:(NSString *)name
{
	struct sockaddr		identifier;

	[data getBytes:&identifier length:sizeof(identifier)];

	if ( (sockfd = socket( identifier.sa_family, SOCK_STREAM, 0 )) == -1 )
	{
		NSLog( @"ERROR: socket() failed" );
		[rootProxy clientError:@"Network Error" message:@"Attempt to connect to server failed."];
		return;
	}

	if ( identifier.sa_family == AF_INET )
	{
		struct sockaddr_in		addr;

		[data getBytes:&addr];

		if ( connect( sockfd, (struct sockaddr *)(&addr), sizeof(addr) ) == -1 )
		{
			close( sockfd );

			NSLog( @"ERROR: connect() failed" );
			[rootProxy clientError:@"Network Error" message:@"Attempt to connect to server failed."];
			return;
		}
	}
	else
	{
		struct sockaddr_un		addr;

		[data getBytes:&addr];
		
		if ( connect( sockfd, (struct sockaddr *)(&addr), sizeof(addr) ) == -1 )
		{
			close( sockfd );

			NSLog( @"ERROR: connect() failed" );
			[rootProxy clientError:@"Network Error" message:@"Attempt to connect to server failed."];
			return;
		}
	}

	[rootProxy clientConnectedWithSocket:sockfd name:name];
}

- (void)run
{
	int					result;

	PacketHeader		header;

	NSData				*data;
	char				*bytes = NULL;
	
	if ( sockfd == -1 )
	{
		NSLog( @"ERROR: can't run when not connected" );
		return;
	}

	NSLog( @"CLIENT start" );

	for (;;)
	{
		if ( (result = ReadBuffer( sockfd, (char *)(&header), sizeof(header) )) != sizeof(header) )
		{
			if ( result != 0 && result != -1 )
			{
				NSLog( @"ERROR: incomplete header received" );
				close( sockfd );
				break;
			}

			break;
		}

		if ( !VerifyChecksum( header.checksum ) )
		{
			NSLog( @"ERROR: checksum verification failed" );
			close( sockfd );
			break;
		}

		NSLog( @"CLIENT message %i/%i/%i", header.checksum, header.function, header.size );

		if ( header.size != 0 )
		{
			if ( (bytes = (char *)malloc( header.size )) == NULL )
			{
				NSLog( @"ERROR: failed to allocate buffer for reading a network packet" );
				close( sockfd );
				break;
			}

			if ( (result = ReadBuffer( sockfd, bytes, header.size )) != header.size )
			{
				NSLog( @"ERROR: failed to read the data of a network packet; only read %i bytes out of %i", result, header.size );
				free( bytes );
				close( sockfd );
				break;
			}
		}

		data = [NSData dataWithBytes:bytes length:header.size];

		switch ( header.function )
		{
			case 2:
				[rootProxy receivedProcessList:data];
				break;

			case 6:
				[rootProxy receivedSearchFinished];
				break;

			case 7:
				[rootProxy receivedVariableList:data];
				break;

			case 9:
				[rootProxy receivedChangeFinished];
				break;

			case 11:
				[rootProxy receivedError:data];
				break;
				
			case 15:
				[rootProxy receivedUndoFinished];
				break;
				
			case 17:
				[rootProxy receivedRedoFinished];
				break;
				
			case 19:
				[rootProxy receivedUndoRedoStatus:data];
				break;

			case 21:
				[rootProxy receivedAppLaunched:data];
				break;

			case 22:
				[rootProxy receivedAppQuit:data];
				break;

			case 23:
				[rootProxy receivedTargetQuit];
				break;

			case 24:
				[rootProxy receivedPauseFinished:data];
				break;
		}

		if ( header.size != 0 )
		{
			free( bytes );
		}
	}

	[rootProxy clientDisconnected];

	NSLog( @"CLIENT close" );
}


@end