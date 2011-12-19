
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
