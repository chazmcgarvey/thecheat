
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
