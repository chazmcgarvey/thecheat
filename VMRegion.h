
// 
// VMRegion 0.1
// Virtual Memory Wrapper
// 
// Copyright (c) 2004, Chaz McGarvey
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this list
// of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice, this
// list of conditions and the following disclaimer in the documentation and/or other
// materials provided with the distribution.
// 
// 3. Neither the name of the BrokenZipper nor the names of its contributors may be
// used to endorse or promote products derived from this software without specific
// prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
// SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
// TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
// ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// 
// Web:   http://www.brokenzipper.com/
// Email: chaz@brokenzipper.com
// 

#import <Cocoa/Cocoa.h>

#include <mach/vm_region.h>
#include <mach/vm_map.h>


/* Compiler macros */
#if defined( __cplusplus )
#define VMREGION_EXPORT extern "C"
#define VMREGION_IMPORT extern "C"
#else
#define VMREGION_EXPORT extern
#define VMREGION_IMPORT extern
#endif

#if !defined( VMREGION_STATIC_INLINE )
#define VMREGION_STATIC_INLINE static __inline__
#endif

#if !defined( VMREGION_EXTERN_INLINE )
#define VMREGION_EXTERN_INLINE extern __inline__
#endif


// attributes of memory regions
enum _VMRegionAttributes
{
	VMREGION_READABLE = 1,
	VMREGION_WRITABLE = 2,
	VMREGION_EXECUTABLE = 4
};


#pragma mark -
#pragma mark VMRegion
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

typedef struct _VMRegion
{
	// process information
	pid_t _process;
	// region information
	vm_address_t _address;
	vm_size_t _size;
	unsigned _attributes;
} VMRegion;

// common regions
VMREGION_EXPORT const VMRegion VMNullRegion; /* <0,0,0> */


#pragma mark -
#pragma mark Utility VM Functions
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

// get the number of regions a process has.
unsigned VMCountRegions( pid_t process );
unsigned VMCountRegionsWithAttributes( pid_t process, unsigned attribs );

// these functions return allocated VMRegion objects.
// use VMReleaseRegion(1) to free up used memory.
// returns nil on error or if there is no region after prevRegion.
// pass nil for prevRegion to access the first region.
VMRegion VMNextRegion( pid_t process, VMRegion previous );
VMRegion VMNextRegionWithAttributes( pid_t process, VMRegion previous, unsigned attribs );

// UTILITY functions - stop/resume processes
// returns YES on success, NO on failure
VMREGION_STATIC_INLINE BOOL VMStopProcess( pid_t process ) { return (kill( process, SIGSTOP ) == 0); }
VMREGION_STATIC_INLINE BOOL VMContinueProcess( pid_t process ) { return (kill( process, SIGCONT ) == 0); }

// lower-level reading/writing functions
// the returned NSData object should be retained by the caller.
NSData *VMReadData( pid_t process, vm_address_t address, vm_size_t size );
BOOL VMReadBytes( pid_t process, vm_address_t address, void *bytes, vm_size_t *size ); // size is # bytes read after call
BOOL VMWriteData( pid_t process, vm_address_t address, NSData *data ); // returns YES on success, NO on failure
BOOL VMWriteBytes( pid_t process, vm_address_t address, const void *bytes, vm_size_t size );


#pragma mark -
#pragma mark Exported VM Functions
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

VMREGION_EXPORT VMRegion VMMakeRegion( pid_t process, vm_address_t address, vm_size_t size );

VMREGION_EXPORT BOOL VMRegionSetData( VMRegion region, NSData *data );

VMREGION_EXPORT NSString *VMStringFromRegion( VMRegion region );


#pragma mark -
#pragma mark Imported VM Functions
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

VMREGION_STATIC_INLINE vm_address_t VMRegionProcess( VMRegion region )
{
	return region._process;
}

VMREGION_STATIC_INLINE vm_address_t VMRegionAddress( VMRegion region )
{
	return region._address;
}

VMREGION_STATIC_INLINE vm_size_t VMRegionSize( VMRegion region )
{
	return region._size;
}

VMREGION_STATIC_INLINE unsigned VMRegionAttributes( VMRegion region )
{
	return region._attributes;
}

VMREGION_STATIC_INLINE BOOL VMRegionReadable( VMRegion region )
{
	return region._attributes & VMREGION_READABLE;
}

VMREGION_STATIC_INLINE BOOL VMRegionWritable( VMRegion region )
{
	return region._attributes & VMREGION_WRITABLE;
}

VMREGION_STATIC_INLINE BOOL VMRegionExecutable( VMRegion region )
{
	return region._attributes & VMREGION_EXECUTABLE;
}


VMREGION_STATIC_INLINE NSData *VMRegionData( VMRegion region )
{
	return VMReadData( region._process, region._address, region._size );
}

VMREGION_STATIC_INLINE BOOL VMRegionBytes( VMRegion region, void *bytes, vm_size_t *size )
{
	*size = region._size;
	return VMReadBytes( region._process, region._address, bytes, size );
}



VMREGION_STATIC_INLINE BOOL VMRegionIsNotNull( VMRegion region )
{
	return (region._process != 0);
}

VMREGION_STATIC_INLINE BOOL VMEqualRegions( VMRegion region1, VMRegion region2 )
{
	return (region1._process == region2._process &&
			region1._address == region2._address &&
			region1._size == region2._size &&
			region1._attributes == region2._attributes);
}


