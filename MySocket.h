//
//  MySocket.h
//  The Cheat
//
//  Created by Chaz McGarvey on 2/1/05.
//  Copyright 2005 Chaz McGarvey. All rights reserved.
//

/*
 * MySocket is my 24 hour hackjob.  There are other classes which would have
 * done a better job, but I found them to be too slow.  This class wraps
 * around BSD sockets directly.  It uses two threads for both asynchronous
 * reads and writes.  Performance still isn't spectacular... I measure about
 * 58 MB/s average when transfering to localhost.
 * The way the old The Cheat did networking was by spawning a new thread for
 * each connection (for both serving and receiving).  I thought that this way
 * would be more efficient, but the old way is noticeably faster.  I may go
 * back to that way eventually, after all it isn't that many threads.
 */

#import <Cocoa/Cocoa.h>
#import "ChazLog.h"

#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h> 
#include <netdb.h>
#include <fcntl.h>

#include <string.h>


/*
 * This class has a few limitations which may not be obvious.  First, it will
 * only send back delegate methods on the Main thread, not necessarily the
 * same thread used to create the socket.  There is no way to time out a read
 * or write action.  There is no way to just read "all" data possible; you
 * must specify how much data to receive.
 */


@interface MySocket : NSObject
{
	int _sockfd;
	
	NSMutableArray *_readQueue;
	NSMutableArray *_writeQueue;
	NSMutableData *_unclaimedData;
	NSRecursiveLock *_readLock;
	NSRecursiveLock *_writeLock;
	
	unsigned _flags;
	unsigned _bytesRead;
	unsigned _bytesWritten;
	NSTimeInterval _startTime;
	
	unsigned _lastBytesRead;
	unsigned _lastBytesWritten;
	NSTimeInterval _lastBytesReadTime;
	NSTimeInterval _lastBytesWrittenTime;
	
	id _delegate;
}

/* INITIALIZATION */
- (id)initWithDelegate:(id)delegate;

/* CONNECTING/ACCEPTING */
- (BOOL)connectToHost:(NSString *)host port:(int)port;
- (BOOL)connectToAddress:(const struct sockaddr *)addr length:(unsigned)addrLen;
- (BOOL)connectToAddressWithData:(NSData *)addr;
- (BOOL)listenOnPort:(int)port;
// returns YES on success

/* OBVIOUS */
- (void)disconnect;
// the disconnect delegate method will NOT be called.
// it is only called when the socket is disconnect by remote or by error.
// absolutely NO delegate methods are sent after this (until reconnecting).

/* READING & WRITING */
- (void)readDataToLength:(unsigned)len tag:(int)tag;
- (void)writeData:(NSData *)data tag:(int)tag;
- (void)writeBytes:(void const *)bytes length:(unsigned)len tag:(int)tag;
/* Nope, there is no way to time out a request. */

/* STATISTICS */
- (unsigned)bytesRead;
- (unsigned)bytesWritten;
/* the above accessors can be accessed after the socket is disconnected to get
   the grand total amount of traffic passed through the socket. */
- (NSTimeInterval)timeConnected;
- (double)readSpeed; // bytes/sec
- (double)writeSpeed; // bytes/sec
/* These speeds are averaged out using the last time these methods were called.
   The more often you call these methods the more accurate they will be. */

- (NSString *)localHost;
- (int)localPort;
- (NSString *)remoteHost;
- (int)remotePort;

- (BOOL)isConnected;
- (BOOL)isListener;

/* CONVENIENCE */
+ (NSData *)addressWithHost:(NSString *)host port:(int)port;

/* DELEGATION */
- (id)delegate;
- (void)setDelegate:(id)delegate;

@end


@interface NSObject ( MySocketDelegate )

/* DELEGATE METHODS */
- (void)socketDidDisconnect:(MySocket *)mySocket;
- (void)socket:(MySocket *)mySocket didAcceptSocket:(MySocket *)newSocket;
- (void)socket:(MySocket *)mySocket didReadData:(NSData *)theData tag:(int)tag;
- (void)socket:(MySocket *)mySocket didWriteDataWithTag:(int)tag;

@end