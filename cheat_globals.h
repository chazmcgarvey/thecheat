
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      cheat_globals.h
// Created:   Fri Sep 19 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#ifndef _cheat_globals_H
#define _cheat_globals_H

#import <Cocoa/Cocoa.h>

#define					TCDefaultListenPort (51835)
//#define					TCDefaultListenPath "/tmp/com.brokenzipper.TheCheat"
// this path alone would work, but it *should* go in the user's home directory
char extern				TCDefaultListenPath[104];

//#define					TCMaxSearchResults (100)

int extern				TCGlobalDocumentCount;
int extern				TCGlobalAlternateBroadcastNameCount;
char extern				TCGlobalListening;

char extern				TCGlobalPlaySounds;
char extern				TCGlobalWindowsOnTop;
char extern				TCGlobalUpdateCheck;
char extern				TCGlobalAllowRemote;
int extern				TCGlobalListenPort;
#define					TCGlobalBroadcastName ([[NSUserDefaults standardUserDefaults] objectForKey:TCBroadcastNamePref])
int extern				TCGlobalHitsDisplayed;

NSString extern			*TCPlaySoundsPref;
NSString extern			*TCWindowsOnTopPref;
NSString extern			*TCUpdateCheckPref;
NSString extern			*TCAllowRemotePref;
NSString extern			*TCListenPortPref;
NSString extern			*TCBroadcastNamePref;
NSString extern			*TCHitsDisplayedPref;

#endif

