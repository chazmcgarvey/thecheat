
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


@interface StatusTextField : NSTextField
{
	NSString *myDefaultStatus;
	NSColor *myDefaultColor;
	
	NSTimer *myTimer;
}

- (void)setDefaultStatus:(NSString *)message; // defaults to black
- (void)setDefaultStatus:(NSString *)message color:(NSColor *)color;

- (void)setTemporaryStatus:(NSString *)message; // defaults to black
- (void)setTemporaryStatus:(NSString *)message color:(NSColor *)color; // defaults to 4 seconds
- (void)setTemporaryStatus:(NSString *)message duration:(NSTimeInterval)duration;
- (void)setTemporaryStatus:(NSString *)message color:(NSColor *)color duration:(NSTimeInterval)duration;

@end
