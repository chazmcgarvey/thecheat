
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      CheatServer.m
// Created:   Sun Sep 07 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "CheatServer.h"

#import "SearchResults.h"

// for comparing floats
#import <Chaz/Misc.h>

#include <string.h>
#include <math.h>
#include <errno.h>


// Internal Functions
int bmsearch( char *pat, int m, char *text, int n, void *base, void *loc[] );
//BOOL inline compare_float( float a, float b );
//BOOL inline compare_double( double a, double b );


@implementation CheatServer


+ (NSConnection *)serverWithDelegate:(id)delegate socket:(int)sock
{
	NSPort				*rPort = [NSPort port], *sPort = [NSPort port];
	NSConnection		*connection;
	NSArray				*array;

	connection = [[NSConnection alloc] initWithReceivePort:rPort sendPort:sPort];
	[connection setRootObject:delegate];

	array = [NSArray arrayWithObjects:sPort, rPort, [NSNumber numberWithInt:sock], nil];
	[NSThread detachNewThreadSelector:@selector(serverThread:) toTarget:self withObject:array];

	return [connection autorelease];
}

+ (void)serverThread:(NSArray *)array
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    NSConnection		*connection = [NSConnection connectionWithReceivePort:[array objectAtIndex:0] sendPort:[array objectAtIndex:1]];
    CheatServer			*object = [[self alloc] initWithRootProxy:[connection rootProxy]];

	[object handleSocket:[[array objectAtIndex:2] intValue]];
	[object run];

    [object release];
    [pool release];
}


- (id)initWithRootProxy:(id)proxy
{
	if ( self = [super init] )
	{
		NSNotificationCenter	*nc = [[NSWorkspace sharedWorkspace] notificationCenter];

		rootProxy = proxy;

		[nc addObserver:self selector:@selector(processListChanged:) name:@"NSWorkspaceDidLaunchApplicationNotification" object:nil];
		[nc addObserver:self selector:@selector(processListChanged:) name:@"NSWorkspaceDidTerminateApplicationNotification" object:nil];

		[self setPID:[rootProxy serverFirstProcess]];

		processPaused = NO;

		searchResults = [[NSMutableArray alloc] init];
		searchResultsUndone = [[NSMutableArray alloc] init];
	}

	return self;
}


- (void)handleSocket:(int)sock
{
	struct sockaddr			identifier;
	int						addrLen = sizeof(identifier);

	NSString				*address;
	char					*addressCString;

	sockfd = sock;

	if ( getpeername( sockfd, &identifier, &addrLen ) == -1 )
	{
		CMLog( @"ERROR: getpeername() failed" );
	}

	if ( identifier.sa_family == AF_INET )
	{
		struct sockaddr_in		addr;

		addrLen = sizeof(addr);

		if ( getpeername( sockfd, (struct sockaddr *)(&addr), &addrLen ) == -1 )
		{
			CMLog( @"ERROR: getpeername() failed" );
		}

		if ( (addressCString = inet_ntoa( addr.sin_addr )) == NULL )
		{
			CMLog( @"ERROR: inet_ntoa() failed" );
		}

		address = [NSString stringWithCString:addressCString];
	}
	else
	{
		struct sockaddr_un		addr;

		addrLen = sizeof(addr);

		if ( getpeername( sockfd, (struct sockaddr *)(&addr), &addrLen ) == -1 )
		{
			CMLog( @"ERROR: getpeername() failed" );
		}

		CMLog( @"client connection: %s", addr.sun_path );
		
		address = [NSString stringWithString:@"127.0.0.1"];
	}

	[rootProxy server:self connectedWithSocket:sockfd];

	[self setAddress:address];
	[self setAction:nil];
}

- (void)run
{
	struct timeval		tv;
	fd_set				fdset, master;
	int					numfds;

	int					result;

	PacketHeader		header;
	char				*data = NULL;

	tv.tv_sec = 2;
	tv.tv_usec = 0;

	FD_ZERO( &fdset );
	FD_ZERO( &master );
	FD_SET( sockfd, &master );

	numfds = sockfd + 1;

	CMLog( @"SERVER start" );

	for (;;)
	{
		fdset = master;

		select( numfds, &fdset, NULL, NULL, &tv );

		if ( FD_ISSET( sockfd, &fdset ) )
		{
			if ( (result = ReadBuffer( sockfd, (char *)(&header), sizeof(header) )) != sizeof(header) )
			{
				break;
			}

			if ( !VerifyChecksum( header.checksum ) )
			{
				CMLog( @"checksum failed" );
			}

			if ( header.size != 0 )
			{
				if ( (data = (char *)malloc( header.size )) == NULL )
				{
					CMLog( @"failed to allocate buffer for reading a network packet" );
					break;
				}

				if ( (result = ReadBuffer( sockfd, data, header.size )) != header.size )
				{
					CMLog( @"failed to read the data of a network packet" );
					free( data );
					break;
				}
			}

			//CMLog( @"SERVER message %i/%i/%i", header.checksum, header.function, header.size );

			switch ( header.function )
			{
				case 1:
					[self sendProcessList];
					break;
					
				case 3:
					[self handleClearSearch];
					break;

				case 5:
					[self handleSearch:data size:header.size];
					break;

				case 8:
					[self handleChange:data size:header.size];
					break;

				case 10:
					[self handlePauseTarget];
					break;

				case 14:
					[self handleUndo];
					break;

				case 16:
					[self handleRedo];
					break;

				case 18:
					[self handleSetTargetPID:data size:header.size];
					break;

			}

			if ( header.size != 0 )
			{
				free( data );
			}
		}
	}

	close( sockfd );

	CMLog( @"SERVER close" );

	[rootProxy serverDisconnected:self];
}


- (void)setAddress:(NSString *)address
{
	[rootProxy server:self changedAddress:address];
}

- (void)setAction:(NSString *)action
{
	if ( action == nil )
	{
		[rootProxy server:self changedAction:@"Idle"];
	}
	else
	{
		[rootProxy server:self changedAction:action];
	}
}

