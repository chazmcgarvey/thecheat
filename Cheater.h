
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

#import "CheaterTypes.h"

#import "Process.h"
#import "Variable.h"


// The network protocol The Cheat uses is way simple.  the header is
// a fixed size: 24 bytes.  Immediately following the header is the
// packet data.

typedef struct _TCPacketHeader
{
	unsigned nifty; // always the same: 'DENT' or 0x44454E54.
	unsigned size; // the size of the packet (excluding this header).
	char name[16]; // NULL-terminated string describing the packet.
} TCPacketHeader;


// network definitions
#define TC_NIFTY (0x44454E54)


@interface Cheater : NSObject
{
	BOOL _isConnected;
	BOOL _isAuthenticated;
	id _delegate;
}

// #############################################################################
#pragma mark Initialization
// #############################################################################

- (id)initWithDelegate:(id)delegate;

// delegation
- (id)delegate;
- (void)setDelegate:(id)delegate;

// accessors
- (BOOL)isConnected;
- (BOOL)isAuthenticated;
- (NSString *)hostAddress;

// #############################################################################
#pragma mark Cheating Control
// #############################################################################

// Methods with AUTH require authentication.

- (void)connect;
- (void)disconnect;
- (void)authenticateWithPassword:(NSString *)password;

- (void)getProcessList;

- (void)setTarget:(Process *)target;
- (void)pauseTarget; // AUTH
- (void)resumeTarget; // AUTH

- (void)limitReturnedResults:(unsigned)limit;
- (void)searchForVariable:(Variable *)var comparison:(TCSearchOperator)op; // AUTH
- (void)searchLastValuesComparison:(TCSearchOperator)op; // AUTH
- (void)cancelSearch; // AUTH
- (void)clearSearch; // AUTH

- (void)getMemoryDump; // AUTH
- (void)cancelMemoryDump; // AUTH

- (void)makeVariableChanges:(NSArray *)variables repeat:(BOOL)doRepeat interval:(NSTimeInterval)repeatInterval; // AUTH
- (void)stopChangingVariables; // AUTH

- (void)undo; // AUTH
- (void)redo; // AUTH

- (void)watchVariablesAtIndex:(unsigned)index count:(unsigned)count interval:(NSTimeInterval)checkInterval; // AUTH
- (void)stopWatchingVariables; // AUTH

@end


// #############################################################################
@protocol CheaterDelegate
// #############################################################################

- (void)cheaterDidConnect:(Cheater *)cheater;
- (void)cheaterDidDisconnect:(Cheater *)cheater;

- (void)cheaterRequiresAuthentication:(Cheater *)cheater;
- (void)cheaterRejectedPassword:(Cheater *)cheater;
- (void)cheaterAcceptedPassword:(Cheater *)cheater;

- (void)cheater:(Cheater *)cheater didFindProcesses:(NSArray *)processes;
- (void)cheater:(Cheater *)cheater didAddProcess:(Process *)process;
- (void)cheater:(Cheater *)cheater didRemoveProcess:(Process *)process;

- (void)cheater:(Cheater *)cheater didSetTarget:(Process *)target;
- (void)cheaterPausedTarget:(Cheater *)cheater;
- (void)cheaterResumedTarget:(Cheater *)cheater;

- (void)cheater:(Cheater *)cheater didFindVariables:(TCArray)variables actualAmount:(unsigned)count;
- (void)cheater:(Cheater *)cheater didFindValues:(TCArray)values;
- (void)cheaterDidCancelSearch:(Cheater *)cheater;
- (void)cheaterDidClearSearch:(Cheater *)cheater;

- (void)cheater:(Cheater *)cheater didDumpMemory:(NSData *)memoryDump;
- (void)cheaterDidCancelMemoryDump:(Cheater *)cheater;

- (void)cheater:(Cheater *)cheater didChangeVariables:(unsigned)changeCount;
- (void)cheaterDidStopChangingVariables:(Cheater *)cheater;

- (void)cheater:(Cheater *)cheater didReportProgress:(int)progress;

- (void)cheater:(Cheater *)cheater didRevertToVariables:(TCArray)variables actualAmount:(unsigned)count;

- (void)cheaterDidUndo:(Cheater *)cheater;
- (void)cheaterDidRedo:(Cheater *)cheater;

- (void)cheater:(Cheater *)cheater variableAtIndex:(unsigned)index didChangeTo:(Variable *)variable;

- (void)cheater:(Cheater *)cheater didFailLastRequest:(NSString *)reason;
- (void)cheater:(Cheater *)cheater echo:(NSString *)message;

@end
