
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "MySocket.h"


// CONSTANTS

// this is used to read in unclaimed data
#define MYSOCKET_PACKETLEN (1024)

enum {
	kMySocketAddedToManager = 1,
	kMySocketConnected = 2,
	kMySocketIsListener = 4
};


struct _mySocketGlobals {
	BOOL isManagerRunning;
	NSMutableArray *sockets;
	NSRecursiveLock *readLock;
	NSRecursiveLock *writeLock;
	int readPipe[2];
	int writePipe[2];
	int maxreadfd;
	int maxwritefd;
	fd_set readfds;
	fd_set writefds;
} _mySocketGlobals = { NO, nil, nil, nil, { -1, -1 }, { -1, -1 }, 0, 0 };


// HELPER CLASSES

@interface _MySocketPacket : NSObject
{
	NSData *_buffer;
	unsigned _bytesHandled;
	unsigned _bytesRequired;
	int _tag;
}

- (id)initWithData:(NSData *)data tag:(int)tag;

- (void *)bytes; // pointer to the current bytes; changes are bytes are handled
- (unsigned)bytesRemaining;

- (void)handledBytes:(unsigned)count;

- (unsigned)bytesRequired;

- (NSData *)data;
- (int)tag;
- (BOOL)isComplete;

@end


// PRIVATE STUFF

@interface MySocket ( PrivateAPI )

- (id)_initWithFileDescriptor:(int)sockfd;
- (void)_connect;

- (void)_addToManager;
- (void)_removeFromManager;

+ (void)_readWithSockFD:(int)fd;
+ (void)_refreshReadThread;
+ (void)_writeWithSockFD:(int)fd;
+ (void)_refreshWriteThread;

+ (void)_lockRead;
+ (void)_unlockRead;
+ (void)_lockWrite;
+ (void)_unlockWrite;
+ (void)_lockReadAndWrite;
+ (void)_unlockReadAndWrite;

/* #### MANAGER METHODS #### */
+ (void)_startManager;
+ (void)_readThread:(id)object;
+ (void)_writeThread:(id)object;

- (int)_accept;
- (int)_read;
- (int)_write;

- (void)_fillReadPacketsWithUnclaimedBytes;

- (void)_handleReadQueue;
- (void)_handleWriteQueue;

- (void)_eventDidAcceptSocket:(MySocket *)newSocket;
- (void)_eventDidDisconnect:(id)dummy;
- (void)_eventDidReadData:(_MySocketPacket *)packet;
- (void)_eventDidWriteData:(_MySocketPacket *)packet;

// utility
- (NSMutableData *)_readBufferWithLength:(unsigned *)len;

// accessors
- (int)_sockfd;

@end



@implementation MySocket


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Initialization
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (id)initWithDelegate:(id)delegate
{
	if ( self = [super init] ) {
		ChazLog( @"SOCKET CREATED" );
		[self setDelegate:delegate];
	}
	return self;
}

- (void)dealloc
{
	ChazLog( @"SOCKET DESTROYED" );
	[self disconnect];
	[super dealloc];
}


