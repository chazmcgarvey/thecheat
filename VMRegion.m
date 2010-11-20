
// 
// VMRegion 0.1
// Virtual Memory Wrapper
// 
// Copyright (c) 2004, Charles McGarvey
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

#import "VMRegion.h"

#include <mach/mach_traps.h> // for task_for_pid(3)
#include <signal.h> // for stop(2)

static __inline__ vm_map_t _VMTaskFromPID( pid_t process )
{
	vm_map_t task;
	
	if ( task_for_pid( current_task(), process, &task ) == KERN_SUCCESS ) {
		return task;
	}
	return 0;
}

static __inline__ VMRegion _VMMakeRegionWithAttributes( pid_t process, mach_vm_address_t address, mach_vm_size_t size, unsigned attribs )
{
	VMRegion region;
	region._process = process;
	region._address = address;
	region._size = size;
	region._attributes = attribs;
	return region;
}

unsigned _VMAttributesFromAddress( pid_t process, mach_vm_address_t address );


const VMRegion VMNullRegion = { 0, 0, 0, 0 };


#pragma mark -
#pragma mark VMRegion Functions
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

VMRegion VMMakeRegion( pid_t process, mach_vm_address_t address, mach_vm_size_t size )
{
	VMRegion region;
	region._process = process;
	region._address = address;
	region._size = size;
	region._attributes = _VMAttributesFromAddress( process, address );
	return region;
}

BOOL VMRegionSetData( VMRegion region, NSData *data )
{
	// get the size that should be used (to prevent from writing past the region)
	mach_vm_size_t size = (mach_vm_size_t)[data length];
	size = (size > region._size)? region._size : size;
	
	return VMWriteBytes( region._process, region._address, [data bytes], size );
}

NSString *VMStringFromRegion( VMRegion region )
{
	return [NSString stringWithFormat:@"{pid:%i,%p,%u,}", region._process, region._address, region._size];
}


#pragma mark -
#pragma mark Utility VM Functions
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

unsigned VMCountRegions( pid_t process )
{
	VMRegion region;
	VMRegion prev = VMNullRegion;
	unsigned count = 0;
	
	while ( VMRegionIsNotNull( region = VMNextRegion( process, prev ) ) )
	{
		count++;
		prev = region;
	}
	
	return count;
}

unsigned VMCountRegionsWithAttributes( pid_t process, unsigned attribs )
{
	VMRegion region;
	VMRegion prev = VMNullRegion;
	unsigned count = 0;
	
	while ( VMRegionIsNotNull( region = VMNextRegionWithAttributes( process, prev, attribs ) ) )
	{
		count++;
		prev = region;
	}
	
	return count;
}


VMRegion VMNextRegion( pid_t process, VMRegion previous )
{
	vm_map_t task = _VMTaskFromPID( process );
	unsigned attribs = 0;
	
	kern_return_t result;
	
	mach_vm_address_t address = 0x0;
	mach_vm_size_t size = 0;
	vm_region_basic_info_data_64_t info;
	mach_msg_type_number_t infoCnt = VM_REGION_BASIC_INFO_COUNT_64;
	mach_port_t object_name = 0;
	
	if ( !VMEqualRegions( previous, VMNullRegion ) ) {
		address = previous._address + previous._size;
	}
	
	// get the next region
	result = mach_vm_region( task, &address, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)(&info), &infoCnt, &object_name );
	
	if ( result == KERN_SUCCESS ) {
		// get the attributes
		if ( info.protection & VM_PROT_READ ) {
			attribs |= VMREGION_READABLE;
		}
		if ( info.protection & VM_PROT_WRITE ) {
			attribs |= VMREGION_WRITABLE;
		}
		if ( info.protection & VM_PROT_EXECUTE ) {
			attribs |= VMREGION_EXECUTABLE;
		}
		// return the region
		return _VMMakeRegionWithAttributes( process, address, size, attribs );
	}
	
	return VMNullRegion;
}

VMRegion VMNextRegionWithAttributes( pid_t process, VMRegion previous, unsigned attribs )
{
	VMRegion region;
	
	while ( VMRegionIsNotNull( region = VMNextRegion( process, previous ) ) )
	{
		if ( (attribs & region._attributes) == attribs ) {
			// pass back this region if the attributes match
			return region;
		}
		previous = region;
	}
	
	return VMNullRegion;
}


NSData *VMReadData( pid_t process, mach_vm_address_t address, mach_vm_size_t size )
{
	vm_map_t task = _VMTaskFromPID( process );
	kern_return_t result;
	
	void *buffer;
	mach_vm_size_t actualSize;
	
	// create a local block to hold the incoming data
	buffer = (void *)malloc( (size_t)size );
	if ( !buffer ) {
		// no buffer, abort
		return nil;
	}
	
	// perform the read
	result = mach_vm_read_overwrite( task, address, size, (vm_offset_t)buffer, &actualSize );
	if ( result != KERN_SUCCESS ) {
		// read error, abort
		free( buffer );
		return nil;
	}
	
	// everything seems to be peachy, so return the data
	return [[[NSData alloc] initWithBytesNoCopy:buffer length:actualSize freeWhenDone:YES] autorelease];
}

BOOL VMReadBytes( pid_t process, mach_vm_address_t address, void *bytes, mach_vm_size_t *size )
{
	vm_map_t task = _VMTaskFromPID( process );
	kern_return_t result;
	mach_vm_size_t staticsize = *size;
	
	// perform the read
	result = mach_vm_read_overwrite( task, address, staticsize, (vm_offset_t)bytes, size );
	if ( result != KERN_SUCCESS ) {
		return NO;
	}
	
	return YES;
}

BOOL VMWriteData( pid_t process, mach_vm_address_t address, NSData *data )
{
	return VMWriteBytes( process, address, [data bytes], [data length] );
}

BOOL VMWriteBytes( pid_t process, mach_vm_address_t address, const void *bytes, mach_vm_size_t size )
{
	vm_map_t task = _VMTaskFromPID( process );
	kern_return_t result;
	
	// attempt to write the bytes and return success/failure
	result = mach_vm_write( task, address, (vm_offset_t)bytes, size );
	return (result == KERN_SUCCESS);
}


unsigned _VMAttributesFromAddress( pid_t process, mach_vm_address_t address )
{
	vm_map_t task = _VMTaskFromPID( process );
	unsigned attribs = 0;
	
	kern_return_t result;
	
	mach_vm_size_t size = 0;
	vm_region_basic_info_data_64_t info;
	mach_msg_type_number_t infoCnt = VM_REGION_BASIC_INFO_COUNT_64;
	mach_port_t object_name = 0;
	
	// get the next region
	result = mach_vm_region( task, &address, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)(&info), &infoCnt, &object_name );
	
	if ( result == KERN_SUCCESS ) {
		// get the attributes
		if ( info.protection & VM_PROT_READ ) {
			attribs |= VMREGION_READABLE;
		}
		if ( info.protection & VM_PROT_WRITE ) {
			attribs |= VMREGION_WRITABLE;
		}
		if ( info.protection & VM_PROT_EXECUTE ) {
			attribs |= VMREGION_EXECUTABLE;
		}
		// return the region attributes
		return attribs;
	}
	return 0;
}


