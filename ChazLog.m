
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


#include "ChazLog.h"

#include "stdio.h"
#include "stdlib.h"


// PrivateAPI
void static _ChazPrint( FILE *output, NSString *format, va_list args );


// Static Globals
BOOL static _gLogEnabled = NO;
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


