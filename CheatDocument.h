
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import <Cocoa/Cocoa.h>
#import "ChazLog.h"
#include "cheat_global.h"

#import "VariableTable.h"
#import "FadeView.h"
#import "MenuExtras.h"
#import "StatusTextField.h"

#import "CheatData.h"
#import "SearchData.h"

#import "LocalCheater.h"
#import "RemoteCheater.h"
#import "Variable.h"

#import "AppController.h"


typedef unsigned TCDocumentMode;
enum {
	TCSearchMode = 0,
	TCCheatMode = 1
};


typedef unsigned TCDocumentStatus;
enum {
	TCIdleStatus = 0,
	TCSearchingStatus = 1,
	TCCheatingStatus = 2,
	TCDumpingStatus = 3
};


@interface CheatDocument : NSDocument
{
	// WINDOW INTERFACE
	IBOutlet NSWindow *ibWindow;
	IBOutlet NSPopUpButton *ibServerPopup;
	IBOutlet NSPopUpButton *ibProcessPopup;
	IBOutlet NSView *ibPlaceView;
	IBOutlet StatusTextField *ibStatusText;
	IBOutlet NSProgressIndicator *ibStatusBar;
	
	// SEARCH MODE INTERFACE
	IBOutlet NSView *ibSearchContentView;
	IBOutlet NSPopUpButton *ibSearchTypePopup;
	IBOutlet NSMatrix *ibSearchIntegerSignMatrix;
	IBOutlet NSPopUpButton *ibSearchOperatorPopup;
	IBOutlet NSMatrix *ibSearchValueUsedMatrix;
	IBOutlet NSTextField *ibSearchValueField;
	IBOutlet VariableTable *ibSearchVariableTable;
	IBOutlet NSButton *ibSearchClearButton;
	IBOutlet NSButton *ibSearchButton;
	IBOutlet NSButton *ibSearchVariableButton;
	
	// CHEAT MODE INTERFACE
	IBOutlet NSView *ibCheatContentView;
	IBOutlet NSTextField *ibCheatInfoText;
	IBOutlet BetterTableView *ibCheatVariableTable;
	IBOutlet NSButton *ibCheatRepeatButton;
	IBOutlet NSTextField *ibCheatRepeatAuxText;
	IBOutlet NSTextField *ibCheatRepeatField;
	IBOutlet NSButton *ibCheatButton;
	
	// PROPERTIES INTERFACE
	IBOutlet NSWindow *ibPropertiesSheet;
	IBOutlet NSTextField *ibWindowTitleField;
	IBOutlet NSTextField *ibCheatInfoField;
	
	// PASSWORD INTERFACE
	IBOutlet NSWindow *ibPasswordSheet;
	IBOutlet NSTextField *ibPasswordField;
	
	// CUSTOM SERVER INTERFACE
	IBOutlet NSWindow *ibCustomServerSheet;
	IBOutlet NSTextField *ibServerField;
	IBOutlet NSTextField *ibPortField;
	
	// EDIT VARIABLES INTERFACE
	IBOutlet NSWindow *ibEditVariablesSheet;
	IBOutlet NSTextField *ibNewValueField;
	
	NSResponder *_lastResponder;
	
	// ### IMPORTANT STUFF ###
	BOOL _connectsOnOpen; // set whether connects automatically on open
	TCDocumentMode _mode; // 'search' or 'cheat' mode
	FadeView *_fadeView; // facilitates the fade animation
	
	TCDocumentStatus _status; // what the user is doing
	BOOL _isCancelingTask; // is what the user doing being cancelled
	BOOL _isTargetPaused; // is the currently selected process paused
	
	id _serverObject; // the object represented by the current server
	Process *_process; // the currently selected process
	
	CheatData *_cheatData; // container for the document data
	SearchData *_searchData; // container for the search data
	
	Cheater *_cheater; // the local or remote object to handle the cheating
	
	// rendezvous support
	NSNetService *_resolvingService;
}

// #############################################################################
#pragma mark Service Finding
// #############################################################################

+ (NSArray *)cheatServices;

// #############################################################################
#pragma mark Changing Mode
// #############################################################################

// used to set the mode before the nib is loaded.
// do not use after that.
- (void)setMode:(TCDocumentMode)mode;

// use this after the nib is loaded.
- (void)switchToCheatMode;
- (void)switchToSearchMode;

// #############################################################################
#pragma mark Accessors
// #############################################################################

- (NSString *)defaultStatusString;
- (BOOL)isLoadedFromFile;

- (void)addServer:(NSMenuItem *)item;
- (void)removeServerWithObject:(id)serverObject;

// #############################################################################
#pragma mark Interface
// #############################################################################

- (void)updateInterface;
- (void)setDocumentChanged;

- (void)setActualResults:(unsigned)count;

// #############################################################################
#pragma mark Utility
// #############################################################################

+ (void)setGlobalTarget:(Process *)target;
+ (Process *)globalTarget;

- (void)showError:(NSString *)error;

// this doesn't update the interface
// so explicitly call updateInterface after use.
- (BOOL)shouldConnectWithServer:(NSMenuItem *)item;
- (void)selectConnectedCheater;
- (void)connectWithServer:(NSMenuItem *)item;
- (void)disconnectFromCheater;

- (void)setConnectOnOpen:(BOOL)flag;
- (void)connectWithURL:(NSString *)url;

- (void)watchVariables;


@end


// #############################################################################

@interface CheatDocument ( DocInterfaceActions )

- (IBAction)ibSetLocalCheater:(id)sender;
- (IBAction)ibSetRemoteCheater:(id)sender;
- (IBAction)ibSetCustomCheater:(id)sender;
- (IBAction)ibSetNoCheater:(id)sender;

- (IBAction)ibSetProcess:(id)sender;

- (IBAction)ibSetVariableType:(id)sender;
- (IBAction)ibSetIntegerSign:(id)sender;
- (IBAction)ibSetOperator:(id)sender;
- (IBAction)ibSetValueUsed:(id)sender;

- (IBAction)ibClearSearch:(id)sender;
- (IBAction)ibSearch:(id)sender;
- (IBAction)ibAddSearchVariable:(id)sender;

- (IBAction)ibSetCheatRepeats:(id)sender;
- (IBAction)ibSetRepeatInterval:(id)sender;
- (IBAction)ibCheat:(id)sender;

- (IBAction)ibRunPropertiesSheet:(id)sender;
- (IBAction)ibEndPropertiesSheet:(id)sender;

- (IBAction)ibRunPasswordSheet:(id)sender;
- (IBAction)ibEndPasswordSheet:(id)sender;

- (IBAction)ibRunCustomServerSheet:(id)sender;
- (IBAction)ibEndCustomServerSheet:(id)sender;

- (IBAction)ibRunEditVariablesSheet:(id)sender;
- (IBAction)ibEndEditVariablesSheet:(id)sender;

- (IBAction)ibPauseTarget:(id)sender;
- (IBAction)ibResumeTarget:(id)sender;

- (IBAction)ibCancelSearch:(id)sender;
- (IBAction)ibStopCheat:(id)sender;

- (IBAction)ibDumpMemory:(id)sender;
- (IBAction)ibCancelDump:(id)sender;

- (IBAction)ibAddCheatVariable:(id)sender;
- (IBAction)ibSetVariableEnabled:(id)sender;

- (IBAction)ibToggleSearchCheat:(id)sender;

- (IBAction)ibUndo:(id)sender;
- (IBAction)ibRedo:(id)sender;

@end


// #############################################################################

@interface CheatDocument ( DocCheaterDelegate ) < CheaterDelegate >

@end