- (void)release
{
	if ( [self retainCount] == 1 ) {
		[self _removeFromManager];
	}
	
	[super release];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Connecting/Disconnecting
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (BOOL)connectToHost:(NSString *)host port:(int)port
{
	return [self connectToAddressWithData:[MySocket addressWithHost:host port:port]];
}

- (BOOL)connectToAddress:(const struct sockaddr *)addr length:(unsigned)addrLen
{
	int err = 0;
	
	if ( [self isConnected] ) {
		return NO;
	}
	
	_sockfd = socket( addr->sa_family, SOCK_STREAM, 0 );
	if ( _sockfd == -1 ) {
		// can't get file descriptor
		return NO;
	}
	// make the socket NOT block
	/*err = fcntl( _sockfd, F_SETFL, O_NONBLOCK );
	if ( err == -1 ) {
		// can't not block
		close( _sockfd );
		return NO;
	}*/
	err = connect( _sockfd, addr, addrLen );
	if ( err == -1 ) {
		// can't connect
		close( _sockfd );
		return NO;
	}
	
	[self _connect];
	return YES;
}

- (BOOL)connectToAddressWithData:(NSData *)addr
{
	return [self connectToAddress:[addr bytes] length:[addr length]];
}

- (BOOL)listenOnPort:(int)port
{
	struct sockaddr_in addr;
	
	int err = 0;
	int yes = 1;
	
	if ( [self isConnected] ) {
		return NO;
	}
	
	_sockfd = socket( AF_INET, SOCK_STREAM, 0 );
	if ( _sockfd == -1 ) {
		// can't get file descriptor
		return NO;
	}
	err = setsockopt( _sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes) );
	if ( err == -1 ) {
		// can't reuse address
		close( _sockfd );
		return NO;
	}
	
	// pack the socket address structure
	addr.sin_family = AF_INET;
	addr.sin_port = htons( (short)port );
	addr.sin_addr.s_addr = INADDR_ANY;
	memset( &(addr.sin_zero), NULL, 8 );
	
	err = bind( _sockfd, (struct sockaddr *)(&addr), sizeof(addr) );
	if ( err == -1 ) {
		// can't bind to this address
		close( _sockfd );
		return NO;
	}
	
	err = listen( _sockfd, 10 );
	if ( err == -1 ) {
		// can't listen on this address
		close( _sockfd );
		return NO;
	}
	
	_flags |= kMySocketIsListener;
	[self _connect];
	return YES;
}


- (void)disconnect
{
	if ( !(_flags & kMySocketConnected) ) {
		// not connected
		return;
	}
	
	[self _removeFromManager];
	
	close( _sockfd );
	_sockfd = -1;
	
	[_readQueue release];
	_readQueue = nil;
	[_writeQueue release];
	_writeQueue = nil;
	[_readLock release];
	_readLock = nil;
	[_writeLock release];
	_writeLock = nil;
	
	_startTime = 0.0;
	
	_flags = 0;
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Reading/Writing
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (void)readDataToLength:(unsigned)len tag:(int)tag
{
	_MySocketPacket *packet;
	
	if ( ![self isConnected] || [self isListener] || len == 0 ) {
		// must be connected and have a valid length
		return;
	}
	
	// create a "read" packet
	packet = [[_MySocketPacket alloc] initWithData:[NSMutableData dataWithLength:len] tag:tag];
	//[packet handledBytes:0];
	
	// add the packet to the queue
	[_readLock lock];
	[_readQueue addObject:packet];
	[packet release];
	[_readLock unlock];
	
	// make sure the thread picks up the change
	[MySocket _refreshReadThread];
}


- (void)writeData:(NSData *)data tag:(int)tag
{
	_MySocketPacket *packet;
	BOOL alreadyWriting;
	
	if ( ![self isConnected] || [self isListener] ) {
		// must be connected
		return;
	}
	
	// create a "write" packet
	packet = [[_MySocketPacket alloc] initWithData:data tag:tag];
	
	[_writeLock lock];
	alreadyWriting = [_writeQueue count] > 0;
	[_writeQueue addObject:packet];
	[packet release];
	[_writeLock unlock];
	
	if ( !alreadyWriting ) {
		// make the helper aware the socket has data to write
		[MySocket _writeWithSockFD:_sockfd];
	}
}

- (void)writeBytes:(void const *)bytes length:(unsigned)len tag:(int)tag
{
	[self writeData:[NSData dataWithBytes:bytes length:len] tag:tag];
}


// AsyncSocket compatibility
- (void)readDataToLength:(CFIndex)length withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[self readDataToLength:length tag:tag];
}

- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[self writeData:data tag:tag];
}

- (void)writeBytes:(void *)bytes length:(unsigned)len withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[self writeBytes:bytes length:len tag:tag];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Accesors
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (unsigned)bytesRead
{
	return _bytesRead;
}

- (unsigned)bytesWritten
{
	return _bytesWritten;
}

