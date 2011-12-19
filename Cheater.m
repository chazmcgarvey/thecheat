
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import "LocalCheater.h"


@implementation Cheater


// #############################################################################
#pragma mark Initialization
// #############################################################################

- (id)initWithDelegate:(id)delegate
{
	if ( self = [self init] ) {
		// set the delegate
		[self setDelegate:delegate];
		ChazLog( @"init Cheater %p", self );
	}
	return self;
}

- (void)dealloc
{
	ChazLog( @"dealloc Cheater %p", self );
	[super dealloc];
}


- (id)delegate
{
	return _delegate;
}

- (void)setDelegate:(id)delegate
{
	// make sure the delegate is not nil and that it conforms to the CheaterDelegate
	if ( [delegate conformsToProtocol:@protocol(CheaterDelegate)] ) {
		_delegate = delegate;
	}
	else {
		_delegate = nil;
	}
}


- (BOOL)isConnected
{
	return _isConnected;
}

- (BOOL)isAuthenticated
{
	return _isAuthenticated;
}

- (NSString *)hostAddress
{
	return @"";
}


// #############################################################################
#pragma mark Cheating Control
// #############################################################################

- (void)connect
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)disconnect
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)authenticateWithPassword:(NSString *)password
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}


- (void)getProcessList
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}


- (void)setTarget:(Process *)target
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)pauseTarget
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)resumeTarget
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}


- (void)limitReturnedResults:(unsigned)limit
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)searchForVariable:(Variable *)data comparison:(TCSearchOperator)op
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)searchLastValuesComparison:(TCSearchOperator)op
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)cancelSearch
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)clearSearch
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)getMemoryDump
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)cancelMemoryDump
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}


- (void)makeVariableChanges:(NSArray *)variables repeat:(BOOL)doRepeat interval:(NSTimeInterval)repeatInterval
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)stopChangingVariables
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}


- (void)undo
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)redo
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}


- (void)watchVariablesAtIndex:(unsigned)index count:(unsigned)count interval:(NSTimeInterval)checkInterval
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}

- (void)stopWatchingVariables
{
	[NSException raise:@"TCNotImplemented" format:@"The subclass of Cheater (%@) needs to implement selector %@.",
		NSStringFromClass(isa),
		NSStringFromSelector(_cmd)];
}


@end
