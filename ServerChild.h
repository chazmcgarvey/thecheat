
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import <Cocoa/Cocoa.h>
#import "ChazLog.h"

#import "MySocket.h"

#import "LocalCheater.h"
#import "Cheater.h"

#include <string.h>


@interface ServerChild : NSObject < CheaterDelegate >
{
	MySocket *_socket;
	NSString *_client;
	
	LocalCheater *_cheater;
	
	/* the current packet being read. */
	TCPacketHeader _header;
	NSData *_parameters;
	
	id _delegate;
}

- (id)initWithSocket:(MySocket *)sock;
- (id)initWithSocket:(MySocket *)sock delegate:(id)delegate;

- (NSString *)host;
- (NSString *)transfer;

- (id)delegate;
- (void)setDelegate:(id)delegate;

@end


@interface NSObject ( ServerChildDelegate )

// informs the cheat server of connection status
- (void)serverChildConnected:(ServerChild *)theChild;
- (void)serverChildDisconnected:(ServerChild *)theChild;

// inform the cheat server something about the child changed.
- (void)serverChildChanged:(ServerChild *)theChild;

@end