- (NSTimeInterval)timeConnected
{
	return CFAbsoluteTimeGetCurrent() - _startTime;
}

- (double)readSpeed
{
	double currentTime = CFAbsoluteTimeGetCurrent();
	double speed = (double)( _bytesRead - _lastBytesRead ) / ( currentTime - _lastBytesReadTime );
	_lastBytesRead = _bytesRead;
	_lastBytesReadTime = currentTime;
	return speed;
}

- (double)writeSpeed
{
	double currentTime = CFAbsoluteTimeGetCurrent();
	double speed = (double)( _bytesWritten - _lastBytesWritten ) / ( currentTime - _lastBytesWrittenTime );
	_lastBytesWritten = _bytesWritten;
	_lastBytesWrittenTime = currentTime;
	return speed;
}


- (NSString *)localHost
{
	char host[128];
	int err;
	
	err = gethostname( host, sizeof(host) );
	if ( err == -1 ) {
		return @"";
	}
	return [NSString stringWithCString:host];
}

- (int)localPort
{
	return 0;
}

- (NSString *)remoteHost
{
	int err;
	struct sockaddr_in addr;
	int len = sizeof(addr);
	
	err = getpeername( _sockfd, (struct sockaddr *)(&addr), &len );
	if ( err == -1 ) {
		return @"Unknown";
	}
	return [NSString stringWithCString:inet_ntoa(addr.sin_addr)];
}

- (int)remotePort
{
	int err;
	struct sockaddr_in addr;
	int len = sizeof(addr);
	
	err = getpeername( _sockfd, (struct sockaddr *)(&addr), &len );
	if ( err == -1 ) {
		return -1;
	}
	return addr.sin_port;
}


- (BOOL)isConnected
{
	return _flags & kMySocketConnected;
}

- (BOOL)isListener
{
	return _flags & kMySocketIsListener;
}


+ (NSData *)addressWithHost:(NSString *)host port:(int)port
{
	struct hostent *h;
	struct sockaddr_in addr;
	
	// resolve the host
	h = gethostbyname( [host lossyCString] );
	if ( h == NULL ) {
		// host not found
		return nil;
	}
	
	// pack the socket address structure
	addr.sin_family = AF_INET;
	addr.sin_port = htons( (short)port );
	memcpy( &(addr.sin_addr), h->h_addr, sizeof(struct in_addr) );
	memset( &(addr.sin_zero), NULL, 8 );
	
	return [NSData dataWithBytes:&addr length:sizeof(addr)];
}


- (id)delegate
{
	return _delegate;
}

- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark PrivateAPI
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (id)_initWithFileDescriptor:(int)sockfd
{
	if ( self = [super init] ) {
		_sockfd = sockfd;
		[self _connect];
	}
	return self;
}

- (void)_connect
{
	if ( ![self isListener] ) {
		_readQueue = [[NSMutableArray alloc] init];
		_writeQueue = [[NSMutableArray alloc] init];
	}
	
	// create the locks
	_readLock = [[NSRecursiveLock alloc] init];
	_writeLock = [[NSRecursiveLock alloc] init];
	
	_startTime = _lastBytesReadTime = _lastBytesWrittenTime = CFAbsoluteTimeGetCurrent();
	_bytesRead = _lastBytesRead = _bytesWritten = _lastBytesWritten = 0;
	
	_flags |= kMySocketConnected;
	
	[self _addToManager];
}


- (void)_addToManager
{
	if ( _flags & kMySocketAddedToManager ) {
		// only add this socket once
		return;
	}
	
	// start the manager if it is not already started
	[MySocket _startManager];
	
	[MySocket _lockReadAndWrite];
	// add to global array of sockets
	[_mySocketGlobals.sockets addObject:self];
	[self release];
	[MySocket _readWithSockFD:_sockfd];
	[MySocket _unlockReadAndWrite];

	// mark as added to manager
	_flags |= kMySocketAddedToManager;
}

