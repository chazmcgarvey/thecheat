
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
