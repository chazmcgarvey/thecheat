
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

#import "ServerChild.h"


@interface ServerChild ( PrivateAPI )

- (void)_handlePacket;

- (void)_setClient:(NSString *)status;

@end


@implementation ServerChild


- (id)initWithSocket:(MySocket *)sock
{
	return [self initWithSocket:sock delegate:nil];
}

- (id)initWithSocket:(MySocket *)sock delegate:(id)delegate
{
	if ( self = [super init] ) {
		_socket = [sock retain];
		[_socket setDelegate:self];
		_delegate = delegate;
		
		// create the cheater object
		_cheater = [[LocalCheater alloc] initWithDelegate:self];
		[_cheater setShouldCopy:NO];
		
		// start reading from the socket
		[_socket readDataToLength:sizeof(TCPacketHeader) tag:0];
		
		if ( [_delegate respondsToSelector:@selector(serverChildConnected:)] ) {
			[_delegate serverChildConnected:self];
		}
	}
	return self;
}

- (void)dealloc
{
	//[_socket setDelegate:[self class]];
	//[_socket disconnect];
	[_socket setDelegate:nil];
	[_socket release];
	
	[_client release];
	[_parameters release];
	[_cheater release];
	[super dealloc];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark MySocketDelegate
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (void)socket:(MySocket *)mySocket didReadData:(NSData *)theData tag:(int)tag
{
	if ( tag == 0 && [theData length] == sizeof(TCPacketHeader) ) {
		// got a packet header
		memcpy( &_header, [theData bytes], sizeof(TCPacketHeader) );
		if ( _header.size > 0 ) {
			// request the rest of the packet
			[mySocket readDataToLength:_header.size tag:1];
		}
		else {
			[self _handlePacket];
			// start reading the next packet
			[mySocket readDataToLength:sizeof(TCPacketHeader) tag:0];
		}
	}
	else if ( tag == 1 && [theData length] == _header.size ) {
		// got packet parameter data
		_parameters = [theData retain];
		[self _handlePacket];
		// start reading the next packet
		[mySocket readDataToLength:sizeof(TCPacketHeader) tag:0];
	}
	else {
		ChazLog( @"ServerChild - read unexpected data, disconnecting..." );
		[_socket release];
		_socket = nil;
		if ( [_delegate respondsToSelector:@selector(serverChildDisconnected:)] ) {
			[_delegate serverChildDisconnected:self];
		}
	}
}

- (void)socketDidDisconnect:(MySocket *)mySocket
{
	[_socket release];
	_socket = nil;
	
	if ( [_delegate respondsToSelector:@selector(serverChildDisconnected:)] ) {
		[_delegate serverChildDisconnected:self];
	}
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark Accessors
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (NSString *)host
{
	return [_socket remoteHost];
}

- (NSString *)transfer
{
	unsigned bytes = [_socket bytesRead] + [_socket bytesWritten];
	double speed = [_socket readSpeed] + [_socket writeSpeed];

	if ( speed > 0.0 ) {
		return [NSString stringWithFormat:@"%.1fMB (%.1fkbps)", (float)bytes/1038576.0f, (float)speed/1024.0f];
	}
	return [NSString stringWithFormat:@"%.1fMB", (float)bytes/1038576.0f];
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

- (void)_handlePacket
{
	if ( strncmp( "connect", _header.name, sizeof(_header.name) ) == 0 ) {
		ChazLog( @"ServerChild - connect received!!" );
		[_cheater connect];
		[self _setClient:[NSUnarchiver unarchiveObjectWithData:_parameters]];
	}
	else if ( strncmp( "authenticate", _header.name, sizeof(_header.name) ) == 0 ) {
		ChazLog( @"ServerChild - process list requested" );
		[_cheater authenticateWithPassword:[NSUnarchiver unarchiveObjectWithData:_parameters]];
	}
	else if ( strncmp( "getproclist", _header.name, sizeof(_header.name) ) == 0 ) {
		ChazLog( @"ServerChild - process list requested" );
		[_cheater getProcessList];
	}
	else if ( strncmp( "settarget", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater setTarget:[NSUnarchiver unarchiveObjectWithData:_parameters]];
	}
	else if ( strncmp( "pausetarget", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater pauseTarget];
	}
	else if ( strncmp( "resumetarget", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater resumeTarget];
	}
	else if ( strncmp( "limitresults", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater limitReturnedResults:[[NSUnarchiver unarchiveObjectWithData:_parameters] unsignedIntValue]];
	}
	else if ( strncmp( "search", _header.name, sizeof(_header.name) ) == 0 ) {
		NSArray *params = [NSUnarchiver unarchiveObjectWithData:_parameters];
		[_cheater searchForVariable:[params objectAtIndex:0] comparison:[[params objectAtIndex:1] unsignedCharValue]];
	}
	else if ( strncmp( "lastsearch", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater searchLastValuesComparison:[[NSUnarchiver unarchiveObjectWithData:_parameters] unsignedCharValue]];
	}
	else if ( strncmp( "cancelsearch", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater cancelSearch];
	}
	else if ( strncmp( "clearsearch", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater clearSearch];
	}
	else if ( strncmp( "dump", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater getMemoryDump];
	}
	else if ( strncmp( "canceldump", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater cancelMemoryDump];
	}
	else if ( strncmp( "changevars", _header.name, sizeof(_header.name) ) == 0 ) {
		NSArray *params = [NSUnarchiver unarchiveObjectWithData:_parameters];
		[_cheater makeVariableChanges:[params objectAtIndex:0] repeat:[[params objectAtIndex:1] boolValue]
							 interval:[[params objectAtIndex:2] doubleValue]];
	}
	else if ( strncmp( "stopchange", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater stopChangingVariables];
	}
	else if ( strncmp( "undo", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater undo];
	}
	else if ( strncmp( "redo", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater redo];
	}
	else if ( strncmp( "watchvars", _header.name, sizeof(_header.name) ) == 0 ) {
		NSArray *params = [NSUnarchiver unarchiveObjectWithData:_parameters];
		[_cheater watchVariablesAtIndex:[[params objectAtIndex:0] unsignedIntValue] count:[[params objectAtIndex:1] unsignedIntValue]
							 interval:[[params objectAtIndex:2] doubleValue]];
	}
	else if ( strncmp( "stopwatch", _header.name, sizeof(_header.name) ) == 0 ) {
		[_cheater stopWatchingVariables];
	}
	
	[_parameters release];
	_parameters = nil;
}


- (void)_setClient:(NSString *)client
{
	[client retain];
	[_client release];
	_client = client;
	if ( [_delegate respondsToSelector:@selector(serverChildChanged:)] ) {
		[_delegate serverChildChanged:self];
	}
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark CheaterDelegate
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)cheaterDidConnect:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "connected" };
	ChazLog( @"SENT didconnect" );
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)cheaterDidDisconnect:(Cheater *)cheater
{
	// nothing needs to be done
}


- (void)cheaterRequiresAuthentication:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "requireauth" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)cheaterRejectedPassword:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "rejectedauth" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)cheaterAcceptedPassword:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "authenticated" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)cheater:(Cheater *)cheater didFindProcesses:(NSArray *)processes
{	
	NSData *params = [NSArchiver archivedDataWithRootObject:processes];
	TCPacketHeader header = { TC_NIFTY, [params length], "proclist" };
	
	ChazLog( @"SENT proclist" );
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];

}

