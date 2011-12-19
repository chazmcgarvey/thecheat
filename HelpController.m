
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import "HelpController.h"


@implementation HelpController


- (id)init
{
	return [super initWithWindowNibName:@"Help"];
}

- (void)windowDidLoad
{
	NSString *filepath = [[NSBundle mainBundle] pathForResource:@"Help" ofType:@"html"];
	NSURL *url;
	NSURLRequest *request;
	
	if ( !filepath ) {
		return;
	}
	
	url = [NSURL fileURLWithPath:filepath];
	request = [NSURLRequest requestWithURL:url];
	
	[[webView mainFrame] loadRequest:request];
	[helpWindow center];
}


- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
	NSURL *url = [request URL];
	
	// open "http" and "mailto" links in a real browser or email client
	if ( [[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"mailto"] ) {
		[[NSWorkspace sharedWorkspace] openURL:url];
		[listener ignore];
	}
	[listener use];
}


@end