- (void)firstSearchString8bit:(char const *)value size:(int)vsize
{
	kern_return_t				result;
	
	vm_address_t				address = 0x0;
	vm_size_t					size = 0;
	vm_region_basic_info_data_t	info;
	mach_msg_type_number_t		infoCnt = 8;
	mach_port_t					object_name = 0;
	
	char						*data;
	vm_size_t					dataLength;
	
	TCaddress					*results = NULL;
	int							resultsAmount = 0;
	
	for (;;)
	{
		if ( (result = vm_region( processTask, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)(&info), &infoCnt, &object_name )) != KERN_SUCCESS )
		{
			if ( result != KERN_INVALID_ADDRESS )
			{
				CMLog( @"vm_region returned error: %i", result );
			}
			break;
		}
		
		if ( (info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE))
		{
			data = (char *)malloc( size );
			dataLength = size;
			
			if ( (result = vm_read_overwrite( processTask, address, size, (vm_address_t)data, &dataLength )) != KERN_SUCCESS && result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				free( data );
				break;
			}
			
			if ( result == KERN_SUCCESS )
			{
				//int				i, top = dataLength - vsize;
				
				if ( (results = realloc( results, TCAddressSize*resultsAmount + dataLength )) == NULL )
				{
					CMLog( @"ERROR: could not expand buffer" );
					exit(0);
				}
				
				resultsAmount += bmsearch( (char *)value, vsize, (char *)data, dataLength, (void *)address, (void **)((char *)results+TCAddressSize*resultsAmount) );
				//resultsAmount += TBM( (char *)value, vsize, data, dataLength, (void **)((char *)results+TCAddressSize*resultsAmount) );
				//resultsAmount += SMITH( data, dataLength, (char *)value, vsize, (void **)((char *)results+TCAddressSize*resultsAmount) );
				
				/*for ( i = 0; i < top; i++ )
				{
					if ( strncmp( value, data+i, vsize ) == 0 )
					{
						results[resultsAmount++] = (TCaddress)address + i;
					}
				}*/
			}
			
			free( data );
		}
		
		address += size;
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_INTEGER size:SIZE_8_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)firstSearchIntegerChar:(int8_t)value
{
	kern_return_t				result;
	
	vm_address_t				address = 0x0;
	vm_size_t					size = 0;
	vm_region_basic_info_data_t	info;
	mach_msg_type_number_t		infoCnt = 8;
	mach_port_t					object_name = 0;
	
	int8_t						*data;
	vm_size_t					dataLength;
	
	TCaddress					*results = NULL;
	int							resultsAmount = 0;
	
	for (;;)
	{
		if ( (result = vm_region( processTask, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)(&info), &infoCnt, &object_name )) != KERN_SUCCESS )
		{
			if ( result != KERN_INVALID_ADDRESS )
			{
				CMLog( @"vm_region returned error: %i", result );
			}
			break;
		}
		
		if ( (info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE))
		{
			data = (int8_t *)malloc( size );
			dataLength = size;
			
			if ( (result = vm_read_overwrite( processTask, address, size, (vm_address_t)data, &dataLength )) != KERN_SUCCESS && result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				free( data );
				break;
			}
			
			if ( result == KERN_SUCCESS )
			{
				int				i;
				
				if ( (results = (TCaddress *)realloc( results, TCAddressSize*resultsAmount + TCAddressSize*dataLength )) == NULL )
				{
					CMLog( @"ERROR: could not expand buffer" );
					exit(0);
				}
				
				for ( i = 0; i < dataLength; i++ )
				{
					if ( *(data+i) == value )
					{
						results[resultsAmount++] = (TCaddress)address + i;
					}
				}
			}
			
			free( data );
		}
		
		address += size;
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_INTEGER size:SIZE_8_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)firstSearchIntegerShort:(int16_t)value
{
	kern_return_t				result;
	
	vm_address_t				address = 0x0;
	vm_size_t					size = 0;
	vm_region_basic_info_data_t	info;
	mach_msg_type_number_t		infoCnt = 8;
	mach_port_t					object_name = 0;
	
	int16_t						*data;
	vm_size_t					dataLength;
	
	TCaddress					*results = NULL;
	int							resultsAmount = 0;
	
	for (;;)
	{
		if ( (result = vm_region( processTask, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)(&info), &infoCnt, &object_name )) != KERN_SUCCESS )
		{
			if ( result != KERN_INVALID_ADDRESS )
			{
				CMLog( @"vm_region returned error: %i", result );
			}
			break;
		}
		
		if ( (info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE))
		{
			data = (int16_t *)malloc( size );
			dataLength = size;
			
			if ( (result = vm_read_overwrite( processTask, address, size, (vm_address_t)data, &dataLength )) != KERN_SUCCESS && result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				free( data );
				break;
			}
			
			if ( result == KERN_SUCCESS )
			{
				int				i, top = dataLength / sizeof(value);
				
				if ( (results = (TCaddress *)realloc( results, TCAddressSize*resultsAmount + 2*dataLength )) == NULL )
				{
					CMLog( @"ERROR: could not expand buffer" );
					exit(0);
				}
				
				for ( i = 0; i < top; i++ )
				{
					if ( *(data+i) == value )
					{
						results[resultsAmount++] = (TCaddress)address + i * sizeof(value);
					}
				}
			}
			
			free( data );
		}
		
		address += size;
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_INTEGER size:SIZE_16_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)firstSearchIntegerLong:(int32_t)value
{
	kern_return_t				result;
	
	vm_address_t				address = 0x0;
	vm_size_t					size = 0;
	vm_region_basic_info_data_t	info;
	mach_msg_type_number_t		infoCnt = 8;
	mach_port_t					object_name = 0;
	
	int32_t						*data;
	vm_size_t					dataLength;
	
	TCaddress					*results = NULL;
	int							resultsAmount = 0;
	
	/*unsigned					zone_count = 10;
	vm_address_t				*zones = (vm_address_t *)malloc( zone_count * sizeof(vm_address_t) );
	//memory_reader_t				reader;
	
	if ( (result = malloc_get_all_zones( processTask, NULL, &zones, &zone_count )) != KERN_SUCCESS )
	{
		CMLog( @"malloc_get_all_zones error: %i", result );
	}
	else
	{
		//address = zones[0];
		
		int			i;
		
		for ( i = 0; i < 10; i++ )
		{
			CMLog( @"malloc_get_all_zones[%i] = %X", i, (vm_address_t)zones[i] );
		}
	}*/
	
	for (;;)
	{
		if ( (result = vm_region( processTask, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)(&info), &infoCnt, &object_name )) != KERN_SUCCESS )
		{
			if ( result != KERN_INVALID_ADDRESS )
			{
				CMLog( @"vm_region returned error: %i", result );
			}
			break;
		}
		
		if ( (info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE) )
		{
			data = (int32_t *)malloc( size );
			dataLength = size;
			
			//CMLog( @"address: %.8X size: %i", address, size );
			
			if ( (result = vm_read_overwrite( processTask, address, size, (vm_address_t)data, &dataLength )) != KERN_SUCCESS && result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				free( data );
				break;
			}
			
			if ( result == KERN_SUCCESS )
			{
				int				i, top = dataLength / sizeof(value);
				
				if ( (results = (TCaddress *)realloc( results, TCAddressSize*resultsAmount + dataLength )) == NULL )
				{
					CMLog( @"ERROR: could not expand buffer" );
					exit(0);
				}

				for ( i = 0; i < top; i++ )
				{
					if ( *(data+i) == value )
					{
						results[resultsAmount++] = (TCaddress)address + i * sizeof(value);
					}
				}
			}
			
			free( data );
		}
		
		address += size;
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_INTEGER size:SIZE_32_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)firstSearchDecimalFloat:(float)value
{
	kern_return_t				result;
	
	vm_address_t				address = 0x0;
	vm_size_t					size = 0;
	vm_region_basic_info_data_t	info;
	mach_msg_type_number_t		infoCnt = 8;
	mach_port_t					object_name = 0;
	
	float						*data;
	vm_size_t					dataLength;
	
	TCaddress					*results = NULL;
	int							resultsAmount = 0;
	
	for (;;)
	{
		if ( (result = vm_region( processTask, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)(&info), &infoCnt, &object_name )) != KERN_SUCCESS )
		{
			if ( result != KERN_INVALID_ADDRESS )
			{
				CMLog( @"vm_region returned error: %i", result );
			}
			break;
		}
		
		if ( (info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE))
		{
			data = (float *)malloc( size );
			dataLength = size;
			
			if ( (result = vm_read_overwrite( processTask, address, size, (vm_address_t)data, &dataLength )) != KERN_SUCCESS && result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				free( data );
				break;
			}
			
			if ( result == KERN_SUCCESS )
			{
				int				i, top = dataLength / sizeof(value);
				
				if ( (results = realloc( results, TCAddressSize*resultsAmount + dataLength )) == NULL )
				{
					CMLog( @"ERROR: could not expand buffer" );
					exit(0);
				}
				
				for ( i = 0; i < top; i++ )
				{
					if ( CMCompareFloatsWithEpsilon( *(data+i), value, 0.1f ) == 0 )
					{
						results[resultsAmount++] = (TCaddress)address + i * sizeof(value);
					}
				}
			}
			
			free( data );
		}
		
		address += size;
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_DECIMAL size:SIZE_32_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)firstSearchDecimalDouble:(double)value
{
	kern_return_t				result;
	
	vm_address_t				address = 0x0;
	vm_size_t					size = 0;
	vm_region_basic_info_data_t	info;
	mach_msg_type_number_t		infoCnt = 8;
	mach_port_t					object_name = 0;
	
	double						*data;
	vm_size_t					dataLength;
	
	TCaddress					*results = NULL;
	int							resultsAmount = 0;
	
	CMLog( @"float search" );
	
	for (;;)
	{
		if ( (result = vm_region( processTask, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)(&info), &infoCnt, &object_name )) != KERN_SUCCESS )
		{
			if ( result != KERN_INVALID_ADDRESS )
			{
				CMLog( @"vm_region returned error: %i", result );
			}
			break;
		}
		
		if ( (info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE))
		{
			data = (double *)malloc( size );
			dataLength = size;
			
			if ( (result = vm_read_overwrite( processTask, address, size, (vm_address_t)data, &dataLength )) != KERN_SUCCESS && result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				free( data );
				break;
			}
			
			if ( result == KERN_SUCCESS )
			{
				int				i, top = dataLength / sizeof(value);
				
				if ( (results = realloc( results, TCAddressSize*resultsAmount + dataLength )) == NULL )
				{
					CMLog( @"ERROR: could not expand buffer" );
					exit(0);
				}
				
				for ( i = 0; i < top; i++ )
				{
					if ( CMCompareDoublesWithEpsilon( *(data+i), value, 0.1 ) == 0 )
					{
						results[resultsAmount++] = (TCaddress)address + i * sizeof(value);
					}
				}
			}
			
			free( data );
		}
		
		address += size;
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_DECIMAL size:SIZE_64_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}


