
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
