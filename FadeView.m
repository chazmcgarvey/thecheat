//
//  FadeView.m
//  The Cheat
//
//  Created by Chaz McGarvey on 12/6/04.
//  Copyright 2004 Chaz McGarvey. All rights reserved.
//

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