- (void)searchString8bit:(char const *)value size:(int)vsize
{
	kern_return_t				result;
	
	char						*data;
	vm_size_t					dataLength;
	
	TCaddress					*results;
	int							resultsAmount = 0;
	
	SearchResults				*lastResults = [searchResults lastObject];
	TCaddress					*lastResultsData = [lastResults data];
	int							i, lastResultsAmount = [lastResults amount];
	
	if ( [lastResults type] != TYPE_INTEGER || [lastResults size] != SIZE_8_BIT )
	{
		[self sendError:@"This search is incompatible with the previous search." fatal:NO];
		return;
	}
	
	if ( (data = (char *)malloc( vsize )) == NULL )
	{
		CMLog( @"ERROR: could not create buffer" );
		
		[self sendError:@"The server cancelled the search because it ran out of memory." fatal:NO];
		return;
	}
	
	if ( (results = (TCaddress *)malloc( TCAddressSize*lastResultsAmount )) == NULL )
	{
		CMLog( @"ERROR: could not create buffer" );
		
		[self sendError:@"The server cancelled the search because it ran out of memory." fatal:NO];
		free( data );
		return;
	}
	
	for ( i = 0; i < lastResultsAmount; i++ )
	{
		TCaddress		address = lastResultsData[i];
		
		//dataLength = sizeof(data);
		
		if ( (result = vm_read_overwrite( processTask, address, vsize, (vm_address_t)(data), &dataLength )) == KERN_SUCCESS )
		{
			if ( memcmp( data, value, dataLength ) == 0 )
			{
				results[resultsAmount++] = address;
			}
		}
		else
		{
			if ( result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				break;
			}
		}
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_INTEGER size:SIZE_8_BIT data:results amount:resultsAmount]];
	
	free( data );
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)searchIntegerChar:(int8_t)value
{
	kern_return_t				result;
	
	int8_t						data;
	vm_size_t					dataLength;
	
	TCaddress					*results;
	int							resultsAmount = 0;
	
	SearchResults				*lastResults = [searchResults lastObject];
	TCaddress					*lastResultsData = [lastResults data];
	int							i, lastResultsAmount = [lastResults amount];
	
	if ( [lastResults type] != TYPE_INTEGER || [lastResults size] != SIZE_8_BIT )
	{
		[self sendError:@"This search is incompatible with the previous search." fatal:NO];
		return;
	}
	
	if ( (results = (TCaddress *)malloc( TCAddressSize*lastResultsAmount )) == NULL )
	{
		CMLog( @"ERROR: could not create buffer" );
		
		[self sendError:@"The server cancelled the search because it ran out of memory." fatal:NO];
		return;
	}
	
	for ( i = 0; i < lastResultsAmount; i++ )
	{
		TCaddress		address = lastResultsData[i];
		
		dataLength = sizeof(data);
		
		if ( (result = vm_read_overwrite( processTask, address, sizeof(data), (vm_address_t)(&data), &dataLength )) == KERN_SUCCESS )
		{
			if ( data == value )
			{
				results[resultsAmount++] = address;
			}
		}
		else
		{
			if ( result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				break;
			}
		}
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_INTEGER size:SIZE_8_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)searchIntegerShort:(int16_t)value
{
	kern_return_t				result;
	
	int16_t						data;
	vm_size_t					dataLength;
	
	TCaddress					*results;
	int							resultsAmount = 0;
	
	SearchResults				*lastResults = [searchResults lastObject];
	TCaddress					*lastResultsData = [lastResults data];
	int							i, lastResultsAmount = [lastResults amount];
	
	if ( [lastResults type] != TYPE_INTEGER || [lastResults size] != SIZE_16_BIT )
	{
		[self sendError:@"This search is incompatible with the previous search." fatal:NO];
		return;
	}
	
	if ( (results = (TCaddress *)malloc( TCAddressSize*lastResultsAmount )) == NULL )
	{
		CMLog( @"ERROR: could not create buffer" );
		
		[self sendError:@"The server cancelled the search because it ran out of memory." fatal:NO];
		return;
	}
	
	for ( i = 0; i < lastResultsAmount; i++ )
	{
		TCaddress		address = lastResultsData[i];
		
		dataLength = sizeof(data);
		
		if ( (result = vm_read_overwrite( processTask, address, sizeof(data), (vm_address_t)(&data), &dataLength )) == KERN_SUCCESS )
		{
			if ( data == value )
			{
				results[resultsAmount++] = address;
			}
		}
		else
		{
			if ( result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				break;
			}
		}
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_INTEGER size:SIZE_16_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)searchIntegerLong:(int32_t)value
{
	kern_return_t				result;
	
	int32_t						data;
	vm_size_t					dataLength;
	
	TCaddress					*results;
	int							resultsAmount = 0;
	
	SearchResults				*lastResults = [searchResults lastObject];
	TCaddress					*lastResultsData = [lastResults data];
	int							i, lastResultsAmount = [lastResults amount];
	
	if ( [lastResults type] != TYPE_INTEGER || [lastResults size] != SIZE_32_BIT )
	{
		[self sendError:@"This search is incompatible with the previous search." fatal:NO];
		return;
	}
	
	if ( (results = (TCaddress *)malloc( TCAddressSize*lastResultsAmount )) == NULL )
	{
		CMLog( @"ERROR: could not create buffer" );
		
		[self sendError:@"The server cancelled the search because it ran out of memory." fatal:NO];
		return;
	}
	
	for ( i = 0; i < lastResultsAmount; i++ )
	{
		TCaddress		address = lastResultsData[i];
		
		dataLength = sizeof(data);
		
		if ( (result = vm_read_overwrite( processTask, address, sizeof(data), (vm_address_t)(&data), &dataLength )) == KERN_SUCCESS )
		{
			if ( data == value )
			{
				results[resultsAmount++] = address;
			}
		}
		else
		{
			if ( result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				break;
			}
		}
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_INTEGER size:SIZE_32_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)searchDecimalFloat:(float)value
{
	kern_return_t				result;
	
	float						data;
	vm_size_t					dataLength;
	
	TCaddress					*results;
	int							resultsAmount = 0;
	
	SearchResults				*lastResults = [searchResults lastObject];
	TCaddress					*lastResultsData = [lastResults data];
	int							i, lastResultsAmount = [lastResults amount];
	
	if ( [lastResults type] != TYPE_DECIMAL || [lastResults size] != SIZE_32_BIT )
	{
		[self sendError:@"This search is incompatible with the previous search." fatal:NO];
		return;
	}
	
	if ( (results = (TCaddress *)malloc( TCAddressSize*lastResultsAmount )) == NULL )
	{
		CMLog( @"ERROR: could not create buffer" );
		
		[self sendError:@"The server cancelled the search because it ran out of memory." fatal:NO];
		return;
	}
	
	for ( i = 0; i < lastResultsAmount; i++ )
	{
		TCaddress		address = lastResultsData[i];
		
		dataLength = sizeof(data);
		
		if ( (result = vm_read_overwrite( processTask, address, sizeof(data), (vm_address_t)(&data), &dataLength )) == KERN_SUCCESS )
		{
			if ( CMCompareFloatsWithEpsilon( data, value, 0.1f ) == 0 )
			{
				results[resultsAmount++] = address;
			}
		}
		else
		{
			if ( result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				break;
			}
		}
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_DECIMAL size:SIZE_32_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}

- (void)searchDecimalDouble:(double)value
{
	kern_return_t				result;
	
	double						data;
	vm_size_t					dataLength;
	
	TCaddress					*results;
	int							resultsAmount = 0;
	
	SearchResults				*lastResults = [searchResults lastObject];
	TCaddress					*lastResultsData = [lastResults data];
	int							i, lastResultsAmount = [lastResults amount];
	
	if ( [lastResults type] != TYPE_DECIMAL || [lastResults size] != SIZE_64_BIT )
	{
		[self sendError:@"This search is incompatible with the previous search." fatal:NO];
		return;
	}
	
	if ( (results = (TCaddress *)malloc( TCAddressSize*lastResultsAmount )) == NULL )
	{
		CMLog( @"ERROR: could not create buffer" );
		
		[self sendError:@"The server cancelled the search because it ran out of memory." fatal:NO];
		return;
	}
	
	for ( i = 0; i < lastResultsAmount; i++ )
	{
		TCaddress		address = lastResultsData[i];
		
		dataLength = sizeof(data);
		
		if ( (result = vm_read_overwrite( processTask, address, sizeof(data), (vm_address_t)(&data), &dataLength )) == KERN_SUCCESS )
		{
			if ( CMCompareDoublesWithEpsilon( data, value, 0.1 ) == 0 )
			{
				results[resultsAmount++] = address;
			}
		}
		else
		{
			if ( result != KERN_PROTECTION_FAILURE )
			{
				CMLog( @"vm_read_overwrite returned error: %i", result );
				break;
			}
		}
	}
	
	realloc( results, TCAddressSize*resultsAmount );
	[searchResults addObject:[SearchResults resultsWithType:TYPE_DECIMAL size:SIZE_64_BIT data:results amount:resultsAmount]];
	
	CMLog( @"found %i of %i", resultsAmount, value );
}


- (void)changeString8bit:(char const *)value size:(int)vsize addresses:(TCaddress *)addresses count:(int)count
{
	int					failCount = 0;
	int					i;
	
	for ( i = 0; i < count; i++ )
	{
		if ( vm_write( processTask, (vm_address_t)addresses[i], (vm_offset_t)value, vsize ) != KERN_SUCCESS )
		{
			failCount++;
		}
	}
	
	if ( failCount > 0 )
	{
		[self sendError:[NSString stringWithFormat:@"%i of the selected variables could not be changed.", failCount] fatal:NO];
	}
}

- (void)changeIntegerChar:(int8_t)value addresses:(TCaddress *)addresses count:(int)count
{
	int					failCount = 0;
	int					i;
	
	for ( i = 0; i < count; i++ )
	{
		if ( vm_write( processTask, (vm_address_t)addresses[i], (vm_offset_t)(&value), sizeof(value) ) != KERN_SUCCESS )
		{
			failCount++;
		}
	}
	
	if ( failCount > 0 )
	{
		[self sendError:[NSString stringWithFormat:@"%i of the selected variables could not be changed.", failCount] fatal:NO];
	}
}

- (void)changeIntegerShort:(int16_t)value addresses:(TCaddress *)addresses count:(int)count
{
	int					failCount = 0;
	int					i;
	
	for ( i = 0; i < count; i++ )
	{
		if ( vm_write( processTask, (vm_address_t)addresses[i], (vm_offset_t)(&value), sizeof(value) ) != KERN_SUCCESS )
		{
			failCount++;
		}
	}
	
	if ( failCount > 0 )
	{
		[self sendError:[NSString stringWithFormat:@"%i of the selected variables could not be changed.", failCount] fatal:NO];
	}
}

- (void)changeIntegerLong:(int32_t)value addresses:(TCaddress *)addresses count:(int)count
{
	int					failCount = 0;
	int					i;
	
	for ( i = 0; i < count; i++ )
	{
		if ( vm_write( processTask, (vm_address_t)addresses[i], (vm_offset_t)(&value), sizeof(value) ) != KERN_SUCCESS )
		{
			failCount++;
		}
	}
	
	if ( failCount > 0 )
	{
		[self sendError:[NSString stringWithFormat:@"%i of the selected variables could not be changed.", failCount] fatal:NO];
	}
}

- (void)changeDecimalFloat:(float)value addresses:(TCaddress *)addresses count:(int)count
{
	int					failCount = 0;
	int					i;
	
	for ( i = 0; i < count; i++ )
	{
		if ( vm_write( processTask, (vm_address_t)addresses[i], (vm_offset_t)(&value), sizeof(value) ) != KERN_SUCCESS )
		{
			failCount++;
		}
	}
	
	if ( failCount > 0 )
	{
		[self sendError:[NSString stringWithFormat:@"%i of the selected variables could not be changed.", failCount] fatal:NO];
	}
}

- (void)changeDecimalDouble:(double)value addresses:(TCaddress *)addresses count:(int)count
{
	int					failCount = 0;
	int					i;
	
	for ( i = 0; i < count; i++ )
	{
		if ( vm_write( processTask, (vm_address_t)addresses[i], (vm_offset_t)(&value), sizeof(value) ) != KERN_SUCCESS )
		{
			failCount++;
		}
	}
	
	if ( failCount > 0 )
	{
		[self sendError:[NSString stringWithFormat:@"%i of the selected variables could not be changed.", failCount] fatal:NO];
	}
}


- (void)sendProcessList
{
	NSArray			*processList = [rootProxy serverProcessList];
	
	NSNumber		*pid;
	u_int32_t		pidNum;
	NSString		*name;

	PacketHeader	header;

	char			*buffer, *ptr;

	//                       PROCESS COUNT
	int				length = sizeof(u_int32_t);
	int				lengthAfter;

	u_int32_t		processCount = [processList count];

	int				i, max = processCount;

	header.checksum = RandomChecksum();
	header.function = 2;

	for ( i = 0; i < max; i++ )
	{
		pid = [[processList objectAtIndex:i] objectForKey:@"NSApplicationProcessIdentifier"];
		name = [[processList objectAtIndex:i] objectForKey:@"NSApplicationName"];

		//        PID                 NAME
		length += sizeof(u_int32_t) + [name length] + 1;
	}

	header.size = length;
	length += sizeof(header);
	//        HEADER

	if ( (buffer = (char *)malloc( length ))==NULL )
	{
		CMLog( @"sendProcessList failed" );
		return;
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, &processCount, sizeof(processCount) );

	for ( i = 0; i < max; i++ )
	{
		pidNum = [[[processList objectAtIndex:i] objectForKey:@"NSApplicationProcessIdentifier"] unsignedLongValue];
		name = [[processList objectAtIndex:i] objectForKey:@"NSApplicationName"];

		COPY_TO_BUFFER( ptr, &pidNum, sizeof(pid) );
		COPY_TO_BUFFER( ptr, [name lossyCString], [name length] + 1 );
	}

	lengthAfter = length;

	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendProcessList failed" );
	}

	free( buffer );
}


- (void)sendSearchFinished
{
	PacketHeader	header;
	int				length = sizeof(header);

	header.checksum = RandomChecksum();
	header.function = 6;
	header.size = 0;

	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendSearchFinished failed" );
	}
}

- (void)sendVariableList:(TCaddress const *)data amount:(int)amount
{
	PacketHeader	header;
	int				length;
	int				lengthAfter;
	int				displayAmount = ( searchResultsAmountDisplayed > amount )? amount : searchResultsAmountDisplayed;
	int				resultsLength = TCAddressSize * displayAmount;

	char			*buffer, *ptr;

	header.checksum = RandomChecksum();
	header.function = 7;
	header.size = sizeof(amount) + sizeof(displayAmount) + resultsLength;
	//            AMOUNT           DISPLAY AMOUNT          DATA

	lengthAfter = length = header.size + sizeof(header);

	if ( (buffer = (char *)malloc( length )) == NULL )
	{
		CMLog( @"sendVariableList:amount: failed" );
		return;
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, &amount, sizeof(amount) );
	COPY_TO_BUFFER( ptr, &displayAmount, sizeof(displayAmount) );
	COPY_TO_BUFFER( ptr, data, resultsLength );

	if ( SendBuffer( sockfd, buffer, &length ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendVariableList:amount: failed" );
	}

	free( buffer );
	
	CMLog( @"SERVER sending %i out of %i results", displayAmount, amount );
}

- (void)sendChangeFinished
{
	PacketHeader	header;
	int				length = sizeof(header);

	header.checksum = RandomChecksum();
	header.function = 9;
	header.size = 0;

	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendChangeFinished failed" );
	}
}

- (void)sendError:(NSString *)msg fatal:(BOOL)fatal
{
	PacketHeader	header;
	int				length;
	int				lengthAfter;

	u_int32_t		type = (fatal)? 1:0;

	char			*buffer, *ptr;

	header.checksum = RandomChecksum();
	header.function = 11;
	header.size = sizeof(type) + [msg length] + 1;
	//            FATAL          STRING

	lengthAfter = length = header.size + sizeof(header);

	if ( (buffer = (char *)malloc( length )) == NULL )
	{
		CMLog( @"sendError:fatal: failed" );
		return;
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, &type, sizeof(type) );
	COPY_TO_BUFFER( ptr, [msg lossyCString], [msg length] + 1 );

	if ( SendBuffer( sockfd, buffer, &length ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendError:fatal: failed" );
	}

	free( buffer );
}

- (void)sendVariableValue:(u_int32_t)index
{

}

- (void)sendUndoFinished
{
	PacketHeader	header;
	int				length = sizeof(header);

	header.checksum = RandomChecksum();
	header.function = 15;
	header.size = 0;

	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendUndoFinished failed" );
	}
}

- (void)sendRedoFinished
{
	PacketHeader	header;
	int				length = sizeof(header);

	header.checksum = RandomChecksum();
	header.function = 17;
	header.size = 0;

	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendRedoFinished failed" );
	}
}

- (void)sendUndoRedoStatus
{
	PacketHeader	header;
	int				length;
	int				lengthAfter;
	
	u_int32_t		undoCount = (u_int32_t)[searchResults count];
	u_int32_t		redoCount = (u_int32_t)[searchResultsUndone count];
	
	char			*buffer, *ptr;
	
	header.checksum = RandomChecksum();
	header.function = 19;
	header.size = 2 * sizeof(u_int32_t);
	
	length = lengthAfter = sizeof(header) + header.size;
	
	if ( (buffer = (char *)malloc( length )) == NULL )
	{
		CMLog( @"sendSetTargetPID: failed" );
	}
	
	ptr = buffer;
	
	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, &undoCount, sizeof(undoCount) );
	COPY_TO_BUFFER( ptr, &redoCount, sizeof(redoCount) );
	
	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendUndoRedoStatus: failed" );
	}
	
	free( buffer );
}

