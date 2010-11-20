
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import <Cocoa/Cocoa.h>


@interface Process : NSObject < NSCopying, NSCoding >
{
	NSString *_name;
	NSString *_version;
	NSImage *_icon;
	pid_t _pid;
}

// initialization
- (id)initWithName:(NSString *)name version:(NSString *)version icon:(NSImage *)icon pid:(pid_t)pid;
- (id)initWithName:(NSString *)name version:(NSString *)version icon:(NSImage *)icon;
- (id)initWithName:(NSString *)name version:(NSString *)version;

// comparison
- (BOOL)sameApplicationAs:(id)anObject;

// accessors
- (BOOL)isEmulated;
- (NSString *)name;
- (NSString *)version;
- (NSImage *)icon;
- (pid_t)pid;

@end
