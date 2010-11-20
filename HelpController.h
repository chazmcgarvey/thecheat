
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
#import <WebKit/WebKit.h>
#import "ChazLog.h"


@interface HelpController : NSWindowController
{
	IBOutlet NSWindow		*helpWindow;
	IBOutlet WebView		*webView;
}

@end