- (void)_removeFromManager
{
	if ( !(_flags & kMySocketAddedToManager) ) {
		// only remove if it is added
		return;
	}
	
	[MySocket _lockReadAndWrite];
	// remove from global array
	[self retain];
	ChazLog( @"REMOVING SOCKET AT INDEX %i", [_mySocketGlobals.sockets indexOfObject:self] );
	[_mySocketGlobals.sockets removeObject:self];
	FD_CLR( _sockfd, &_mySocketGlobals.readfds );
	FD_CLR( _sockfd, &_mySocketGlobals.writefds );
	[MySocket _unlockReadAndWrite];
	
	_flags ^= kMySocketAddedToManager;
}


+ (void)_readWithSockFD:(int)fd
{
	[MySocket _lockRead];
	FD_SET( fd, &_mySocketGlobals.readfds );
	_mySocketGlobals.maxreadfd = MAX( _mySocketGlobals.maxreadfd, fd );
	[MySocket _unlockRead];
	// make sure the thread picks up the change
	[MySocket _refreshReadThread];
}

+ (void)_refreshReadThread
{
	char b = 'R';
	write( _mySocketGlobals.readPipe[1], &b, sizeof(b) );
}

+ (void)_writeWithSockFD:(int)fd
{
	[MySocket _lockWrite];
	FD_SET( fd, &_mySocketGlobals.writefds );
	_mySocketGlobals.maxwritefd = MAX( _mySocketGlobals.maxwritefd, fd );
	[MySocket _unlockWrite];
	[MySocket _refreshWriteThread];
}

+ (void)_refreshWriteThread
{
	char b = 'R';
	write( _mySocketGlobals.writePipe[1], &b, sizeof(b) );
}


+ (void)_lockRead
{
	[_mySocketGlobals.readLock lock];
}

+ (void)_unlockRead
{
	[_mySocketGlobals.readLock unlock];
}

+ (void)_lockWrite
{
	[_mySocketGlobals.writeLock lock];
}

+ (void)_unlockWrite
{
	[_mySocketGlobals.writeLock unlock];
}

+ (void)_lockReadAndWrite
{
	[MySocket _lockRead];
	[MySocket _lockWrite];
}

+ (void)_unlockReadAndWrite
{
	[MySocket _unlockRead];
	[MySocket _unlockWrite];
}


+ (void)_startManager
{
	int err;
	
	if ( _mySocketGlobals.isManagerRunning ) {
		return;
	}
	
	ChazLog( @"MySocketHelper STARTING" );
	
	// zero the descriptor sets
	FD_ZERO( &_mySocketGlobals.readfds );
	FD_ZERO( &_mySocketGlobals.writefds );
	
	// create the read pipe
	err = pipe( _mySocketGlobals.readPipe );
	if ( err == -1 ) {
		return;
	}
	FD_SET( _mySocketGlobals.readPipe[0], &_mySocketGlobals.readfds );
	_mySocketGlobals.maxreadfd = _mySocketGlobals.readPipe[0];
	// create the write pipe
	err = pipe( _mySocketGlobals.writePipe );
	if ( err == -1 ) {
		close( _mySocketGlobals.readPipe[0] );
		close( _mySocketGlobals.readPipe[1] );
		return;
	}
	_mySocketGlobals.maxwritefd = _mySocketGlobals.writePipe[0];
	
	// create other global objects
	_mySocketGlobals.sockets = [[NSMutableArray alloc] init];
	_mySocketGlobals.readLock = [[NSRecursiveLock alloc] init];
	_mySocketGlobals.writeLock = [[NSRecursiveLock alloc] init];
	
	// start the threads
	[NSThread detachNewThreadSelector:@selector(_readThread:) toTarget:[MySocket class] withObject:nil];
	[NSThread detachNewThreadSelector:@selector(_writeThread:) toTarget:[MySocket class] withObject:nil];
	_mySocketGlobals.isManagerRunning = YES;
}