- (void)cheater:(Cheater *)cheater didAddProcess:(Process *)process
{
	NSData *params = [NSArchiver archivedDataWithRootObject:process];
	TCPacketHeader header = { TC_NIFTY, [params length], "addprocess" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)cheater:(Cheater *)cheater didRemoveProcess:(Process *)process
{
	NSData *params = [NSArchiver archivedDataWithRootObject:process];
	TCPacketHeader header = { TC_NIFTY, [params length], "removeprocess" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}


- (void)cheater:(Cheater *)cheater didSetTarget:(Process *)target
{
	NSData *params = [NSArchiver archivedDataWithRootObject:target];
	TCPacketHeader header = { TC_NIFTY, [params length], "didsettarget" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)cheaterPausedTarget:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "didpausetarget" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)cheaterResumedTarget:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "didresumetarget" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)cheater:(Cheater *)cheater didFindVariables:(TCArray)variables actualAmount:(unsigned)count
{
	struct {
		unsigned actualAmount;
		unsigned varCount;
		unsigned varSize;
	} varInfo = { count, TCArrayElementCount(variables), TCArrayElementSize(variables) };
	unsigned bufferLen = varInfo.varCount * varInfo.varSize;
	
	TCPacketHeader header = { TC_NIFTY, sizeof(varInfo) + bufferLen, "vars" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeBytes:&varInfo length:sizeof(varInfo) tag:0];
	[_socket writeBytes:TCArrayBytes(variables) length:bufferLen tag:0];
	
	TCReleaseArray( variables );
}

- (void)cheater:(Cheater *)cheater didFindValues:(TCArray)values
{
	struct {
		unsigned varCount;
		unsigned varSize;
	} varInfo = { TCArrayElementCount(values), TCArrayElementSize(values) };
	unsigned bufferLen = varInfo.varCount * varInfo.varSize;
	
	TCPacketHeader header = { TC_NIFTY, sizeof(varInfo) + bufferLen, "values" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeBytes:&varInfo length:sizeof(varInfo) tag:0];
	[_socket writeBytes:TCArrayBytes(values) length:bufferLen tag:0];
	
	TCReleaseArray( values );
}

- (void)cheaterDidCancelSearch:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "didcancelsearch" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)cheaterDidClearSearch:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "didclearsearch" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)cheater:(Cheater *)cheater didDumpMemory:(NSData *)memoryDump
{
	TCPacketHeader header = { TC_NIFTY, [memoryDump length], "memdump" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:memoryDump tag:0];
}

