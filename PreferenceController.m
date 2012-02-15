
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

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
    [_toolbar setSelectedItemIdentifier:@"General"];
}

- (void)chooseServer:(id)object
{
	NSWindow *window = [self window];
	[self switchToView:ibServerView];
	[window setTitle:@"Server"];
    [_toolbar setSelectedItemIdentifier:@"Server"];
}

- (void)chooseUpdate:(id)object
{
	NSWindow *window = [self window];
	[self switchToView:ibUpdateCheckView];
	[window setTitle:@"Update Check"];
    [_toolbar setSelectedItemIdentifier:@"Update Check"];
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