+ (void)_readThread:(id)object
{
	BOOL breakLoop = NO;
	fd_set readfds;
	
	do {
		int err;
		int i, top;
		
		// create the ever-so-important pool
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[MySocket _lockRead];
		//FD_COPY( &_mySocketGlobals.readfds, &readfds );
		readfds = _mySocketGlobals.readfds;
		[MySocket _unlockRead];
		
		// find the sockets which need processing
		err = select( _mySocketGlobals.maxreadfd+1, &readfds, NULL, NULL, NULL );
		if ( err == -1 ) {
			// trouble, select() is having problems
			ChazLog( @"select() failed!, error: %s", strerror(errno) );
			goto DONE;
		}
		
		// check the pipe
		if ( FD_ISSET( _mySocketGlobals.readPipe[0], &readfds ) ) {
			char b;
			err = read( _mySocketGlobals.readPipe[0], &b, sizeof(b) );
			if ( err <= 0 ) {
				// our connection to the main thread was severed...
				// SELF DESTRUCT
				ChazLog( @"readPipe severed, exiting READ thread..." );
				breakLoop = YES;
				goto DONE;
			}
		}
		
		// process the sockets
		[MySocket _lockRead];
		top = [_mySocketGlobals.sockets count];
		for ( i = 0; i < top; i++ ) {
			MySocket *sock = [_mySocketGlobals.sockets objectAtIndex:i];
			int sockfd = [sock _sockfd];
			
			[sock _fillReadPacketsWithUnclaimedBytes];
			[sock _handleReadQueue];
			
			if ( FD_ISSET( sockfd, &readfds ) ) {
				if ( [sock isListener] ) {
					// socket ready for accepting
					err = [sock _accept];
				}
				else {
					// socket ready for reading
					err = [sock _read];
				}
				if ( err == -1 ) {
					// action returne error, disconnect socket
					[sock disconnect];
					[sock performSelectorOnMainThread:@selector(_eventDidDisconnect:)
										   withObject:nil waitUntilDone:NO];
					top--;
				}
			}
		}
		[MySocket _unlockRead];
		
DONE:;
		[pool release];
	}
	while ( !breakLoop );
}

+ (void)_writeThread:(id)object
{
	BOOL breakLoop = NO;
	fd_set pipefds;
	fd_set readfds, writefds;
	
	FD_ZERO( &pipefds );
	FD_SET( _mySocketGlobals.writePipe[0], &pipefds );
	
	do {
		int err;
		int i, top;
		
		// create the ever-so-important pool
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		readfds = pipefds;
		[MySocket _lockWrite];
		//FD_COPY( &_mySocketGlobals.writefds, &writefds );
		writefds = _mySocketGlobals.writefds;
		[MySocket _unlockWrite];
		
		// find the sockets which need processing
		err = select( _mySocketGlobals.maxwritefd+1, &readfds, &writefds, NULL, NULL );
		if ( err == -1 ) {
			// trouble, select() is having problems
			ChazLog( @"select() failed!, error: %s", strerror(errno) );
			goto DONE;
		}
		
		// check the pipe
		if ( FD_ISSET( _mySocketGlobals.writePipe[0], &readfds ) ) {
			char b;
			err = read( _mySocketGlobals.writePipe[0], &b, sizeof(b) );
			if ( err <= 0 ) {
				// our connection to the main thread was severed...
				// SELF DESTRUCT
				ChazLog( @"writePipe severed" );
				breakLoop = YES;
				goto DONE;
			}
		}
		
		// process the sockets
		[MySocket _lockWrite];
		top = [_mySocketGlobals.sockets count];
		for ( i = 0; i < top; i++ ) {
			MySocket *sock = [_mySocketGlobals.sockets objectAtIndex:i];
			int sockfd = [sock _sockfd];
			
			if ( FD_ISSET( sockfd, &writefds ) ) {
				// socket ready for accepting
				err = [sock _write];
				if ( err == -1 ) {
					// action returne error, disconnect socket
					[sock disconnect];
					[sock performSelectorOnMainThread:@selector(_eventDidDisconnect:)
										   withObject:nil waitUntilDone:NO];
					top--;
				}
			}
		}
		[MySocket _unlockWrite];
		
DONE:;
		[pool release];
	}
	while ( !breakLoop );
}


