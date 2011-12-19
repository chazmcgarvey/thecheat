
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


@interface FadeView : NSView
{
	NSImage *_fadeImage;
	double _fadeAlpha;
	
	NSTimeInterval _fadeDuration;
	NSTimeInterval _fadeInterval;
	NSTimer *_fadeTimer;
	
	id _delegate;
}

- (NSImage *)image;
- (NSTimeInterval)fadeDuration;
- (NSTimeInterval)fadeInterval;
- (double)alpha;

- (void)setImage:(NSImage *)image;
- (void)setFadeDuration:(NSTimeInterval)seconds;
- (void)setFadeInterval:(NSTimeInterval)seconds;

- (void)startFadeAnimation;
- (void)stopFadeAnimation;

- (id)delegate;
- (void)setDelegate:(id)delegate;

@end


@interface NSObject ( FadeViewDelegate )

- (void)fadeViewFinishedAnimation:(FadeView *)theView;

@end