- (void)sendAppLaunched:(NSDictionary *)appInfo
{
	PacketHeader	header;

	char			*buffer, *ptr;

	int				length = 0;
	int				lengthAfter;

	u_int32_t		pid = [[appInfo objectForKey:@"NSApplicationProcessIdentifier"] unsignedLongValue];
	NSString		*name = [appInfo objectForKey:@"NSApplicationName"];

	//        PID                 NAME
	length += sizeof(u_int32_t) + [name length] + 1;

	header.checksum = RandomChecksum();
	header.function = 21;
	header.size = length;

	length += sizeof(header);
	//        HEADER

	if ( (buffer = (char *)malloc( length ))==NULL )
	{
		CMLog( @"sendAppLaunched: failed" );

		return;
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, &pid, sizeof(pid) );
	COPY_TO_BUFFER( ptr, [name lossyCString], [name length] + 1 );

	lengthAfter = length;

	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendAppLaunched: failed" );
	}

	free( buffer );
}


- (void)sendAppQuit:(NSDictionary *)appInfo
{
	PacketHeader	header;

	char			*buffer, *ptr;

	int				length = 0;
	int				lengthAfter;

	u_int32_t		pid = [[appInfo objectForKey:@"NSApplicationProcessIdentifier"] unsignedLongValue];

	//        PID
	length += sizeof(pid);

	header.checksum = RandomChecksum();
	header.function = 22;
	header.size = length;

	length += sizeof(header);
	//        HEADER

	if ( (buffer = (char *)malloc( length ))==NULL )
	{
		CMLog( @"sendAppQuit: failed" );

		return;
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, &pid, sizeof(pid) );

	lengthAfter = length;

	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendAppQuit: failed" );
	}

	free( buffer );
}

