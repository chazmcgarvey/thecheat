//
//  FadeView.h
//  The Cheat
//
//  Created by Chaz McGarvey on 12/6/04.
//  Copyright 2004 Chaz McGarvey. All rights reserved.
//

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