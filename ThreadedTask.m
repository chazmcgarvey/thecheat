
// 
// ThreadedTask 0.3
// Perform a long task without blocking the main thread.
// 
// Copyright (c) 2004-2005, Charles McGarvey
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this list
// of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice, this
// list of conditions and the following disclaimer in the documentation and/or other
// materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
// SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
// TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
// ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 

#import "ThreadedTask.h"

#import <objc/objc-runtime.h>


@interface ThreadedTask ( PrivateAPI )

/* private initialization: designated initializer */
- (id)_initWithContext:(id)context delegate:(id)delegate;
/* task method */
- (void)_runTask:(NSArray *)package;
/* sent to the main thread to report task progress */
- (void)_taskReportProgress:(NSNumber *)progress;
/* sent to the main thread to report a cancellation */
- (void)_taskDidCancel:(id)dummy;
/* sent to the main thread to report a completion */
- (void)_taskDidFinish:(id)dummy;
/* sent to the main thread to report a failure */
- (void)_taskDidFailWithErrorCode:(NSNumber *)errorCode;

@end


@implementation ThreadedTask


// #############################################################################
#pragma mark Initialization
// #############################################################################

- (id)init
{
	return [self initWithTarget:nil selector:nil context:nil delegate:nil];
}

- (id)_initWithContext:(id)context delegate:(id)delegate // DESIGNATED
{
	if ( self = [super init] ) {
		[self setContext:context];
		[self setDelegate:delegate];
		// create objects
		_taskLock = [[NSLock alloc] init];
	}
	return self;
}

- (id)initWithTarget:(id)target selector:(SEL)selector delegate:(id)delegate
{
	return [self initWithTarget:target selector:selector context:nil delegate:delegate];
}

- (id)initWithTarget:(id)target selector:(SEL)selector context:(id)context delegate:(id)delegate
{
	if ( (self = [self _initWithContext:context delegate:delegate]) ) {
		// set initial values
		[self setTarget:target selector:selector];
	}
	return self;
}

- (id)initWithFunction:(int (*)(ThreadedTask *, unsigned))function delegate:(id)delegate
{
	return [self initWithFunction:function context:nil delegate:delegate];
}

- (id)initWithFunction:(int (*)(ThreadedTask *, unsigned))function context:(id)context delegate:(id)delegate
{
	if ( (self = [self _initWithContext:context delegate:delegate]) ) {
		// set initial values
		[self setFunction:function];
	}
	return self;
}

- (void)dealloc
{
	// cancel any running task
	[self cancel];
	[_taskLock release];
	// release retained objects
	[_context release];
	[_modes release];

	[super dealloc];
}


// #############################################################################
#pragma mark Accessor Methods
// #############################################################################

- (id)target
{
	return _target;
}

- (SEL)selector
{
	return _selector;
}

- (void)setTarget:(id)target selector:(SEL)selector
{
	// don't do anything if the task is running
	if ( [self isRunning] ) {
		return;
	}
	
	if ( [target respondsToSelector:selector] ) {
		// target & selector look good, save them
		_target = target;
		_selector = selector;
		_function = NULL;
	}
	else {
		// bad target and/or selector, use nil
		_target = nil;
		_selector = NULL;
	}
}


- (int (*)(id, unsigned))function
{
	return _function;
}

- (void)setFunction:(int (*)(id, unsigned))function
{
	// don't do anything if the task is running
	if ( [self isRunning] ) {
		return;
	}
	
	_function = function;
	if ( _function ) {
		_target = nil;
		_selector = NULL;
	}
}


- (id)context
{
	return _context;
}

- (void)setContext:(id)context
{
	// don't do anything if the task is running
	if ( [self isRunning] ) {
		return;
	}
	
	[context retain];
	[_context release];
	_context = context;
}


- (id)delegate
{
	return _delegate;
}

- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}

- (void)setDelegateRunLoop:(NSRunLoop *)runloop modes:(NSArray *)modes
{
	_runloop = runloop;
	[modes retain];
	[_modes release];
	_modes = modes;
}


- (BOOL)isRunning
{
	return _isTaskThreadRunning;
}


// #############################################################################
#pragma mark Control Methods
// #############################################################################

- (BOOL)run
{
	// don't run if there is no iteration method/function to call
	if ( [self isRunning] || (!_target && !_function) ) {
		return NO;
	}

	// set initial values
	_doCancelTask = NO;
	
	if ( !_runloop ) {
		// use the default runloop
		NSRunLoop *current = [NSRunLoop currentRunLoop];
		if ( !_modes ) {
			NSString *currentMode = [current currentMode];
			NSArray *modes = currentMode? [NSArray arrayWithObject:currentMode]
				: [NSArray arrayWithObjects:NSDefaultRunLoopMode,NSModalPanelRunLoopMode,NSEventTrackingRunLoopMode,NSConnectionReplyMode,nil];
			[self setDelegateRunLoop:current modes:modes];
		}
		else {
			[self setDelegateRunLoop:current modes:_modes];
		}
	}
	
	// start the task thread!
	_isTaskThreadRunning = YES;
    [NSThread detachNewThreadSelector:@selector(_runTask:) toTarget:self withObject:nil];
	return YES;
}

