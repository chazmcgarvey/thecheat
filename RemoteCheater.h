
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import <Cocoa/Cocoa.h>
#import "ChazUpdate.h"

#import "Cheater.h"

#import "MySocket.h"


@interface RemoteCheater : Cheater
{
	MySocket *_socket;
	
	/* the current packet being read. */
	TCPacketHeader _header;
	NSData *_parameters;
}

- (BOOL)connectToHostWithData:(NSData *)data;
// disconnects automatically upon dealloc

@end
