
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
