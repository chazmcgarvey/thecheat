
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

#import "LocalCheater.h"

#include "cheat_global.h"


// memory dump function
int _MemoryDumpTask( ThreadedTask *task, unsigned iteration );


@interface LocalCheater ( Private )

// internal methods so they can be used throughout the class
- (void)_clearSearch;
- (BOOL)_pauseTarget; // returns TRUE for success
- (BOOL)_resumeTarget; // returns TRUE for success
// handling app launching/quitting
- (void)_applicationLaunched:(NSNotification *)note;
- (void)_applicationTerminated:(NSNotification *)note;
// cheating
- (unsigned)_doChange:(NSArray *)variables;
- (void)_changeTimer:(NSTimer *)timer;
// watch variables
- (void)_doWatch;
- (void)_watchTimer:(NSTimer *)timer;
// tasks
- (int)_memoryDumpTask:(ThreadedTask *)task iteration:(unsigned)iteration;

@end


@implementation LocalCheater


- (id)init
{
	if ( self = [super init] ) {
		NSNotificationCenter *nc= [[NSWorkspace sharedWorkspace] notificationCenter];
		
		// register for app launch/quit notifications
		[nc addObserver:self selector:@selector(_applicationLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
		[nc addObserver:self selector:@selector(_applicationTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
		
		_searchResults = [[NSMutableArray alloc] init];
		_savedResults = [[NSMutableArray alloc] init];
		_returnLimit = -1;
	}
	return self;
}

- (void)dealloc
{
	[(NSNotificationCenter *)[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	
	// make sure the process isn't left paused
	[self _resumeTarget];
	
	// release local objects
	[_target release];
	[self _clearSearch];
	
	// make sure everything is cancelled.
	[_searchTask cancelAndRemoveDelegate];
	[_dumpTask cancelAndRemoveDelegate];
	[self stopChangingVariables];
	[self stopWatchingVariables];
	
	[_searchTask release];
	[_dumpTask release];
	
	[_processes release];
	
	[super dealloc];	
}


- (BOOL)shouldCopy
{
	return _shouldCopy;
}

- (void)setShouldCopy:(BOOL)flag
{
	_shouldCopy = flag;
}


- (NSString *)hostAddress
{
	//return @"127.0.0.1";
	return @"this computer";
}


// #############################################################################
#pragma mark Cheater Override
// #############################################################################

- (void)connect
{
	if ( !_isConnected ) {
		_isConnected = YES;
		// return as connected
		[_delegate cheaterDidConnect:self];
	}
}

- (void)disconnect
{
	if ( _isConnected ) {
		[_searchTask cancelAndRemoveDelegate];
		[_dumpTask cancelAndRemoveDelegate];
		[self stopChangingVariables];
		[self stopWatchingVariables];

		_isConnected = NO;
		// return as disconnected
		//[_delegate cheaterDidDisconnect:self];
	}
}

- (void)authenticateWithPassword:(NSString *)password
{
	// being a local cheater, authentication really isn't required.
	// return succes every time.
	_isAuthenticated = YES;
	[_delegate cheaterAcceptedPassword:self];
}


- (void)getProcessList
{
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSArray *launchedApps = [workspace launchedApplications];
	unsigned i, len = [launchedApps count];
	
	if ( !_processes ) {
		_processes = [[NSMutableArray alloc] initWithCapacity:len];
	}
	
	// compile process array
	for ( i = 0; i < len; i++ ) {
		NSDictionary *application = [launchedApps objectAtIndex:i];
		
		// don't allow The Cheat to be cheated
		if ( [[application objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]] ) {
			continue;
		}
		
		Process *process = [[Process alloc] initWithName:[application objectForKey:@"NSApplicationName"]
												 version:ApplicationVersion( [application objectForKey:@"NSApplicationPath"] )
													icon:[workspace iconForFile:[application objectForKey:@"NSApplicationPath"]]
													 pid:[[application objectForKey:@"NSApplicationProcessIdentifier"] intValue]];
		[_processes addObject:process];
		[process release];
	}
	
	// return process list
	[_delegate cheater:self didFindProcesses:[NSArray arrayWithArray:_processes]];
}


- (void)setTarget:(Process *)target
{
	// unpause the current target if needed
	[self resumeTarget];
	// clear the search
	[self clearSearch];
	// set the new target
	[_target release];
	
	if ( _shouldCopy ) {
		_target = [target copy];
		[_delegate cheater:self didSetTarget:[_target copy]];
	}
	else {
		_target = [target retain];
		[_delegate cheater:self didSetTarget:_target];
	}
}

- (void)pauseTarget
{
	// attempt to pause the current target
	if ( !_isTargetPaused && [self _pauseTarget] ) {
		[_delegate cheaterPausedTarget:self];
	}
	else {
		[_delegate cheater:self echo:@"This process cannot be paused."];
	}
}

- (void)resumeTarget
{
	// attempt to resume the current target
	if ( _isTargetPaused && [self _resumeTarget] ) {
		[_delegate cheaterResumedTarget:self];
	}
	else {
		[_delegate cheater:self echo:@"This process cannot be resumed."];
	}
}


- (void)limitReturnedResults:(unsigned)limit
{
	_returnLimit = limit;
}

- (void)searchForVariable:(Variable *)var comparison:(TCSearchOperator)op
{
	SearchContext *context;
	void *function;
	
	if ( _searchTask ) {
		ChazLog( @"there is already a search task" );
		return;
	}
	
	if ( [_searchResults count] > 0 ) {
		SearchContext *lastContext = [_searchResults lastObject];
		if ( ([var type] == TCString) && ([lastContext->value valueSize] < [var valueSize]) ) {
			// string size not good
			[_delegate cheater:self didFailLastRequest:@"String is too long."];
			return;
		}
		context = [[SearchContext alloc] initWithLastContext:[_searchResults lastObject]  searchOperator:op value:var];
	}
	else {
		context = [[SearchContext alloc] initWithPID:[_target pid] searchOperator:op value:var];
	}
	
	function = [context iterationFunction];
	if ( function ) {
		_searchTask = [[ThreadedTask alloc] initWithFunction:function
													 context:context
													delegate:self];
		
		if ( ![_searchTask run] ) {
			// task didn't run
			[_searchTask release];
			_searchTask = nil;
			[_delegate cheater:self didFailLastRequest:@"Internal error."];
		}
	}
	else {
		[_delegate cheater:self didFailLastRequest:@"Invalid search parameters."];
	}
	
	[context release];
}


- (void)searchLastValuesComparison:(TCSearchOperator)op
{
	SearchContext *context;
	void *function;
	
	if ( _searchTask ) {
		ChazLog( @"there is already a search task" );
		return;
	}
	
	if ( [_searchResults count] > 0 ) {
		context = [[SearchContext alloc] initWithLastContext:[_searchResults lastObject]  searchOperator:op];
	}
	else {
		ChazLog( @"doing a searchLastValues search without previous results..." );
		[_delegate cheater:self didFailLastRequest:@"Invalid search."];
		return;
	}
	
	function = [context iterationFunction];
	if ( function ) {
		_searchTask = [[ThreadedTask alloc] initWithFunction:function
													 context:context
													delegate:self];
		
		if ( ![_searchTask run] ) {
			// task didn't run
			[_searchTask release];
			_searchTask = nil;
			[_delegate cheater:self didFailLastRequest:@"Internal error."];
		}
	}
	else {
		[_delegate cheater:self didFailLastRequest:@"Invalid search parameters."];
	}
	
	[context release];
}

- (void)cancelSearch
{
	[_searchTask cancelWithoutWaiting];
}

- (void)clearSearch
{
	[self _clearSearch];
	[_delegate cheaterDidClearSearch:self];
}


- (void)getMemoryDump
{
	if ( _dumpTask ) {
		ChazLog( @"there is already a dump task" );
		return;
	}
	
	_dumpTask = [[ThreadedTask alloc] initWithFunction:_MemoryDumpTask
											 context:[[[DumpContext alloc] initWithPID:[_target pid]] autorelease]
											delegate:self];
	
	if ( ![_dumpTask run] ) {
		[_dumpTask release];
		_dumpTask = nil;
		[_delegate cheater:self didFailLastRequest:@"Internal error."];
	}
}

int _MemoryDumpTask( ThreadedTask *task, unsigned iteration )
{
	DumpContext *context = [task context];
	VMRegion region = VMNextRegionWithAttributes( context->process, context->lastRegion, VMREGION_READABLE );
	
	if ( VMRegionIsNotNull( region ) ) {
		[context->dump appendData:VMRegionData( region )];
		
		context->lastRegion = region;
		
		// continue looping
		return 1;
	}
	else {
		// no more regions, exit
		return 0;
	}
}

- (void)cancelMemoryDump
{
	[_dumpTask cancelWithoutWaiting];
}


- (void)makeVariableChanges:(NSArray *)variables repeat:(BOOL)doRepeat interval:(NSTimeInterval)repeatInterval
{
	unsigned changes;
	
	[self stopChangingVariables];
	
	// repeat the changes if necessary
	if ( doRepeat ) {
		if ( _shouldCopy ) {
			_cheatVariables = [variables copy];
		}
		else {
			_cheatVariables = [variables retain];
		}
		_cheatTimer = [[NSTimer scheduledTimerWithTimeInterval:repeatInterval
														target:self
													  selector:@selector(_changeTimer:)
													  userInfo:nil
													   repeats:YES] retain];
		[[NSRunLoop currentRunLoop] addTimer:_cheatTimer forMode:NSEventTrackingRunLoopMode];
		[[NSRunLoop currentRunLoop] addTimer:_cheatTimer forMode:NSModalPanelRunLoopMode];
	}
	
	// change variables
	changes = [self _doChange:variables];
	[_delegate cheater:self didChangeVariables:changes];
}

- (void)stopChangingVariables
{
	if ( _cheatVariables ) {
		[_cheatTimer invalidate];
		[_cheatTimer release];
		_cheatTimer = nil;
		[_cheatVariables release];
		_cheatVariables = nil;
		
		// report back to delegate
		[_delegate cheaterDidStopChangingVariables:self];
	}
}


- (void)undo
{
	SearchContext *searchContext;
	TCArray variables;
	TCArray values;
	
	if ( searchContext = [_searchResults lastObject] ) {
		[_savedResults addObject:searchContext];
		[_searchResults removeLastObject];
		
		[self stopWatchingVariables];

		if ( searchContext = [_searchResults lastObject] ) {
			if ( _shouldCopy ) {
				variables = TCArrayCopyElements( searchContext->addresses, _returnLimit );
				values = TCArrayCopyElements( searchContext->values, _returnLimit );
			}
			else {
				variables = TCArrayCopyContainer( searchContext->addresses, _returnLimit );
				values = TCArrayCopyContainer( searchContext->values, _returnLimit );
			}
			
			[_delegate cheater:self didRevertToVariables:variables actualAmount:TCArrayElementCount( searchContext->addresses )];
			[_delegate cheater:self didFindValues:values];
		}
		
		[_delegate cheaterDidUndo:self];
	}
}

- (void)redo
{
	SearchContext *searchContext;
	TCArray variables;
	TCArray values;
	
	[self stopWatchingVariables];
	
	if ( searchContext = [_savedResults lastObject] ) {
		[_searchResults addObject:searchContext];
		[_savedResults removeLastObject];
		
		if ( _shouldCopy ) {
			variables = TCArrayCopyElements( searchContext->addresses, _returnLimit );
			values = TCArrayCopyElements( searchContext->values, _returnLimit );
		}
		else {
			variables = TCArrayCopyContainer( searchContext->addresses, _returnLimit );
			values = TCArrayCopyContainer( searchContext->values, _returnLimit );
		}
		
		[_delegate cheater:self didRevertToVariables:variables actualAmount:TCArrayElementCount( searchContext->addresses )];
		[_delegate cheater:self didFindValues:values];
		[_delegate cheaterDidRedo:self];
	}
}


- (void)watchVariablesAtIndex:(unsigned)index count:(unsigned)count interval:(NSTimeInterval)checkInterval
{
	SearchContext *context;
	unsigned i, top;
	
	ChazLog( @"watchVariablesAtIndex:.." );
	
	[self stopWatchingVariables];
	
	if ( count == 0 ) {
		ChazLog( @"invalid watch parameters: 0 count" );
		return;
	}
	
	if ( context = [_searchResults lastObject] ) {
		TCArray addresses = context->addresses;
		TCArray values = context->values;
		// check the index & count
		if ( index + count <= TCArrayElementCount( addresses ) ) {
			// save current values
			NSMutableArray *vars = [[NSMutableArray alloc] initWithCapacity:count];
			top = index + count;
			for ( i = index; i < top; i++ ) {
				Variable *var = [[Variable alloc] initWithType:[context variableType] integerSign:[context integerSign]];
				[var setAddress:*(TCAddress *)TCArrayElementAtIndex( addresses, i )];
				[var setValue:TCArrayElementAtIndex( values, i ) size:TCArrayElementSize(values)];
				[vars addObject:var];
				[var release];
			}
			_watchVariables = [[NSArray arrayWithArray:vars] retain];
			[vars release];
			
			_watchRange = NSMakeRange( index, count );
			_watchTimer = [[NSTimer scheduledTimerWithTimeInterval:checkInterval
															target:self
														  selector:@selector(_watchTimer:)
														  userInfo:nil
														   repeats:YES] retain];
			[[NSRunLoop currentRunLoop] addTimer:_watchTimer forMode:NSEventTrackingRunLoopMode];
			[[NSRunLoop currentRunLoop] addTimer:_watchTimer forMode:NSModalPanelRunLoopMode];
			
			// do a watch check right now
			[self _doWatch];
		}
		else {
			ChazLog( @"invalid watch parameters" );
		}
	}
}

- (void)stopWatchingVariables
{
	if ( _watchVariables ) {
		[_watchTimer invalidate];
		[_watchTimer release];
		_watchTimer = nil;
		[_watchVariables release];
		_watchVariables = nil;
	}
}


// #############################################################################
#pragma mark ThreadedTaskDelegate
// #############################################################################

- (void)threadedTaskFinished:(ThreadedTask *)theTask
{
	id context = [theTask context];
	
	[self stopWatchingVariables];
	
	ChazLog( @"threaded task finished" );
	
	if ( [context isKindOfClass:[SearchContext class]] ) {
		SearchContext *searchContext = context;
		TCArray variables;
		TCArray values;
		
		if ( _shouldCopy ) {
			variables = TCArrayCopyElements( searchContext->addresses, _returnLimit );
			values = TCArrayCopyElements( searchContext->values, _returnLimit );
		}
		else {
			variables = TCArrayCopyContainer( searchContext->addresses, _returnLimit );
			values = TCArrayCopyContainer( searchContext->values, _returnLimit );
		}
		
		[_searchResults addObject:searchContext];
		[_searchTask release];
		_searchTask = nil;
		
		[_delegate cheater:self didFindVariables:variables actualAmount:TCArrayElementCount( searchContext->addresses )];
		[_delegate cheater:self didFindValues:values];
	}
	else if ( [context isKindOfClass:[DumpContext class]] ) {
		DumpContext *dumpContext = context;
		[_delegate cheater:self didDumpMemory:dumpContext->dump];
		[_dumpTask release];
		_dumpTask = nil;
	}
}

- (void)threadedTaskCancelled:(ThreadedTask *)theTask
{
	id context = [theTask context];
	ChazLog( @"threaded task cancelled" );
	
	if ( [context isKindOfClass:[SearchContext class]] ) {
		[_delegate cheaterDidCancelSearch:self];
		[_searchTask release];
		_searchTask = nil;
	}
	else if ( [context isKindOfClass:[DumpContext class]] ) {
		[_delegate cheaterDidCancelMemoryDump:self];
		[_dumpTask release];
		_dumpTask = nil;
	}
}

- (void)threadedTask:(ThreadedTask *)theTask failedWithErrorCode:(int)errorCode
{
	id context = [theTask context];
	ChazLog( @"threaded task failed with code: %i", errorCode );
	
	if ( [context isKindOfClass:[SearchContext class]] ) {
		[_delegate cheater:self didFailLastRequest:[NSString stringWithFormat:@"Search failed with error: %i", errorCode]];
		[_searchTask release];
		_searchTask = nil;
	}
	else if ( [context isKindOfClass:[DumpContext class]] ) {
		[_delegate cheater:self didFailLastRequest:[NSString stringWithFormat:@"Dump failed with error: %i", errorCode]];
		[_dumpTask release];
		_dumpTask = nil;
	}
}

- (void)threadedTask:(ThreadedTask *)theTask reportedProgress:(int)theProgress
{
	[_delegate cheater:self didReportProgress:theProgress];
}


// #############################################################################
#pragma mark Private Methods
// #############################################################################

- (void)_clearSearch
{
	[self stopWatchingVariables];
	[self cancelSearch];
	
	// empty the results array
	[_searchResults removeAllObjects];
	[_savedResults removeAllObjects];
}

- (BOOL)_pauseTarget
{
	// attempt to pause
	if ( VMStopProcess( [_target pid] ) ) {
		_isTargetPaused = YES;
		return YES;
	}
	_isTargetPaused = NO;
	return NO;
}

- (BOOL)_resumeTarget
{
	if ( VMContinueProcess( [_target pid] ) ) {
		_isTargetPaused = NO;
		return YES;
	}
	_isTargetPaused = YES;
	return NO;
}


- (void)_applicationLaunched:(NSNotification *)note
{
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSDictionary *application = [note userInfo];
	NSString *bundleID;

	// don't allow The Cheat to be cheated
	bundleID = [application objectForKey:@"NSApplicationBundleIdentifier"];
	if ( bundleID && [bundleID isEqualToString:[[NSBundle mainBundle] bundleIdentifier]] ) {
		return;
	}
	
	Process *process = [[Process alloc] initWithName:[application objectForKey:@"NSApplicationName"]
											 version:ApplicationVersion( [application objectForKey:@"NSApplicationPath"] )
												icon:[workspace iconForFile:[application objectForKey:@"NSApplicationPath"]]
												 pid:[[application objectForKey:@"NSApplicationProcessIdentifier"] intValue]];
	if ( ![_processes containsObject:process] ) {
		[_processes addObject:process];
		// inform the delegate of the new process
		[_delegate cheater:self didAddProcess:process];
	}
	// cleanup
	[process release];
}

- (void)_applicationTerminated:(NSNotification *)note
{
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSDictionary *application = [note userInfo];
	
	Process *process = [[Process alloc] initWithName:[application objectForKey:@"NSApplicationName"]
											 version:ApplicationVersion( [application objectForKey:@"NSApplicationPath"] )
												icon:[workspace iconForFile:[application objectForKey:@"NSApplicationPath"]]
												 pid:[[application objectForKey:@"NSApplicationProcessIdentifier"] intValue]];
	
	// if this is the current process, take appropriate actions
	if ( [_target isEqual:process] ) {
		[self cancelSearch];
		[self clearSearch];
		[self cancelMemoryDump];
		[self stopChangingVariables];
		[_delegate cheater:self didRemoveProcess:process];
		[_delegate cheater:self didFailLastRequest:@"The target quit."];
	}
	else {
		// inform the delegate of the removed process
		[_delegate cheater:self didRemoveProcess:process];
	}
	[_processes removeObject:process];
	
	// cleanup
	[process release];
}


- (unsigned)_doChange:(NSArray *)variables
{
	unsigned i, top;
	unsigned successes = 0;
	
	top = [variables count];
	for ( i = 0; i < top; i++ ) {
		Variable *variable = [variables objectAtIndex:i];
		
		if ( VMWriteBytes( [_target pid], [variable address], [variable value], [variable valueSize] ) ) {
			successes++;
		}
	}
	return successes;
}

- (void)_changeTimer:(NSTimer *)timer
{
	unsigned changes = [self _doChange:_cheatVariables];
	[_delegate cheater:self didChangeVariables:changes];
}


- (void)_doWatch
{
	unsigned i, top;
	char value[TC_MAX_VAR_SIZE];
	vm_size_t size;
	
	top = [_watchVariables count];
	for ( i = 0; i < top; i++ ) {
		Variable *variable = [_watchVariables objectAtIndex:i];
		
		size = [variable valueSize];
		if ( VMReadBytes( [_target pid], [variable address], value, &size ) ) {
			// check if memory changed
			if ( memcmp( value, [variable value], size ) != 0 ) {
				[variable setValue:value];
				// inform delegate of the change
				[_delegate cheater:self variableAtIndex:_watchRange.location+i didChangeTo:variable];
			}
		}
	}
}

- (void)_watchTimer:(NSTimer *)timer
{
	[self _doWatch];
}


@end
