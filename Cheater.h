
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
