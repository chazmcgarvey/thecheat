
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