
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      CheatServer.h
// Created:   Sun Sep 07 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>
#import <Chaz/Chaz.h>

#import "ServerDelegate.h"

#include <mach/vm_map.h>
#include <mach/mach_traps.h>

#include <malloc/malloc.h>

#include <sys/types.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <unistd.h>

#include "cheat_types.h"
#include "cheat_net.h"


@class SearchResults;


@interface CheatServer : NSObject
{
	id					rootProxy;
	int					sockfd;

	pid_t				processID;
	vm_map_t			processTask;

	BOOL				processPaused;

	NSMutableArray		*searchResults;
	NSMutableArray		*searchResultsUndone;
	int					searchResultsAmountDisplayed;
}

+ (NSConnection *)serverWithDelegate:(id)delegate socket:(int)sock;
+ (void)serverThread:(NSArray *)array;

- (id)initWithRootProxy:(id)proxy;

- (void)handleSocket:(int)sock;
- (void)run;

- (void)setAddress:(NSString *)address;
- (void)setAction:(NSString *)action;

- (void)firstSearchString8bit:(char const *)value size:(int)vsize;
- (void)firstSearchIntegerChar:(int8_t)value;
- (void)firstSearchIntegerShort:(int16_t)value;
- (void)firstSearchIntegerLong:(int32_t)value;
- (void)firstSearchDecimalFloat:(float)value;
- (void)firstSearchDecimalDouble:(double)value;

- (void)searchString8bit:(char const *)value size:(int)vsize;
- (void)searchIntegerChar:(int8_t)value;
- (void)searchIntegerShort:(int16_t)value;
- (void)searchIntegerLong:(int32_t)value;
- (void)searchDecimalFloat:(float)value;
- (void)searchDecimalDouble:(double)value;

- (void)changeString8bit:(char const *)value size:(int)vsize addresses:(TCaddress *)addresses count:(int)count;
- (void)changeIntegerChar:(int8_t)value addresses:(TCaddress *)addresses count:(int)count;
- (void)changeIntegerShort:(int16_t)value addresses:(TCaddress *)addresses count:(int)count;
- (void)changeIntegerLong:(int32_t)value addresses:(TCaddress *)addresses count:(int)count;
- (void)changeDecimalFloat:(float)value addresses:(TCaddress *)addresses count:(int)count;
- (void)changeDecimalDouble:(double)value addresses:(TCaddress *)addresses count:(int)count;

- (void)sendProcessList;
- (void)sendSearchFinished;
- (void)sendVariableList:(TCaddress const *)data amount:(int)amount;
- (void)sendChangeFinished;
- (void)sendError:(NSString *)msg fatal:(BOOL)fatal;
- (void)sendVariableValue:(u_int32_t)index;
- (void)sendUndoFinished;
- (void)sendRedoFinished;
- (void)sendUndoRedoStatus;
- (void)sendAppLaunched:(NSDictionary *)appInfo;
- (void)sendAppQuit:(NSDictionary *)appInfo;
- (void)sendTargetAppQuit;
- (void)sendPauseFinished:(BOOL)paused;

- (void)handleClearSearch;
- (void)handleSearch:(char const *)data size:(int)dataSize;
- (void)handleChange:(char const *)data size:(int)dataSize;
- (void)handlePauseTarget;
- (void)handleUndo;
- (void)handleRedo;
- (void)handleSetTargetPID:(char const *)data size:(int)size;

- (void)unpause;
- (void)setPID:(pid_t)pid;

@end

