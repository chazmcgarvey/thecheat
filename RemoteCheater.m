
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

#import "RemoteCheater.h"


@interface RemoteCheater ( PrivateAPI )

- (void)_handlePacket;

@end



@implementation RemoteCheater


- (void)dealloc
{
	[self disconnect];
	[super dealloc];
}


- (BOOL)connectToHostWithData:(NSData *)data
{
	if ( _socket ) {
		[self disconnect];
	}
	_socket = [[MySocket alloc] initWithDelegate:self];
	if ( ![_socket connectToAddressWithData:data] ) {
		return NO;
	}
	
	// start reading from the socket
	[_socket readDataToLength:sizeof(TCPacketHeader) tag:0];
	
	return YES;
}

- (NSString *)hostAddress
{
	return [_socket remoteHost];
}


// #############################################################################
#pragma mark Cheater Override
// #############################################################################

- (void)connect
{
	NSData *params = [NSArchiver archivedDataWithRootObject:[NSString stringWithFormat:@"%@ %@", ChazAppName(), ChazAppVersion()]];
	TCPacketHeader header = { TC_NIFTY, [params length], "connect" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)disconnect
{
	[_socket setDelegate:nil];
	[_socket release];
	_socket = nil;
	//[_delegate cheaterDidDisconnect:self];
}

- (void)authenticateWithPassword:(NSString *)password
{
	NSData *params = [NSArchiver archivedDataWithRootObject:password];
	TCPacketHeader header = { TC_NIFTY, [params length], "authenticate" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}


- (void)getProcessList
{
	TCPacketHeader header = { TC_NIFTY, 0, "getproclist" };
	ChazLog( @"SENT getproclist" );
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)setTarget:(Process *)target
{
	NSData *params = [NSArchiver archivedDataWithRootObject:target];
	TCPacketHeader header = { TC_NIFTY, [params length], "settarget" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)pauseTarget
{
	TCPacketHeader header = { TC_NIFTY, 0, "pausetarget" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)resumeTarget
{
	TCPacketHeader header = { TC_NIFTY, 0, "resumetarget" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)limitReturnedResults:(unsigned)limit
{
	NSData *params = [NSArchiver archivedDataWithRootObject:[NSNumber numberWithUnsignedInt:limit]];
	TCPacketHeader header = { TC_NIFTY, [params length], "limitresults" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)searchForVariable:(Variable *)data comparison:(TCSearchOperator)op
{
	NSData *params = [NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:data, [NSNumber numberWithUnsignedChar:op], nil]];
	TCPacketHeader header = { TC_NIFTY, [params length], "search" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)searchLastValuesComparison:(TCSearchOperator)op
{
	NSData *params = [NSArchiver archivedDataWithRootObject:[NSNumber numberWithUnsignedChar:op]];
	TCPacketHeader header = { TC_NIFTY, [params length], "lastsearch" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)cancelSearch
{
	TCPacketHeader header = { TC_NIFTY, 0, "cancelsearch" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)clearSearch
{
	TCPacketHeader header = { TC_NIFTY, 0, "clearsearch" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)getMemoryDump
{
	TCPacketHeader header = { TC_NIFTY, 0, "dump" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)cancelMemoryDump
{
	TCPacketHeader header = { TC_NIFTY, 0, "canceldump" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)makeVariableChanges:(NSArray *)variables repeat:(BOOL)doRepeat interval:(NSTimeInterval)repeatInterval
{
	NSData *params = [NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:variables,
		[NSNumber numberWithBool:doRepeat], [NSNumber numberWithDouble:repeatInterval], nil]];
	TCPacketHeader header = { TC_NIFTY, [params length], "changevars" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)stopChangingVariables
{
	TCPacketHeader header = { TC_NIFTY, 0, "stopchange" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)undo
{
	TCPacketHeader header = { TC_NIFTY, 0, "undo" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}

- (void)redo
{
	TCPacketHeader header = { TC_NIFTY, 0, "redo" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
}


- (void)watchVariablesAtIndex:(unsigned)index count:(unsigned)count interval:(NSTimeInterval)checkInterval
{
	NSData *params = [NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:index],
		[NSNumber numberWithUnsignedInt:count], [NSNumber numberWithDouble:checkInterval], nil]];
	TCPacketHeader header = { TC_NIFTY, [params length], "watchvars" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
	[_socket writeData:params tag:0];
}

- (void)stopWatchingVariables
{
	TCPacketHeader header = { TC_NIFTY, 0, "stopwatching" };
	[_socket writeBytes:&header length:sizeof(header) tag:0];
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
		ChazLog( @"RemoteCheater - read expected data, disconnecting..." );
		[self disconnect];
	}
}

- (void)socketDidDisconnect:(MySocket *)mySocket
{
	[_socket release];
	_socket = nil;
	
	[_delegate cheaterDidDisconnect:self];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#pragma mark PrivateAPI
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

- (void)_handlePacket
{
	if ( strncmp( "connected", _header.name, sizeof(_header.name) ) == 0 ) {
		ChazLog( @"RemoteCheater - connected" );
		[_delegate cheaterDidConnect:self];
	}
	else if ( strncmp( "requireauth", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterRequiresAuthentication:self];
	}
	else if ( strncmp( "rejectedauth", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterRejectedPassword:self];
	}
	else if ( strncmp( "authenticated", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterAcceptedPassword:self];
	}
	else if ( strncmp( "proclist", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheater:self didFindProcesses:[NSUnarchiver unarchiveObjectWithData:_parameters]];
	}
	else if ( strncmp( "addprocess", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheater:self didAddProcess:[NSUnarchiver unarchiveObjectWithData:_parameters]];
	}
	else if ( strncmp( "removeprocess", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheater:self didRemoveProcess:[NSUnarchiver unarchiveObjectWithData:_parameters]];
	}
	else if ( strncmp( "didsettarget", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheater:self didSetTarget:[NSUnarchiver unarchiveObjectWithData:_parameters]];
	}
	else if ( strncmp( "didpausetarget", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterPausedTarget:self];
	}
	else if ( strncmp( "didresumetarget", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterResumedTarget:self];
	}
	else if ( strncmp( "vars", _header.name, sizeof(_header.name) ) == 0 ) {
		struct varInfo {
			unsigned count;
			unsigned varCount;
			unsigned varSize;
		} *varInfo;
		void *bytes;
		TCArray variables;
		varInfo = (struct varInfo *)[_parameters bytes];
		bytes = (void *)[_parameters bytes] + sizeof(*varInfo);
		variables = TCMakeArrayWithBytes( varInfo->varCount, varInfo->varSize, bytes );
		[_delegate cheater:self didFindVariables:variables actualAmount:varInfo->count];
	}
	else if ( strncmp( "values", _header.name, sizeof(_header.name) ) == 0 ) {
		struct varInfo {
			unsigned varCount;
			unsigned varSize;
		} *varInfo;
		void *bytes;
		TCArray values;
		varInfo = (struct varInfo *)[_parameters bytes];
		bytes = (void *)[_parameters bytes] + sizeof(*varInfo);
		values = TCMakeArrayWithBytes( varInfo->varCount, varInfo->varSize, bytes );
		[_delegate cheater:self didFindValues:values];
	}
	else if ( strncmp( "didcancelsearch", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterDidCancelSearch:self];
	}
	else if ( strncmp( "didclearsearch", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterDidClearSearch:self];
	}
	else if ( strncmp( "memdump", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheater:self didDumpMemory:_parameters];
	}
	else if ( strncmp( "didcanceldump", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterDidCancelMemoryDump:self];
	}
	else if ( strncmp( "changedvars", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheater:self didChangeVariables:[[NSUnarchiver unarchiveObjectWithData:_parameters] unsignedIntValue]];
	}
	else if ( strncmp( "didstopchanging", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterDidStopChangingVariables:self];
	}
	else if ( strncmp( "progress", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheater:self didReportProgress:[[NSUnarchiver unarchiveObjectWithData:_parameters] intValue]];
	}
	else if ( strncmp( "revertedto", _header.name, sizeof(_header.name) ) == 0 ) {
		struct varInfo {
			unsigned count;
			unsigned varCount;
			unsigned varSize;
		} *varInfo;
		void *bytes;
		TCArray variables;
		varInfo = (struct varInfo *)[_parameters bytes];
		bytes = (void *)[_parameters bytes] + sizeof(*varInfo);
		variables = TCMakeArrayWithBytes( varInfo->varCount, varInfo->varSize, bytes );
		[_delegate cheater:self didRevertToVariables:variables actualAmount:varInfo->count];
	}
	else if ( strncmp( "didundo", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterDidUndo:self];
	}
	else if ( strncmp( "didredo", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheaterDidRedo:self];
	}
	else if ( strncmp( "varchanged", _header.name, sizeof(_header.name) ) == 0 ) {
		NSArray *params = [NSUnarchiver unarchiveObjectWithData:_parameters];
		[_delegate cheater:self variableAtIndex:[[params objectAtIndex:0] unsignedIntValue] didChangeTo:[params objectAtIndex:1]];
	}
	else if ( strncmp( "failed", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheater:self didFailLastRequest:[NSUnarchiver unarchiveObjectWithData:_parameters]];
	}
	else if ( strncmp( "echo", _header.name, sizeof(_header.name) ) == 0 ) {
		[_delegate cheater:self echo:[NSUnarchiver unarchiveObjectWithData:_parameters]];
	}
	
	[_parameters release];
	_parameters = nil;
}



@end
