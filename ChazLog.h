//
//  ChazLog.h
//  Niobium
//
//  Created by NB McGarvey on 9/6/04.
//  Copyright 2004 NB McGarvey. All rights reserved.
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