- (void)sendTargetAppQuit
{
	PacketHeader	header;
	int				length = sizeof(header);

	header.checksum = RandomChecksum();
	header.function = 23;
	header.size = 0;

	if ( SendBuffer( sockfd, (char *)(&header), &length ) == -1 || length != sizeof(header) )
	{
		CMLog( @"sendTargetAppQuit failed" );
	}
}

- (void)sendPauseFinished:(BOOL)paused
{
	PacketHeader	header;

	char			*buffer, *ptr;

	//                       PAUSED
	int				length = sizeof(paused);
	int				lengthAfter;

	header.checksum = RandomChecksum();
	header.function = 24;
	header.size = length;

	length += sizeof(header);
	//        HEADER

	if ( (buffer = (char *)malloc( length ))==NULL )
	{
		CMLog( @"sendPauseFinished: failed" );

		return;
	}

	ptr = buffer;

	COPY_TO_BUFFER( ptr, &header, sizeof(header) );
	COPY_TO_BUFFER( ptr, &paused, sizeof(paused) );

	lengthAfter = length;

	if ( SendBuffer( sockfd, buffer, &lengthAfter ) == -1 || lengthAfter != length )
	{
		CMLog( @"sendPauseFinished: failed" );
	}

	free( buffer );
}


- (void)handleClearSearch
{
	[searchResults removeAllObjects];
	[searchResultsUndone removeAllObjects];
	
	[self unpause];
}