- (int)_accept
{
	MySocket *newSocket;
	int newsockfd;
	struct sockaddr addr;
	int addrlen = sizeof(addr);
	
	newsockfd = accept( _sockfd, &addr, &addrlen );
	if ( newsockfd >= 0 ) {
		// create a new MySocket
		newSocket = [[MySocket alloc] _initWithFileDescriptor:newsockfd];
		[newSocket setDelegate:_delegate];
		
		[self performSelectorOnMainThread:@selector(_eventDidAcceptSocket:)
							   withObject:newSocket waitUntilDone:NO];
	}
	else {
		return -1;
	}
	return 0;
}

- (int)_read
{
	_MySocketPacket *packet = nil;
	int bytesRead;
	
	[_readLock lock];
	if ( [_readQueue count] == 0 ) {
		// no packets claiming anything, so just
		// read into the unclaimed bytes buffer.
		if ( !_unclaimedData ) {
			_unclaimedData = [[NSMutableData alloc] init];
		}
		int len = [_unclaimedData length];
		[_unclaimedData increaseLengthBy:MYSOCKET_PACKETLEN];
		bytesRead = recv( _sockfd, [_unclaimedData mutableBytes] + len, MYSOCKET_PACKETLEN, 0 );
		[_unclaimedData setLength:len+bytesRead];
	}
	else {
		packet = [_readQueue objectAtIndex:0];
		bytesRead = recv( _sockfd, [packet bytes], [packet bytesRemaining], 0 );
		[packet handledBytes:bytesRead];
	}
	[_readLock unlock];
	
	if ( bytesRead > 0 ) {
		// update total bytes read
		_bytesRead += bytesRead;
		
		[self _handleReadQueue];
	}
	else {
		// remove this socket
		ChazLog( @"MySocket disconnecting: %i", bytesRead );
		return -1;
	}
	return 0;
}

- (int)_write
{
	_MySocketPacket *packet = nil;
	int bytesWritten = 0;
	
	[_writeLock lock];
	if ( [_writeQueue count] > 0 ) {
		int buflen = 0;
		int len = sizeof(buflen);
		int err;
		err = getsockopt( _sockfd, SOL_SOCKET, SO_SNDBUF, &buflen, &len );
		// write data
		packet = [_writeQueue objectAtIndex:0];
		bytesWritten = send( _sockfd, [packet bytes], MIN([packet bytesRemaining],buflen/2), 0 ); //MIN(4096,[packet bytesRemaining]), 0 );
		[packet handledBytes:bytesWritten];
	}
	[_writeLock unlock];
	
	if ( bytesWritten >= 0 ) {
		// update total bytes read
		_bytesWritten += bytesWritten;
		
		[self _handleWriteQueue];
	}
	else {
		return -1;
	}
	return 0;
}


- (void)_fillReadPacketsWithUnclaimedBytes
{
	int i, top;
	void *bytes;
	int total;
	
	total = [_unclaimedData length];
	if ( total == 0 ) {
		return;
	}
	bytes = [_unclaimedData mutableBytes];
	
	[_readLock lock];
	top = [_readQueue count];
	for ( i = 0; i < top; i++ ) {
		_MySocketPacket *packet = [_readQueue objectAtIndex:i];
		int len = MIN( total, [packet bytesRemaining] );
		
		if ( len > 0 ) {
			memcpy( [packet bytes], bytes, len );
			[packet handledBytes:len];
			bytes += len;
			total -= len;
		}
		if ( total == 0 ) {
			break;
		}
	}
	[_unclaimedData replaceBytesInRange:NSMakeRange(0,[_unclaimedData length]-total) withBytes:NULL length:0];
	[_readLock unlock];
}


- (void)_handleReadQueue
{
	int i, top;
	
	[_readLock lock];
	top = [_readQueue count];
	for ( i = 0; i < top; ) {
		_MySocketPacket *packet = [_readQueue objectAtIndex:0];
		if ( [packet isComplete] ) {
			[self performSelectorOnMainThread:@selector(_eventDidReadData:)
								   withObject:[packet retain] waitUntilDone:NO];
			[_readQueue removeObjectAtIndex:i];
			top--;
		}
		else {
			i++;
		}
	}
	[_readLock unlock];
}

