
// **********************************************************************
// The Cheat - A universal game cheater for Mac OS X
// (C) 2003-2005 Chaz McGarvey (BrokenZipper)
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 1, or (at your option)
// any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
// 

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
