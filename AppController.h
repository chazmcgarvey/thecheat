
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      AppController.h
// Created:   Wed Aug 13 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>


// constants
enum
{
	TYPE_STRING, TYPE_INTEGER, TYPE_FLOAT
};

enum
{
	SIZE_8_BIT, SIZE_16_BIT, SIZE_32_BIT, SIZE_64_BIT
};


@interface AppController : NSObject
{
	BOOL			cheating;
	
	NSArray			*processList;
	
	NSMutableArray	*addressList;
	BOOL			searching;
	
	IBOutlet id		window;
	IBOutlet id		processPopup;
	IBOutlet id		searchTextField;
	IBOutlet id		changeTextField;
	IBOutlet id		searchButton;
	IBOutlet id		changeButton;
	IBOutlet id		typePopup;
	IBOutlet id		sizePopup;
	IBOutlet id		statusText;
	IBOutlet id		statusBar;
	IBOutlet id		addressTable;
}

- (void)reset;

- (void)firstSearch:(id)nothing;
- (void)search:(id)nothing;

- (void)change;

- (void)updateProcessPopup;
- (void)updateTypePopup;
- (void)updateSizePopup;
- (void)updateSearchButton;
- (void)updateChangeButton;
- (void)updateStatusText;

- (void)rebuildProcessList;

- (IBAction)processPopup:(id)sender;
- (IBAction)typePopup:(id)sender;
- (IBAction)searchButton:(id)sender;
- (IBAction)changeButton:(id)sender;

@end