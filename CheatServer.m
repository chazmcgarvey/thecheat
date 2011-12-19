
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import "CheatServer.h"


@interface CheatServer ( PrivateAPI )

// delegate methods
- (void)_performDelegateSelector:(SEL)selector;
- (void)_performDelegateSelector:(SEL)selector withObject:(id)object;

@end


@implementation CheatServer


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Initialization
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (id)initWithDelegate:(id)delegate
{
	if ( self = [super init] ) {
		_delegate = delegate;
	}
	return self;
}

- (void)dealloc
{
	[self stop];
	[super dealloc];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Starting/Stopping
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (BOOL)listenOnPort:(int)port broadcast:(NSString *)name
{
	if ( [self isListening] ) {
		// already running
		return NO;
	}
	
	// start the server
	_socket = [[MySocket alloc] initWithDelegate:self];
	if ( ![_socket listenOnPort:port] ) {
		[_socket release];
		_socket = nil;
		return NO;
	}
	
	_children = [[NSMutableArray alloc] init];
	
	_port = port;
	_name = [name retain];
	
	// start the rendezvous broadcast
	if ( _name ) { // domain: @"local."
		_netService = [[NSNetService alloc] initWithDomain:@"" type:@"_cheat._tcp." name:_name port:port];
		[_netService setDelegate:self];
		[_netService publish];
	}
	
	return YES;
}

- (void)stop
{
	// close the listener
	[_socket disconnect];
	[_socket release];
	_socket = nil;
	
	// if broadcasting, stop
	[_netService stop];
	_netService = nil;
	
	[_children release];
	_children = nil;
	
	_port = 0;
	[_name release];
	_name = nil;
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Accessing Children
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (int)childCount
{
	return [_children count];
}

- (NSArray *)children
{
	return [NSArray arrayWithArray:_children];
}

- (void)removeChildAtIndex:(unsigned)index
{
	[_children removeObjectAtIndex:index];
}


- (void)serverChildConnected:(ServerChild *)theChild
{
	if ( [self isListening] ) {
		//[_children addObject:theChild];
		[self _performDelegateSelector:@selector(serverChildrenChanged:)];
	}
}

- (void)serverChildDisconnected:(ServerChild *)theChild
{
	if ( [self isListening] ) {
		[_children removeObject:theChild];
		[self _performDelegateSelector:@selector(serverChildrenChanged:)];
	}
}

- (void)serverChildChanged:(ServerChild *)theChild
{
	[self _performDelegateSelector:@selector(serverChildrenChanged:)];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark MySocketDelegate
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)socket:(MySocket *)mySocket didAcceptSocket:(MySocket *)newSocket
{
	ChazLog( @"CheatServer - MySocket accepted another one!!" );
	
	ServerChild *child;
	
	// create a new child
	child = [[ServerChild alloc] initWithSocket:newSocket delegate:self];
	[_children addObject:child];
	[child release];
}

- (void)socketDidDisconnect:(MySocket *)mySocket
{
	ChazLog( @"CheatServer - MySocket disconnected: %p", mySocket );
	[self _performDelegateSelector:@selector(serverDisconnectedUnexpectedly:)];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark NetService Delegate
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)netServiceWillPublish:(NSNetService *)sender
{
	ChazLog( @"service will publish" );
	//[sender resolve];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	ChazLog( @"service did not publish" );
	// just inform the delegate and let it decide what to do 
	[self _performDelegateSelector:@selector(server:failedToBroadcastName:) withObject:[sender name]];
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	ChazLog( @"service stopped" );
	[sender release];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Delegate Methods
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)_performDelegateSelector:(SEL)selector
{
	if ( [_delegate respondsToSelector:selector] ) {
		[_delegate performSelector:selector withObject:self];
	}
}

- (void)_performDelegateSelector:(SEL)selector withObject:(id)object
{
	if ( [_delegate respondsToSelector:selector] ) {
		[_delegate performSelector:selector withObject:self withObject:object];
	}
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Accessors
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (BOOL)isListening
{
	return _socket != nil;
}

- (NSString *)host
{
	return [_socket localHost];
}

- (int)port
{
	return _port;
}

- (NSString *)broadcast
{
	return _name;
}

- (id)delegate
{
	return _delegate;
}

- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}


@end
