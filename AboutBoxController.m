
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import "AboutBoxController.h"


@implementation AboutBoxController


- (id)init
{
	return [super initWithWindowNibName:@"AboutBox"];
}

- (void)windowDidLoad
{
	NSDictionary *attributes;
	NSAttributedString *string;
	
	// set the version string
	[ibNameVersionText setStringValue:[NSString stringWithFormat:@"Version %@", ChazAppVersion()]];
	// set the built string
	[ibDateText setStringValue:[NSString stringWithFormat:@"Built %@", [ChazAppBuildDate() description]]];
	
	// set the attributes for the website and email links
	attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName,
		[NSNumber numberWithBool:YES], NSUnderlineStyleAttributeName,
		[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName, nil];
	
	string = [[NSAttributedString alloc] initWithString:[ibWebsiteButton title] attributes:attributes];
	[ibWebsiteButton setAttributedTitle:string];
	[string release];
	string = [[NSAttributedString alloc] initWithString:[ibEmailButton title] attributes:attributes];
	[ibEmailButton setAttributedTitle:string];
	[string release];
	
	attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor redColor], NSForegroundColorAttributeName,
		[NSNumber numberWithBool:YES], NSUnderlineStyleAttributeName,
		[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName, nil];
	
	string = [[NSAttributedString alloc] initWithString:[ibWebsiteButton title] attributes:attributes];
	[ibWebsiteButton setAttributedAlternateTitle:string];
	[string release];
	string = [[NSAttributedString alloc] initWithString:[ibEmailButton title] attributes:attributes];
	[ibEmailButton setAttributedAlternateTitle:string];
	[string release];
	
	[[self window] center];
}


- (IBAction)ibWebsiteButton:(id)sender
{
	LaunchWebsite();
}

- (IBAction)ibEmailButton:(id)sender
{
	LaunchEmail();
}


@end
