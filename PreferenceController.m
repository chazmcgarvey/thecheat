
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

#import "PreferenceController.h"


@implementation PreferenceController


- (id)init
{
	if ( self = [super initWithWindowNibName:@"Preferences"] )
	{
		[self setWindowFrameAutosaveName:@"TCPreferencWindowPosition"];
	}
	return self;
}

- (void)dealloc
{
	[_toolbar release];
	[_contentView release];
	[super dealloc];
}


- (void)windowDidLoad
{
	_toolbar = [[NSToolbar alloc] initWithIdentifier:@"TCPreferencesToolbar"];
	[_toolbar setDelegate:self];
	[_toolbar setVisible:YES];
	[[self window] setToolbar:_toolbar];
	
	_contentView = [[[self window] contentView] retain];
	
	[self initialInterfaceSetup];
}


- (void)initialInterfaceSetup
{
	[self chooseGeneral:self];
}


- (void)chooseGeneral:(id)object
{
	NSWindow *window = [self window];
	[self switchToView:ibGeneralView];
	[window setTitle:@"General"];
	if ( MacOSXVersion() >= 0x1030 ) {
		[_toolbar setSelectedItemIdentifier:@"General"];
	}
}

- (void)chooseServer:(id)object
{
	NSWindow *window = [self window];
	[self switchToView:ibServerView];
	[window setTitle:@"Server"];
	if ( MacOSXVersion() >= 0x1030 ) {
		[_toolbar setSelectedItemIdentifier:@"Server"];
	}
}

- (void)chooseUpdate:(id)object
{
	NSWindow *window = [self window];
	[self switchToView:ibUpdateCheckView];
	[window setTitle:@"Update Check"];
	if ( MacOSXVersion() >= 0x1030 ) {
		[_toolbar setSelectedItemIdentifier:@"Update Check"];
	}
}

- (void)switchToView:(NSView *)view
{
	NSWindow *window = [self window];
	NSRect frame = [window frame];
	float xdif, ydif;
	
	if ( view == [window contentView] ) {
		return;
	}
	
	xdif = [view frame].size.width - [[window contentView] frame].size.width;
	ydif = [view frame].size.height - [[window contentView] frame].size.height;
	
	frame.size.width += xdif;
	frame.size.height += ydif;
	frame.origin.y -= ydif;
	
	// switch to the new view
	[window setContentView:_contentView];
	[window setFrame:frame display:YES animate:YES];
	[window setContentView:view];
	[window makeFirstResponder:view];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem		*item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	[item setLabel:itemIdentifier];
	[item setPaletteLabel:itemIdentifier];
	[item setImage:[NSImage imageNamed:itemIdentifier]];
	[item setTarget:self];
	[item setAction:NSSelectorFromString( [NSString stringWithFormat:@"choose%@:", itemIdentifier] )];
	
    return [item autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:@"General", @"Update", @"Server", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:@"General", @"Update", @"Server", nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:@"General", @"Update", @"Server", nil];
}


@end