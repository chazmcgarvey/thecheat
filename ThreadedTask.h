
// 
// ThreadedTask 0.3
// Perform a long task without blocking the main thread.
// 
// Copyright (c) 2004-2005, Chaz McGarvey
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
// 3. Neither the name of the BrokenZipper nor the names of its contributors may be
// used to endorse or promote products derived from this software without specific
// prior written permission.
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
// Web:   http://www.brokenzipper.com/
// Email: chaz@brokenzipper.com
// 

#import <Cocoa/Cocoa.h>


@interface ThreadedTask : NSObject
{
	// task objects
	id _target;
	SEL _selector;
	int (*_function)(id, unsigned);
	id _context;
	// keeping track of things...
	BOOL _isTaskThreadRunning;
	BOOL _doCancelTask;
	// the delegate object
	id _delegate;
	NSRunLoop *_runloop;
	NSArray *_modes;
	// locks
	NSLock *_taskLock;
}

// #############################################################################
#pragma mark Initialization
// #############################################################################

/* See accessor methods for a description of the parameters. */
- (id)initWithTarget:(id)target selector:(SEL)selector delegate:(id)delegate;
- (id)initWithTarget:(id)target selector:(SEL)selector context:(id)context delegate:(id)delegate;
- (id)initWithFunction:(int (*)(ThreadedTask *, unsigned))function delegate:(id)delegate;
- (id)initWithFunction:(int (*)(ThreadedTask *, unsigned))function context:(id)context delegate:(id)delegate;


// #############################################################################
#pragma mark Accessor Methods
// #############################################################################

/*
 * As a protection, it is not possible to change the iteration method or function,
 * or the context while the task is running.
 */

/*
 * The target is the object (or class) that the selector is used on.  Target is
 * not retained.
 * 
 * The selector which should be used should be in this form:
 * 
 * - (int)task:(ThreadedTask *)task iteration:(unsigned)iteration;
 * 
 * The task parameter is the ThreadedTask object belonging to the task. 
 * The iteration parameter increases by one for each iteration that passes.
 * 
 * The return value is the important part.  It's what tells task object
 * whether to continue or stop or report a failure.  Here are the values:
 * 
 * Returning 1 means the task is not finished, and the iteration method
 * or function will be called again.
 * Returning 0 means the task is finished, and to end it.
 * Returning _anything_ else and the task will assume it is an error code;
 * the task would then abort and report the error code to the delegate.
 * 
 * The target and selector will be set to nil if either are not valid.
 */
- (id)target;
- (SEL)selector;
- (void)setTarget:(id)target selector:(SEL)selector;

/*
 * A function can be used instead of a target and selector.  The function
 * should be in the following form:
 * 
 * int MyTask( ThreadedTask *task, unsigned iteration );
 * 
 * The parameters and return value are the same as for the selector.  The
 * task uses the function if setFunction: was called after setTarget:, or
 * if setTarget: was never called.
 */

- (int (*)(id, unsigned))function;
- (void)setFunction:(int (*)(id, unsigned))function;

/*
 * The context of the threaded task can be any object.  It is set before
 * the task is run.  The iteration method/function can retrieve this
 * context from the task and use it to safely store results from the
 * task. The context can also be nil if the iteration doesn't need it.
 */
- (id)context;
- (void)setContext:(id)context;

/*
 * Delegation is how information is received from the task. Setting a
 * delegate isn't required, but it's pointless not to do so.  Unlike
 * the above accessors, the delegate can be changed while a task is running.
 * A runloop can also be specified which is used to send the delegate
 * methods using the given modes.  If no runloop is specified, the current
 * runloop for the thread which runs the threaded task is used.  Neither
 * the delegate or the runloop are retained, but the modes are.  If a
 * runloop is not specified and there is no current runloop, then no delegate
 * methods will be sent.  Pass nil for modes to use the mode of the current
 * runloop.
 */
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (void)setDelegateRunLoop:(NSRunLoop *)runloop modes:(NSArray *)modes;

/*
 * Returns YES if the thread is detached and the task is being performed.
 */
- (BOOL)isRunning;


// #############################################################################
#pragma mark Control Methods
// #############################################################################

/*
 * Begin execution of the task.  This method returns immediately.
 * The delegate will recieve threadedTaskFinished: when the task has completed
 * its purpose.  This method will return YES if the task was successfully
 * started, and NO if the task could not be run, which usually occurs if the
 * iteration method/selector or function is not valid.
 */
- (BOOL)run;

/*
 * General information about cancelling: If you release the ThreadedTask object
 * while a task is running, the task will be cancelled for you automatically
 * and this is generally safe to do, but the release may block the main thread
 * for a short amount of time while the task cancels.  This can be avoided by
 * using a cancel method below which doesn't block.
 */

/*
 * Signal the task to cancel prematurely.  This method will block until the
 * task actually does cancel.  It is safe to release the ThreadedTask object
 * any time after this call without blocking.  If the iteration method or
 * function is blocking for some reason, you should used a different cancel
 * method which doesn't block, otherwise a deadlock could occur.
 */
- (void)cancel;

/*
 * Signal the task to cancel prematurely.  This method returns immediately, but
 * you should not release the ThreadedTask object until the delegate receives
 * a conclusion method.
 */
- (void)cancelWithoutWaiting;

/*
 * Signal the task to cancel prematurely.  This is a convenience method that
 * sets the delegate to nil and cancels the task without blocking at the same
 * time.  This is useful if the delegate is going to be released while the task
 * is running.  You should not release the ThreadedTask object immediately
 * after this call, but you will also not receive any notification that it is
 * safe to do so.  You will know when receiver can be released without blocking
 * when the isRunning method returns NO.
 */
- (void)cancelAndRemoveDelegate;


// #############################################################################
#pragma mark Iteration Methods
// #############################################################################

/*
 * Report progress of the task back to the main thread.  This method should only
 * be called from the iteration method or function.  It takes a single integer
 * parameter which can be anything the receiver of the progress report will
 * understand (perhaps 0 thru 100, like as a percentage).
 */
- (void)reportProgress:(int)progress;

@end


@interface NSObject ( ThreadedTaskDelegate )

// #############################################################################
#pragma mark Delegate Methods
// #############################################################################

/*
 * These delegate methods are sent on the thread running the delegate runloop,
 * or the main runloop if none is specified.  It is typically safe to update
 * the user interface from these methods.
 */

/*
 * Sent to the delegate upon completion of the task.
 */
- (void)threadedTaskFinished:(ThreadedTask *)theTask;

/*
 * Sent to the delegate when the task has finished cancelling.
 */
- (void)threadedTaskCancelled:(ThreadedTask *)theTask;

/*
 * Sent to the delegate when the iteration returned an error.
 */
- (void)threadedTask:(ThreadedTask *)theTask failedWithErrorCode:(int)errorCode;

/*
 * Sent to the delegate to report the progress of the task.  This is a direct
 * result of the reportProgress: method being called from the iteration.
 */
- (void)threadedTask:(ThreadedTask *)theTask reportedProgress:(int)theProgress;

@end

