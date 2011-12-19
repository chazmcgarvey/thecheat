
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "FadeView.h"


@interface FadeView ( PrivateAPI )

- (void)_fadeTimer:(NSTimer *)timer;

@end


@implementation FadeView


- (id)init
{
	if ( self = [super init] ) {
		[self setFadeDuration:1.0];
		[self setFadeInterval:5.0/60.0];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ( self = [super initWithFrame:frame] ) {
		[self setFadeDuration:1.0];
		[self setFadeInterval:5.0/60.0];
	}
	return self;
}

- (void)dealloc
{
	[self stopFadeAnimation];
	[_fadeImage release];
	[super dealloc];
}


- (void)drawRect:(NSRect)rect
{
    [_fadeImage dissolveToPoint:NSMakePoint(0,0) fraction:_fadeAlpha];
}


- (NSImage *)image
{
	return _fadeImage;
}

- (NSTimeInterval)fadeDuration
{
	return _fadeDuration;
}

- (NSTimeInterval)fadeInterval
{
	return _fadeInterval;
}

- (double)alpha
{
	return _fadeAlpha;
}


- (void)setImage:(NSImage *)image
{
	[image retain];
	[_fadeImage release];
	_fadeImage = image;
}

- (void)setFadeDuration:(NSTimeInterval)seconds
{
	if ( seconds != 0.0 ) {
		_fadeDuration = seconds;
	}
	else {
		_fadeDuration = 1.0;
	}
}

- (void)setFadeInterval:(NSTimeInterval)seconds
{
	_fadeInterval = seconds;
}

- (void)startFadeAnimation
{
	[self stopFadeAnimation];
	
	_fadeAlpha = 1.0;
	[self setNeedsDisplay:YES];
	
	_fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:_fadeInterval target:self selector:@selector(_fadeTimer:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:_fadeTimer forMode:NSEventTrackingRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:_fadeTimer forMode:NSModalPanelRunLoopMode];
	[self release];
}

- (void)stopFadeAnimation
{
	if ( _fadeTimer ) {
		[self retain];
		[_fadeTimer invalidate];
		[_fadeTimer release];
		_fadeTimer = nil;
	}
}

- (void)_fadeTimer:(NSTimer *)timer
{
	_fadeAlpha -= [timer timeInterval] / _fadeDuration;
	[self setNeedsDisplay:YES];
	
	if ( _fadeAlpha <= 0.0 ) {
		[self stopFadeAnimation];
		if ( [_delegate respondsToSelector:@selector(fadeViewFinishedAnimation:)] ) {
			[_delegate fadeViewFinishedAnimation:self];
		}
	}
}


- (id)delegate
{
	return _delegate;
}

- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}


@end