- (void)handleSearch:(char const *)data size:(int)dataSize
{
	TCtype			type;
	TCsize			size;
	
	char			*ptr = (char *)data;

	[self setAction:@"Searching"];

	COPY_FROM_BUFFER( &type, ptr, sizeof(type) );
	COPY_FROM_BUFFER( &size, ptr, sizeof(size) );
	
	// receive the amount of results to return
	COPY_FROM_BUFFER( &searchResultsAmountDisplayed, ptr, sizeof(searchResultsAmountDisplayed) );

	if ( ![searchResults lastObject] )
	{
		switch ( type )
		{
			case TYPE_STRING:
			{
				switch ( size )
				{
					case SIZE_8_BIT:
					{
						[self firstSearchString8bit:ptr size:(dataSize - (ptr - data) - 1)];
					}
						break;
				}
			}
				break;

			case TYPE_INTEGER:
			{
				switch ( size )
				{
					case SIZE_8_BIT:
					{
						int8_t			value;

						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self firstSearchIntegerChar:value];
					}
						break;

					case SIZE_16_BIT:
					{
						int16_t			value;

						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self firstSearchIntegerShort:value];
					}
						break;

					case SIZE_32_BIT:
					{
						int32_t			value;

						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self firstSearchIntegerLong:value];
					}
						break;
				}
			}
				break;

			case TYPE_DECIMAL:
			{
				switch ( size )
				{
					case SIZE_32_BIT:
					{
						float			value;

						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self firstSearchDecimalFloat:value];
					}
						break;

					case SIZE_64_BIT:
					{
						double			value;

						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self firstSearchDecimalDouble:value];
					}
						break;
				}
			}
				break;
		}
	}
	else
	{
		switch ( type )
		{
			case TYPE_STRING:
			{
				switch ( size )
				{
					case SIZE_8_BIT:
					{
						[self searchString8bit:ptr size:(dataSize - (ptr - data))];
						
						break;
					}
				}
			}
				break;

			case TYPE_INTEGER:
			{
				switch ( size )
				{
					case SIZE_8_BIT:
					{
						int8_t			value;

						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self searchIntegerChar:value];
						
						break;
					}

					case SIZE_16_BIT:
					{
						int16_t			value;

						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self searchIntegerShort:value];
						
						break;
					}

					case SIZE_32_BIT:
					{
						int32_t			value;

						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self searchIntegerLong:value];
						
						break;
					}
				}
			}
				break;

			case TYPE_DECIMAL:
			{
				switch ( size )
				{
					case SIZE_32_BIT:
					{
						float			value;
						
						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self searchDecimalFloat:value];
					}
						break;

					case SIZE_64_BIT:
					{
						double			value;

						COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
						[self searchDecimalDouble:value];
					}
						break;
				}
			}
				break;
		}
	}

	[self sendVariableList:[(SearchResults *)[searchResults lastObject] data] amount:[[searchResults lastObject] amount]];
	[self sendSearchFinished];
	[self sendUndoRedoStatus];

	[self setAction:nil];
}

