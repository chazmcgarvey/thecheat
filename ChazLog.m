
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#include "ChazLog.h"

#include "stdio.h"
#include "stdlib.h"


// PrivateAPI
void static _ChazPrint( FILE *output, NSString *format, va_list args );


// Static Globals
BOOL static _gLogEnabled = YES;
FILE static *_gLogFile = stdout;
FILE static *_gDebugFile = NULL;


#pragma mark -
#pragma mark Setup
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

void ChazLogEnable()
{
	_gLogEnabled = YES;
}

void ChazLogDisable()
{
	if ( _gLogFile != _gDebugFile ) {
		_gLogEnabled = NO;
	}
}


void ChazDebugSetup()
{
	NSString *filepath = ChazDebugLogPath();
	FILE *file;
	
	// look for debug file
	file = fopen( [filepath lossyCString], "r+" );
	
	if ( !file ) {
		// there is no debug file or we don't have permissions
		return;
	}
	
	fclose( file );
	
	_gDebugFile = fopen( [filepath lossyCString], "w" );
	
	ChazDebug( @"Debug log found (obviously).  Entering debug mode." );
}

void ChazDebugCleanup()
{
	if ( _gDebugFile ) {
		ChazDebug( @"Debug log cleaned up." );
		
		fclose ( _gDebugFile );
	}
}


#pragma mark -
#pragma mark Logs
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

void ChazLog( NSString *format, ... )
{
	va_list args;
	
	if ( !_gLogEnabled ) {
		return;
	}
	
    va_start( args, format );
	// print log to standard i/o
	_ChazPrint( _gLogFile, format, args );
    va_end( args );
}

void ChazDebug( NSString *format, ... )
{
	va_list args;
	
	if ( !_gDebugFile ) {
		return;
	}
	
    va_start( args, format );
	// print log to the debug file
	_ChazPrint( _gDebugFile, format, args );
    va_end( args );
}


#pragma mark -
#pragma mark Miscellaneous
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

BOOL ChazIsDebugging()
{
	return (_gDebugFile != NULL);
}

NSString *ChazDebugLogPath()
{
	// get filepath
	return [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"debug.txt"];
}


void ChazMapLogToDebug()
{
	if ( _gDebugFile ) {
		_gLogEnabled = YES;
		_gLogFile = _gDebugFile;
	}
}


void ChazOpenDebugLog()
{
	[[NSWorkspace sharedWorkspace] openFile:ChazDebugLogPath()];
}


#pragma mark -
#pragma mark PrivateAPI
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

void _ChazPrint( FILE *output, NSString *format, va_list args )
{
	NSString *string;
	
	// get formatted string
    string = [[NSString alloc] initWithFormat:format arguments:args];
	
	fprintf( output, "[%s] %s\n", [[[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S.%F"
																	   timeZone:nil
																		 locale:nil] lossyCString], [string lossyCString] );
	fflush( output );
	
	[string release];
}