- (void)cancel
{
	if ( [self isRunning] ) {
		_doCancelTask = YES;
		// this blocks until the task thread exits.
		[_taskLock lock];
		[_taskLock unlock];
	}
}

- (void)cancelWithoutWaiting
{
	_doCancelTask = YES;
}

- (void)cancelAndRemoveDelegate
{
	[self setDelegate:nil];
	[self cancelWithoutWaiting];
}


// #############################################################################
#pragma mark Task Methods
// #############################################################################

- (void)reportProgress:(int)progress
{
	//[_runloop performSelector:@selector(_taskReportProgress:) target:self
	//				 argument:[[NSNumber alloc] initWithInt:progress] order:0 modes:_modes];
	[self performSelectorOnMainThread:@selector(_taskReportProgress:)
						   withObject:[[NSNumber alloc] initWithInt:progress] waitUntilDone:NO];
}


// #############################################################################
#pragma mark Private Methods
// #############################################################################

- (void)_runTask:(NSArray *)package
{
	NSAutoreleasePool *pool;

	unsigned iteration;
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
	NSInteger returnCode;
#else
	int returnCode;
#endif

	// create the ever-so-important pool
    pool = [[NSAutoreleasePool alloc] init];
	
	// set the lock the tells the main thread the task thread is running
	[_taskLock lock];
	
	// set first iteration
	iteration = 0;
	returnCode = 1;

	// enter the task loop
	if ( _target ) {
		while ( !_doCancelTask && returnCode == 1 ) {
			NSAutoreleasePool *loopPool;
			
			// do the actual work
			loopPool = [[NSAutoreleasePool alloc] init];
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
			returnCode = (NSInteger)objc_msgSend( _target, _selector, self, iteration );
#else
			returnCode = (int)objc_msgSend( _target, _selector, self, iteration );
#endif
			[loopPool release];
			
			iteration++;
		}
	}
	else if ( _function ) {
		while ( !_doCancelTask && returnCode == 1 ) {
			NSAutoreleasePool *loopPool;
			
			// do the actual work
			loopPool = [[NSAutoreleasePool alloc] init];
			returnCode = (int)_function( self, iteration );
			[loopPool release];
			
			iteration++;
		}
	}
	
	if ( _doCancelTask ) {
		// report cancel
		//[_runloop performSelector:@selector(_taskDidCancel:) target:self argument:nil order:iteration modes:_modes];
		[self performSelectorOnMainThread:@selector(_taskDidCancel:) withObject:nil waitUntilDone:NO];
	}
	else if ( returnCode == 0 ) {
		// report task completed
		//[_runloop performSelector:@selector(_taskDidFinish:) target:self argument:nil order:iteration modes:_modes];
		[self performSelectorOnMainThread:@selector(_taskDidFinish:) withObject:nil waitUntilDone:NO];
	}
	else {
		// report error
		[_runloop performSelector:@selector(_taskDidFailWithErrorCode:) target:self
						 argument:[[NSNumber alloc] initWithInt:returnCode] order:iteration modes:_modes];
		//[self performSelectorOnMainThread:@selector(_taskDidFailWithErrorCode:)
		//					   withObject:[[NSNumber alloc] initWithInt:returnCode] waitUntilDone:NO];
	}
	
	// allow the main thread to continue if it was blocking
	_isTaskThreadRunning = NO;
	[_taskLock unlock];
	
    [pool release];
}


- (void)_taskReportProgress:(NSNumber *)progress
{
	if ( [_delegate respondsToSelector:@selector(threadedTask:reportedProgress:)] ) {
		[_delegate threadedTask:self reportedProgress:[progress intValue]];
	}
	[progress release];
}

- (void)_taskDidCancel:(id)dummy
{
	if ( [_delegate respondsToSelector:@selector(threadedTaskCancelled:)] ) {
		[_delegate threadedTaskCancelled:self];
	}
}

- (void)_taskDidFinish:(id)dummy
{
	if ( [_delegate respondsToSelector:@selector(threadedTaskFinished:)] ) {
		[_delegate threadedTaskFinished:self];
	}
}

- (void)_taskDidFailWithErrorCode:(NSNumber *)errorCode
{
	if ( [_delegate respondsToSelector:@selector(threadedTask:failedWithErrorCode:)] ) {
		[_delegate threadedTask:self failedWithErrorCode:[errorCode intValue]];
	}
	[errorCode release];
}


@end