- (void)_handleWriteQueue
{
	int i, top;
	
	[_writeLock lock];
	top = [_writeQueue count];
	for ( i = 0; i < top; ) {
		_MySocketPacket *packet = [_writeQueue objectAtIndex:0];
		if ( [packet isComplete] ) {
			[self performSelectorOnMainThread:@selector(_eventDidWriteData:)
								   withObject:[packet retain] waitUntilDone:NO];
			[_writeQueue removeObjectAtIndex:i];
			top--;
		}
		else {
			i++;
		}
	}
	if ( [_writeQueue count] == 0 ) {
		// no more pending writes
		FD_CLR( _sockfd, &_mySocketGlobals.writefds );
	}
	[_writeLock unlock];
}


- (void)_eventDidAcceptSocket:(MySocket *)newSocket
{
	// just report the event back to the delegate
	if ( [_delegate respondsToSelector:@selector(socket:didAcceptSocket:)] ) {
		[_delegate socket:self didAcceptSocket:newSocket];
	}
	
	// release the parameter(s)
	// they were not released by the caller because the caller is in another thread.
	[newSocket release];
}

- (void)_eventDidDisconnect:(id)dummy
{
	[self disconnect];
	if ( [_delegate respondsToSelector:@selector(socketDidDisconnect:)] ) {
		[_delegate socketDidDisconnect:self];
	}
}

- (void)_eventDidReadData:(_MySocketPacket *)packet
{
	if ( [_delegate respondsToSelector:@selector(socket:didReadData:tag:)] ) {
		[_delegate socket:self didReadData:[packet data] tag:[packet tag]];
	}
	
	[packet release];
}

- (void)_eventDidWriteData:(_MySocketPacket *)packet
{
	if ( [_delegate respondsToSelector:@selector(socket:didWriteDataWithTag:)] ) {
		[_delegate socket:self didWriteDataWithTag:[packet tag]];
	}
	
	[packet release];
}


- (NSMutableData *)_readBufferWithLength:(unsigned *)len
{
	NSMutableData *buffer;
	unsigned packetLen = *len;
	
	if ( buffer = _unclaimedData ) {
		// claim the bytes
		int unclaimedLen = [_unclaimedData length];
		if ( unclaimedLen > packetLen ) {
			*len = packetLen;
			_unclaimedData = [[NSMutableData alloc] initWithBytes:[buffer bytes]+packetLen length:unclaimedLen-packetLen];
				//[[buffer subdataWithRange:NSMakeRange(packetLen,unclaimedLen-packetLen)] retain];
		}
		else {
			*len = unclaimedLen;
			_unclaimedData = nil;
		}
		[buffer setLength:packetLen];
	}
	else {
		buffer = [[NSMutableData alloc] initWithLength:packetLen];
		*len = 0;
	}
	return [buffer autorelease];
}


- (int)_sockfd
{
	return _sockfd;
}


@end


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark _MySocketPacket
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

@implementation _MySocketPacket


- (id)initWithData:(NSData *)data tag:(int)tag
{
	if ( self = [super init] ) {
		_buffer = [data retain];
		_bytesRequired = [data length];
		_tag = tag;
	}
	return self;
}

- (void)dealloc
{
	[_buffer release];
	[super dealloc];
}


- (void *)bytes
{
	return (void *)[_buffer bytes] + _bytesHandled;
}

- (unsigned)bytesRemaining
{
	return _bytesRequired - _bytesHandled;
}


- (void)handledBytes:(unsigned)count
{
	_bytesHandled += count;
}

- (unsigned)bytesRequired
{
	return _bytesRequired;
}


- (NSData *)data
{
	return _buffer;
}

- (int)tag
{
	return _tag;
}

- (BOOL)isComplete
{
	return [self bytesRemaining] == 0;
}



@end
