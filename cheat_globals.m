
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      cheat_globals.m
// Created:   Fri Sep 19 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#include "cheat_globals.h"

char					TCDefaultListenPath[104] = "/.thecheat_socket";

int						TCGlobalDocumentCount = 1;
int						TCGlobalAlternateBroadcastNameCount = 2;
char					TCGlobalListening = NO;

char					TCGlobalPlaySounds = YES;
char					TCGlobalWindowsOnTop = NO;
char					TCGlobalAllowRemote = NO;
int						TCGlobalListenPort = TCDefaultListenPort;

NSString				*TCPlaySoundsPref = @"TCPlaySoundsPref";
NSString				*TCWindowsOnTopPref = @"TCWindowsOnTopPref";
NSString				*TCAllowRemotePref = @"TCAllowRemotePref";
NSString				*TCListenPortPref = @"TCListenPortPref";
NSString				*TCBroadcastNamePref = @"TCBroadcastNamePref";