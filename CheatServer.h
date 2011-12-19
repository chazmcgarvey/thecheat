
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
#import "ChazLog.h"

#import "MySocket.h"

#import "ServerChild.h"


@interface CheatServer : NSObject
{
	MySocket *_socket; // the socket that listens for connections
	NSNetService *_netService; // for rendezvous broadcasting
	
	int _port; // port the socket is listening on
	NSString *_name; // name the service is being broadcast as
	
	NSMutableArray *_children; // the server spawns
	
	id _delegate;
}

// initialization
- (id)initWithDelegate:(id)delegate;

// starting and stopping the server
// it will automatically be stopped on dealloc.
// pass nil for name to not broadcast.
- (BOOL)listenOnPort:(int)port broadcast:(NSString *)name;
- (void)stop;

// accessing children
// children are spawned by the server to handle remote sessions.
// they are instances of the ServerChild class.
- (int)childCount;
- (NSArray *)children;
- (void)removeChildAtIndex:(unsigned)index;

// accessors
- (BOOL)isListening;
- (NSString *)host;
- (int)port;
- (NSString *)broadcast;

- (id)delegate;
- (void)setDelegate:(id)delegate;

@end


@interface NSObject ( CheatServerDelegate )

// when the server dies while running...  would this ever happen?  I doubt it.
- (void)serverDisconnectedUnexpectedly:(CheatServer *)theServer;

// broadcast failed, this is much more likely to happen.
// note that the server will continue running.
- (void)server:(CheatServer *)theServer failedToBroadcastName:(NSString *)theName;

// a connection was made or lost with the server...
- (void)serverChildrenChanged:(CheatServer *)theServer;

@end