- (void)cheaterDidCancelMemoryDump:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "didcanceldump" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)cheater:(Cheater *)cheater didChangeVariables:(unsigned)changeCount
{
	NSData *params = [NSArchiver archivedDataWithRootObject:[NSNumber numberWithUnsignedInt:changeCount]];
	TCPacketHeader header = { TC_NIFTY, [params length], "changedvars" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)cheaterDidStopChangingVariables:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "didstopchanging" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)cheater:(Cheater *)cheater didReportProgress:(int)progress
{
	NSData *params = [NSArchiver archivedDataWithRootObject:[NSNumber numberWithInt:progress]];
	TCPacketHeader header = { TC_NIFTY, [params length], "progress" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}


- (void)cheater:(Cheater *)cheater didRevertToVariables:(TCArray)variables actualAmount:(unsigned)count
{
	struct {
		unsigned actualAmount;
		unsigned varCount;
		unsigned varSize;
	} varInfo = { count, TCArrayElementCount(variables), TCArrayElementSize(variables) };
	unsigned bufferLen = varInfo.varCount * varInfo.varSize;
	
	TCPacketHeader header = { TC_NIFTY, sizeof(varInfo) + bufferLen, "revertedto" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeBytes:&varInfo length:sizeof(varInfo) tag:0];
	[_socket writeBytes:TCArrayBytes(variables) length:bufferLen tag:0];
	
	TCReleaseArray( variables );
}


- (void)cheaterDidUndo:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "didundo" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)cheaterDidRedo:(Cheater *)cheater
{
	TCPacketHeader header = { TC_NIFTY, 0, "didredo" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)cheater:(Cheater *)cheater variableAtIndex:(unsigned)index didChangeTo:(Variable *)variable
{
	NSData *params = [NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:index], variable, nil]];
	TCPacketHeader header = { TC_NIFTY, [params length], "varchanged" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}


- (void)cheater:(Cheater *)cheater didFailLastRequest:(NSString *)reason
{
	NSData *params = [NSArchiver archivedDataWithRootObject:reason];
	TCPacketHeader header = { TC_NIFTY, [params length], "failed" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)cheater:(Cheater *)cheater echo:(NSString *)message
{
	NSData *params = [NSArchiver archivedDataWithRootObject:message];
	TCPacketHeader header = { TC_NIFTY, [params length], "echo" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}


@end
