
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

#import "Process.h"

#ifdef __i386__
	#import <sys/types.h>
	#import <sys/sysctl.h>
#endif

@interface Process ( PrivateAPI )

- (void)_setName:(NSString *)name;
- (void)_setVersion:(NSString *)version;
- (void)_setIcon:(NSImage *)icon;
- (void)_setPID:(pid_t)pid;

@end


@implementation Process


- (id)initWithName:(NSString *)name version:(NSString *)version icon:(NSImage *)icon pid:(pid_t)pid
{
	if ( self = [super init] ) {
		[self _setName:name];
		[self _setVersion:version];
		[self _setIcon:icon];
		[self _setPID:pid];
	}
	return self;
}

- (id)initWithName:(NSString *)name version:(NSString *)version icon:(NSImage *)icon
{
	return [self initWithName:name version:version icon:icon pid:0];
}

- (id)initWithName:(NSString *)name version:(NSString *)version
{
	return [self initWithName:name version:version icon:nil pid:0];
}

- (void)dealloc
{
	// release local objects
	[_name release];
	[_version release];
	[_icon release];
	
	[super dealloc];
}


// #############################################################################
#pragma mark NSCoding
// #############################################################################

- (id)copyWithZone:(NSZone *)zone
{
	return [[Process allocWithZone:zone] initWithName:_name version:_version icon:_icon pid:_pid];
}


// #############################################################################
#pragma mark NSCoding
// #############################################################################

- (id)initWithCoder:(NSCoder *)coder
{
	if ( self = [super init] )
	{
		[self _setName:[coder decodeObject]];
		[self _setVersion:[coder decodeObject]];
		//[self setIcon:[coder decodeObject]];
		[coder decodeValueOfObjCType:@encode(pid_t) at:&_pid];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:_name];
	[coder encodeObject:_version];
	//[coder encodeObject:_icon];
	[coder encodeValueOfObjCType:@encode(pid_t) at:&_pid];
}


#pragma mark NSObject Override

- (BOOL)isEqual:(id)anObject
{
	if ( [_name isEqualToString:[(Process *)anObject name]] &&
		 [_version isEqualToString:[(Process *)anObject version]] &&
		 _pid == [(Process *)anObject pid] ) {
		// they are the same process
		return YES;
	}
	return NO;
}

- (unsigned)hash
{
	return [[NSString stringWithFormat:@"%@%@%u", _name, _version, _pid] hash];
}


- (BOOL)sameApplicationAs:(id)anObject
{
	if ( [_name isEqualToString:[(Process *)anObject name]] &&
		 [_version isEqualToString:[(Process *)anObject version]] ) {
		// they are the same application
		return YES;
	}
	return NO;
}

#pragma mark Detecting Emulation

#ifdef __i386__
// http://developer.apple.com/documentation/MacOSX/Conceptual/universal_binary/universal_binary_exec_a/universal_binary_exec_a.html
static int sysctlbyname_with_pid (const char *name, pid_t pid,
								  void *oldp, size_t *oldlenp,
								  void *newp, size_t newlen)
{
    if (pid == 0) {
        if (sysctlbyname(name, oldp, oldlenp, newp, newlen) == -1)  {
            fprintf(stderr, "sysctlbyname_with_pid(0): sysctlbyname  failed:"
					"%s\n", strerror(errno));
            return -1;
        }
    } else {
        int mib[CTL_MAXNAME+1];
        size_t len = CTL_MAXNAME;
        if (sysctlnametomib(name, mib, &len) == -1) {
            fprintf(stderr, "sysctlbyname_with_pid: sysctlnametomib  failed:"
					"%s\n", strerror(errno));
            return -1;
        }
        mib[len] = pid;
        len++;
        if (sysctl(mib, len, oldp, oldlenp, newp, newlen) == -1)  {
            fprintf(stderr, "sysctlbyname_with_pid: sysctl  failed:"
                    "%s\n", strerror(errno));
            return -1;
        }
    }
    return 0;
}

// http://developer.apple.com/documentation/MacOSX/Conceptual/universal_binary/universal_binary_exec_a/universal_binary_exec_a.html
static int is_pid_native (pid_t pid)
{
    int ret = 0;
    size_t sz = sizeof(ret);
	
    if (sysctlbyname_with_pid("sysctl.proc_native", pid,
							  &ret, &sz, NULL, 0) == -1) {
		if (errno == ENOENT) {
            return 1;
        }
        fprintf(stderr, "is_pid_native: sysctlbyname_with_pid  failed:"
                "%s\n", strerror(errno));
        return -1;
    }
    return ret;
}
#endif

- (BOOL)isEmulated
{
	BOOL isEmulated = NO;
#ifdef __i386__
	if (is_pid_native(_pid) == 0)
	{
		isEmulated = YES;
	}
#endif
	
	return isEmulated;
}

#pragma mark Accessors

- (NSString *)name
{
	return _name;
}

- (NSString *)version
{
	return _version;
}

- (NSImage *)icon
{
	return _icon;
}

- (pid_t)pid
{
	return _pid;
}


- (void)_setName:(NSString *)name
{
	if ( !name ) {
		name = [NSString stringWithString:@"Unknown Process"];
	}
	[name retain];
	[_name release];
	_name = name;
}

- (void)_setVersion:(NSString *)version
{
	if ( !version ) {
		version = [NSString stringWithString:@"Unknown Version"];
	}
	[version retain];
	[_version release];
	_version = version;
}

- (void)_setIcon:(NSImage *)icon
{
	[icon retain];
	[_icon release];
	_icon = icon;
	
	// resize new image
	[_icon setScalesWhenResized:YES];
	[_icon setSize:NSMakeSize(16,16)];
}

- (void)_setPID:(pid_t)pid
{
	_pid = pid;
}


@end
