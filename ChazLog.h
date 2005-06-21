
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


#ifndef _ChazLog_h_
#define _ChazLog_h_

#if defined(__cplusplus)
extern "C" {
#endif

#import <Cocoa/Cocoa.h>


/* Enable and disable logging to the standard console. */
void ChazLogEnable();
void ChazLogDisable();

/* Required for logging to a debug file. */
void ChazDebugSetup();
void ChazDebugCleanup();

/* Print a log message to the standard console. */
void ChazLog( NSString *format, ... );
/* Print a log message to the debug file (if available). */
void ChazDebug( NSString *format, ... );

/* Returns true if debug mode is active. */
BOOL ChazIsDebugging();
/* Returns the absolute filepath of the debug log. */
NSString *ChazDebugLogPath();

/* Makes ChazLog() equivalent to ChazDebug(). */
// call this after ChazDebugSetup()
// this will automatically enable logs
void ChazMapLogToDebug();

/* Opens the log file using the default text editor. */
void ChazOpenDebugLog();


#if defined(__cplusplus)
}
#endif


#endif /* _ChazLog_h_ */