- (void)handleChange:(char const *)data size:(int)dataSize
{
	TCtype			type;
	TCsize			size;
	
	TCaddress		*addresses = NULL;
	int				count;
	
	char			*ptr = (char *)data;
	
	[self setAction:@"Changing"];
	
	// read out the type and size of the variable.
	COPY_FROM_BUFFER( &type, ptr, sizeof(type) );
	COPY_FROM_BUFFER( &size, ptr, sizeof(size) );
	
	// read the amount of addresses.
	COPY_FROM_BUFFER( &count, ptr, sizeof(count) );
	
	// save the pointer to the addresses.
	addresses = (TCaddress *)ptr;
	ptr += TCAddressSize*count;
	
	switch ( type )
	{
		case TYPE_STRING:
		{
			switch ( size )
			{
				case SIZE_8_BIT:
				{
					[self changeString8bit:ptr size:(dataSize - (ptr - data)) addresses:addresses count:count];
				}
					break;
			}
		}
			break;
			
		case TYPE_INTEGER:
		{
			switch ( size )
			{
				case SIZE_8_BIT:
				{
					int8_t			value;
					
					COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
					[self changeIntegerChar:value addresses:addresses count:count];
				}
					break;
					
				case SIZE_16_BIT:
				{
					int16_t			value;
					
					COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
					[self changeIntegerShort:value addresses:addresses count:count];
				}
					break;
					
				case SIZE_32_BIT:
				{
					int32_t			value;
					
					COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
					[self changeIntegerLong:value addresses:addresses count:count];
				}
					break;
			}
		}
			break;
			
		case TYPE_DECIMAL:
		{
			switch ( size )
			{
				case SIZE_32_BIT:
				{
					float			value;
					
					COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
					[self changeDecimalFloat:value addresses:addresses count:count];
				}
					break;
					
				case SIZE_64_BIT:
				{
					double			value;
					
					COPY_FROM_BUFFER( &value, ptr, sizeof(value) );
					[self changeDecimalDouble:value addresses:addresses count:count];
				}
					break;
			}
		}
			break;
	}
	
	[self sendChangeFinished];
	
	[self setAction:nil];
}

