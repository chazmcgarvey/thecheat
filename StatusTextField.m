
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

#import "StatusTextField.h"


@interface StatusTextField ( Private )

- (void)doTimer:(NSTimer *)timer;

@end


@implementation StatusTextField


- (id)init
{
	if ( self = [super init] ) {
		myTimer = nil;
	}
	return self;
}

- (void)dealloc
{
	[myDefaultStatus release];
	[myTimer invalidate];
	[myTimer release];
	
	[super dealloc];
}


- (void)setDefaultStatus:(NSString *)message
{
	[self setDefaultStatus:message color:[NSColor blackColor]];
}

- (void)setDefaultStatus:(NSString *)message color:(NSColor *)color
{
	if ( !message ) {
		message = [NSString stringWithString:@""];
	}
	if ( !color ) {
		color = [NSColor blackColor];
	}
	// save the new values
	[message retain];
	[myDefaultStatus release];
	myDefaultStatus = message;
	// save the new values
	[color retain];
	[myDefaultColor release];
	myDefaultColor = color;
	// set the new default if there isn't already a temp showing
	if ( !myTimer ) {
		[self setStringValue:myDefaultStatus];
		[self setTextColor:myDefaultColor];
	}
}


- (void)setTemporaryStatus:(NSString *)message
{
	[self setTemporaryStatus:message color:[NSColor blackColor]];
}

- (void)setTemporaryStatus:(NSString *)message color:(NSColor *)color
{
	[self setTemporaryStatus:message color:color duration:4.0];
}

- (void)setTemporaryStatus:(NSString *)message duration:(NSTimeInterval)duration
{
	[self setTemporaryStatus:message color:[NSColor blackColor] duration:duration];
}

- (void)setTemporaryStatus:(NSString *)message color:(NSColor *)color duration:(NSTimeInterval)duration
{
	// stop any current temporary status
	[myTimer invalidate];
	[myTimer release];
	
	if ( !message ) {
		message = [NSString stringWithString:@""];
	}
	if ( !color ) {
		color = [NSColor blackColor];
	}
	// set the new temporary status
	[self setStringValue:message];
	[self setTextColor:color];
	// start the timer
	myTimer = [[NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(doTimer:) userInfo:nil repeats:NO] retain];
}


- (void)doTimer:(NSTimer *)timer
{
	// kill the timer
	[myTimer release];
	myTimer = nil;
	
	// set the default status
	if ( myDefaultStatus ) {
		[self setStringValue:myDefaultStatus];
	}
	if ( myDefaultColor ) {
		[self setTextColor:myDefaultColor];
	}
}


@end
