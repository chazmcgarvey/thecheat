
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      SessionController.h
// Created:   Sun Sep 07 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>
#import <Chaz/Chaz.h>

#include <float.h>

#import "ClientDelegate.h"

#import "MenuExtras.h"

#include "cheat_types.h"
#include "cheat_globals.h"
#include "cheat_net.h"


@interface SessionController : NSWindowController < ClientDelegate >
{
	// allows for easy interface updating
	TCstatus			status, lastStatus;
	
	// dealing with connecting
	BOOL				waitingToConnect;
	NSConnection		*connection;
	NSData				*connectionAddress;
	NSString			*connectionName;
	int					sockfd;
	
	// for updating the interface
	NSString			*targetName;
	int					targetPID;
	BOOL				targetPaused;

	NSArray				*serverList;
	NSMutableArray		*addressList;

	TCaddress			*searchResults;
	int					searchResultsAmount;
	int					searchResultsAmountDisplayed;

	// to allow for connecting on new document
	BOOL				everConnected;
	
	// for the status field
	NSString			*savedStatusText;
	NSColor				*savedStatusColor;
	NSTimer				*statusTextTimer;
	
	// for updating the interface
	int					undoCount, redoCount;
	BOOL				addressSelected;
	
	// for changing variables every x seconds
	NSTimer				*changeTimer;
	NSArray				*changeSelectedItems;

	// INTERFACE OUTLETS
	IBOutlet NSWindow				*cheatWindow;
	IBOutlet NSPopUpButton  		*serverPopup;
	IBOutlet NSButton				*pauseButton;
	IBOutlet NSPopUpButton  		*processPopup;
	IBOutlet NSPopUpButton  		*typePopup;
	IBOutlet NSPopUpButton  		*sizePopup;
	IBOutlet NSTextField			*searchTextField;
	IBOutlet NSMatrix				*searchRadioMatrix;
	IBOutlet NSButton				*searchButton;
	IBOutlet NSButton				*clearSearchButton;
	IBOutlet NSButton				*changeButton;
	IBOutlet NSTableView			*addressTable;
	IBOutlet CMStatusView			*statusText;
	IBOutlet NSProgressIndicator	*statusBar;
	IBOutlet NSTextField			*descriptionText;

	IBOutlet NSMenu					*serverMenu;
	IBOutlet NSMenu					*processMenu;
	IBOutlet NSMenu					*typeMenu;
	IBOutlet NSMenu					*stringSizeMenu;
	IBOutlet NSMenu					*integerSizeMenu;
	IBOutlet NSMenu					*decimalSizeMenu;
	
	// FOR THE CHANGE SHEET
	IBOutlet NSWindow				*changeSheet;
	IBOutlet NSTextField			*changeTextField;
	IBOutlet NSButton				*recurringChangeButton;
	IBOutlet NSComboBox				*changeSecondsCombo;
	IBOutlet NSButton				*cancelButton;
	IBOutlet NSButton				*okButton;
}

// UPDATE INTERFACE
- (void)initialInterfaceSetup;

- (void)updateSearchButton;
- (void)updatePauseButton;
- (void)updateSearchBoxes;
- (void)updateChangeButton;
- (void)updateDescriptionText;

- (void)setStatusDisconnected;
- (void)setStatusConnected;
- (void)setStatusCheating;
- (void)setStatusSearching;
- (void)setStatusChanging;
- (void)setStatusChangingLater;
- (void)setStatusChangingContinuously;
- (void)setStatusUndoing;
- (void)setStatusRedoing;
//- (void)setStatusToLast;

//- (void)setStatusText:(NSString *)msg duration:(NSTimeInterval)seconds;
//- (void)setStatusText:(NSString *)msg duration:(NSTimeInterval)seconds color:(NSColor *)color;
//- (void)statusTextTimer:(NSTimer *)timer;

// UPDATE CHANGE SHEET



// CONNECT/DISCONNECT TO SERVER
- (void)connectToLocal;
- (void)connectToServer:(NSData *)addr name:(NSString *)name;
- (void)disconnect;

// SEND NETWORK MESSAGE
- (void)sendProcessListRequest;
- (void)sendClearSearch;
- (void)sendSearch:(char const *)data size:(int)size;
- (void)sendChange:(char const *)data size:(int)size;
- (void)sendPauseTarget;
- (void)sendVariableValueRequest;
- (void)sendUndoRequest;
- (void)sendRedoRequest;
- (void)sendSetTargetPID:(int)pid;

// RECEIVED NETWORK MESSAGE
- (void)receivedProcessList:(NSData *)data;
- (void)receivedSearchFinished;
- (void)receivedVariableList:(NSData *)data;
- (void)receivedChangeFinished;
- (void)receivedError:(NSData *)data;
- (void)receivedUndoFinished;
- (void)receivedRedoFinished;
- (void)receivedUndoRedoStatus:(NSData *)data;
- (void)receivedAppLaunched:(NSData *)data;
- (void)receivedAppQuit:(NSData *)data;
- (void)receivedTargetQuit;
- (void)receivedPauseFinished:(NSData *)data;

// SEARCHING/CHANGING COMMANDS
- (void)search;
- (void)change;

- (void)changeSheet:(NSWindow *)sheet returned:(int)returned context:(void *)context;

- (void)changeTimer:(NSTimer *)timer;

// CHEAT WINDOW INTERFACE
- (IBAction)typePopup:(id)sender;
- (IBAction)sizePopup:(id)sender;

- (IBAction)searchButton:(id)sender;
- (IBAction)clearSearchButton:(id)sender;

- (IBAction)changeButton:(id)sender;

- (IBAction)serverMenuItem:(id)sender;
- (IBAction)serverMenuDisconnect:(id)sender;
- (IBAction)serverMenuLocal:(id)sender;
- (IBAction)processMenuItem:(id)sender;

- (IBAction)pauseButton:(id)sender;

- (IBAction)undoMenu:(id)sender;
- (IBAction)redoMenu:(id)sender;

// CHANGE SHEET INTERFACE
- (IBAction)cancelButton:(id)sender;
- (IBAction)okButton:(id)sender;

- (IBAction)recurringChangeButton:(id)sender;

// CLEAN UP
- (void)clearSearch;
- (void)destroyResults;

// NOTIFICATION SELECTORS
- (void)listenerStarted:(NSNotification *)note;
- (void)listenerStopped:(NSNotification *)note;

- (void)windowsOnTopChanged:(NSNotification *)note;

// ERROR HANDLING
- (void)handleErrorMessage:(NSString *)msg fatal:(BOOL)fatal;

@end