- (void)handlePauseTarget
{
	if ( !processPaused )
	{
		int			wait_status;
		
		NS_DURING
		{
			if ( ptrace( PT_ATTACH, processID, 0, 0 ) != -1 )
			{
				if ( waitpid( processID, &wait_status, WUNTRACED ) == processID )
				{
					if ( WIFSTOPPED(wait_status) )
					{
						processPaused = YES;
						[self sendPauseFinished:YES];
					}
					else
					{
						CMLog( @"ERROR: process couldn't be paused" );
						[self sendPauseFinished:NO];
						[self sendError:@"Could not pause target because of an unknown error." fatal:NO];
					}
				}
				else
				{
					CMLog( @"ERROR: process couldn't be paused" );
					[self sendPauseFinished:NO];
					[self sendError:@"Could not pause target because of an unknown error." fatal:NO];
				}
			}
			else
			{
				CMLog( @"ERROR: process couldn't be paused" );
				[self sendPauseFinished:NO];
				
				switch ( errno )
				{
					case ESRCH:
						[self sendError:@"Could not pause target because there is no valid target to pause." fatal:NO];
						break;
						
					case EINVAL:
						[self sendError:@"Could not pause target because a process cannot pause itself." fatal:NO];
						break;
						
					case EBUSY:
						[self sendError:@"Could not pause target because the target is being controlled by another instance or application." fatal:NO];
						break;
						
					case EPERM:
						[self sendError:@"Could not pause target because this type of application cannot be paused." fatal:NO];
						break;
						
					default:
						[self sendError:@"Could not pause target because of an unknown error." fatal:NO];
						break;
				}
			}
		}
		NS_HANDLER
		{
			[self sendPauseFinished:NO];
			[self sendError:[NSString stringWithFormat:@"Could not pause target because an exception (%@) was raised: %@", [localException name], [localException reason]] fatal:NO];
		}
		NS_ENDHANDLER
	}
	else
	{
		ptrace( PT_DETACH, processID, 0, 0 );

		processPaused = NO;
		[self sendPauseFinished:NO];
	}
}

- (void)handleUndo
{
	SearchResults		*results = [searchResults lastObject];
	
	if ( results )
	{
		[searchResultsUndone addObject:results];
		[searchResults removeLastObject];
	}

	results = [searchResults lastObject];
	if ( results )
	{
		[self sendVariableList:[results data] amount:[results amount]];
	}
	else
	{
		[self sendVariableList:NULL amount:0];
	}
	
	[self sendUndoFinished];
	[self sendUndoRedoStatus];
}

- (void)handleRedo
{
	SearchResults		*results = [searchResultsUndone lastObject];
	
	if ( results )
	{
		[searchResults addObject:results];
		[searchResultsUndone removeLastObject];
	}

	results = [searchResults lastObject];
	if ( results )
	{
		[self sendVariableList:[results data] amount:[results amount]];
	}
	else
	{
		[self sendVariableList:NULL amount:0];
	}
	
	[self sendRedoFinished];
	[self sendUndoRedoStatus];
}

- (void)handleSetTargetPID:(char const *)data size:(int)size
{
	char			*ptr = (char *)data;

	pid_t			pid;

	COPY_FROM_BUFFER( &pid, ptr, sizeof(pid) );

	[self setPID:pid];
}


- (void)unpause
{
	if ( processPaused )
	{
		[self handlePauseTarget];
	}
}

- (void)setPID:(pid_t)pid
{
	kern_return_t				result;

	[self unpause];
	
	processID = pid;

	if ( (result = task_for_pid( current_task(), processID, &processTask)) != KERN_SUCCESS )
	{
		CMLog( @"task_for_pid returned error: %i", result );
	}
}


- (void)dealloc
{
	[self unpause];

	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	[searchResults release];
	[searchResultsUndone release];

	[super dealloc];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   NSWorkspaceDidLaunchApplicationNotification Notification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)processListChanged:(NSNotification *)note
{
	pid_t			pid = [[[note userInfo] objectForKey:@"NSApplicationProcessIdentifier"] intValue];

	if ( /*pid != getpid()*/ sockfd != -1 )
	{
		if ( [[note name] isEqualToString:@"NSWorkspaceDidLaunchApplicationNotification"] )
		{
			[self sendAppLaunched:[note userInfo]];
		}
		else
		{
			[self sendAppQuit:[note userInfo]];

			if ( pid == processID )
			{
				[self sendTargetAppQuit];

				// we can't set the new target here because this method is not called
				// in the server thread.  the client will have to change it.
				//[self setPID:[rootProxy serverFirstProcess]];
				processPaused = NO;
			}
		}
	}
}


@end


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   Internal Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


#define ASIZE 256
int bmsearch( char *pat, int m, char *text, int n, void *base, void *loc[] )
{
	int count = 0;
	int i, j, k, skip[ASIZE];
	
	if( m==0 ) return 0;
	for( k=0; k<ASIZE; k++ ) skip[k] = m;
	for( k=0; k<m-1; k++ ) skip[(int)pat[k]] = m-k-1;
	
	for( k=m-1; k < n; k += skip[(int)text[k] & (ASIZE-1)] ) {
		for( j=m-1, i=k; j>=0 && text[i] == pat[j]; j-- ) i--;
		if( j == (-1) )
			/* SAVE LOCATION */
			loc[count++] = (void *)( base+i+1 );
			//return( text+i+1 );
	}
	return count;
}

/*
BOOL compare_float( float a, float b )
{
	float const		feps = 0.0001f;
	
	return feps > fabsf( a - b );
}

BOOL compare_double( double a, double b )
{
	double const	deps = 0.0000001;
	
	return deps > fabs( a - b );
}*/