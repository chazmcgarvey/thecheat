
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      AppController.m
// Created:   Wed Aug 13 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "AppController.h"

#include <mach/vm_map.h>
#include <mach/mach_traps.h>


// defines
#define PID_SELECTED	[[[processList objectAtIndex:[processPopup indexOfSelectedItem]] objectForKey:@"NSApplicationProcessIdentifier"] intValue]
#define TYPE_SELECTED	[typePopup indexOfSelectedItem]
#define SIZE_SELECTED	[sizePopup indexOfSelectedItem]


@implementation AppController

- (id)init
{
	if ( self = [super init] )
	{
		
	}

	return self;
}

- (void)awakeFromNib
{
	NSNotificationCenter	*nc = [[NSWorkspace sharedWorkspace] notificationCenter];

	[self rebuildProcessList];
	[self updateProcessPopup];
	[self updateTypePopup];
	[self updateSizePopup];
	[self updateChangeButton];
	[self updateStatusText];

	[nc addObserver:self selector:@selector(processListChanged:) name:@"NSWorkspaceDidLaunchApplicationNotification" object:nil];
	[nc addObserver:self selector:@selector(processListChanged:) name:@"NSWorkspaceDidTerminateApplicationNotification" object:nil];
	
	[self reset];
}


- (void)reset
{
	if ( cheating )
	{
		cheating = NO;

		[addressList release], addressList = nil;

		// update the interface
		[typePopup setEnabled:YES];
		[sizePopup setEnabled:YES];
		[searchTextField setStringValue:@""];
		[changeTextField setStringValue:@""];
		[addressTable reloadData];
	}
}


- (void)firstSearch:(id)nothing
{
	NSAutoreleasePool			*pool = [[NSAutoreleasePool alloc] init];
	
	pid_t						pid = (pid_t)PID_SELECTED;
	vm_map_t					task;

	kern_return_t				result;

	vm_address_t				address = 0x0;
	vm_size_t					size = 0;
	vm_region_basic_info_data_t	info;
	mach_msg_type_number_t		infoCnt = 8;
	mach_port_t					object_name = 0;

	char unsigned				*data;
	vm_size_t					dataCnt;

	char unsigned				*string8bit = (char unsigned *)[[searchTextField stringValue] lossyCString];
	long unsigned				stringSize = strlen( string8bit );
	char						integer8bit = (char)[searchTextField intValue];
	short						integer16bit = (short)[searchTextField intValue];
	long						integer32bit = (long)[searchTextField intValue];
	long long					integer64bit = (long long)[searchTextField intValue];
	float						float32bit = (float)[searchTextField floatValue];
	double						float64bit = (double)[searchTextField doubleValue];

	BOOL						done = NO;

	if ( (result = task_for_pid( current_task(), pid, &task)) != KERN_SUCCESS )
	{
		NSLog( @"task_for_pid returned error: %i", result );
		return;
	}

	addressList = [[NSMutableArray alloc] init];

	while ( !done )
	{
		if ( (result = vm_region( task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)(&info), &infoCnt, &object_name )) != KERN_SUCCESS )
		{
			if ( result != KERN_INVALID_ADDRESS )
			{
				NSLog( @"vm_region returned error: %i", result );
			}

			done = YES;
		}

		//NSLog( @"address: %X, size: %i", address, size );

		if ( (info.protection & VM_PROT_READ) && ((info.protection & VM_PROT_WRITE) >> 1) )
		{
			data = (char unsigned *)malloc( size );
			dataCnt = size;

			if ( (result = vm_read_overwrite( task, address, size, (vm_address_t)data, &dataCnt )) != KERN_SUCCESS && result != KERN_PROTECTION_FAILURE )
			{
				NSLog( @"vm_read_overwrite returned error: %i", result );
				free( data );
				done = YES;
			}

			if ( result == KERN_SUCCESS )
			{
				long unsigned	i, max = (long unsigned)dataCnt;

				//NSLog( @"data: %X, size: %i", (vm_address_t)data, dataCnt );

				switch ( TYPE_SELECTED )
				{
					case TYPE_STRING:
						switch ( SIZE_SELECTED )
						{
							case SIZE_8_BIT:
							{
								long unsigned	maxString = max - stringSize;

								for ( i = 0; i < maxString; i += sizeof(char unsigned) )
								{
									if ( strncmp( string8bit, data+i, stringSize ) == 0 )
									{
										[addressList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
							}
								break;
						}
						break;

					case TYPE_INTEGER:
						switch ( SIZE_SELECTED )
						{
							case SIZE_8_BIT:
							{
								for ( i = 0; i < max; i += sizeof(char) )
								{
									if ( integer8bit == *((char *)(data+i)) )
									{
										[addressList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
							}
								break;

							case SIZE_16_BIT:
							{
								for ( i = 0; i < max; i += sizeof(short) )
								{
									if ( integer16bit == *((short *)(data+i)) )
									{
										[addressList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
							}
								break;

							case SIZE_32_BIT:
							{
								for ( i = 0; i < max; i += sizeof(long) )
								{
									if ( integer32bit == *((long *)(data+i)) )
									{
										[addressList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
							}
								break;

							case SIZE_64_BIT:
							{
								for ( i = 0; i < max; i += sizeof(long long) )
								{
									if ( integer64bit == *((long long *)(data+i)) )
									{
										[addressList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
							}
								break;
						}
						break;

					case TYPE_FLOAT:
						switch ( SIZE_SELECTED+2 )
						{
							case SIZE_32_BIT:
							{
								for ( i = 0; i < max; i += sizeof(float) )
								{
									if ( float32bit == *((float *)(data+i)) )
									{
										[addressList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
							}
								break;

							case SIZE_64_BIT:
							{
								for ( i = 0; i < max; i += sizeof(double) )
								{
									if ( float64bit == *((double *)(data+i)) )
									{
										[addressList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
							}
								break;
						}
						break;
				}
			}

			free( data );
		}

		address += size;
	}

	searching = NO;

	// update the interface
	[statusBar stopAnimation:self];
	[self updateProcessPopup];
	[self updateSearchButton];
	[self updateTypePopup];
	[self updateSizePopup];
	[self updateChangeButton];
	[self updateStatusText];
	[addressTable reloadData];

	[pool release];
}

- (void)search:(id)nothing
{
	NSAutoreleasePool			*pool = [[NSAutoreleasePool alloc] init];
	
	pid_t						pid = (pid_t)PID_SELECTED;
	vm_map_t					task;

	kern_return_t				result;

	vm_address_t				address = 0x0;
	vm_size_t					size = 0;
	vm_region_basic_info_data_t	info;
	mach_msg_type_number_t		infoCnt = 8;
	mach_port_t					object_name = 0;

	char unsigned				*data;
	vm_size_t					dataCnt;

	char unsigned				*string8bit = (char unsigned *)[[searchTextField stringValue] lossyCString];
	long unsigned				stringSize = strlen( string8bit );
	char						integer8bit = (char)[searchTextField intValue];
	short						integer16bit = (short)[searchTextField intValue];
	long						integer32bit = (long)[searchTextField intValue];
	long long					integer64bit = (long long)[searchTextField intValue];
	float						float32bit = (float)[searchTextField floatValue];
	double						float64bit = (double)[searchTextField doubleValue];

	long unsigned				j, max = [addressList count];

	NSMutableArray				*newList = [[NSMutableArray alloc] init];

	if ( (result = task_for_pid( current_task(), pid, &task)) != KERN_SUCCESS )
	{
		NSLog( @"task_for_pid returned error: %i", result );
		return;
	}

	for ( j = 0; j < max; j++ )
	{
		long unsigned		item = [[addressList objectAtIndex:j] unsignedLongValue];

		address = (vm_address_t)item;

		if ( (result = vm_region( task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)(&info), &infoCnt, &object_name )) != KERN_SUCCESS )
		{
			if ( result != KERN_INVALID_ADDRESS )
			{
				NSLog( @"vm_region returned error: %i", result );
			}

			break;
		}

		//NSLog( @"address: %X, size: %i", address, size );

		if ( (info.protection & VM_PROT_READ) && ((info.protection & VM_PROT_WRITE) >> 1) )
		{
			data = (char unsigned *)malloc( size );
			dataCnt = size;

			if ( (result = vm_read_overwrite( task, address, size, (vm_address_t)data, &dataCnt )) != KERN_SUCCESS && result != KERN_PROTECTION_FAILURE )
			{
				NSLog( @"vm_read_overwrite returned error: %i", result );
				free( data );
				break;
			}

			if ( result == KERN_SUCCESS )
			{
				long unsigned	i = item - (long unsigned)address;

				if ( i < (long unsigned)dataCnt )
				{
					//NSLog( @"data: %X, size: %i", (vm_address_t)data, dataCnt );

					switch ( TYPE_SELECTED )
					{
						case TYPE_STRING:
							switch ( SIZE_SELECTED )
							{
								case SIZE_8_BIT:
								{
									if ( strncmp( string8bit, data+i, stringSize ) == 0 )
									{
										[newList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
									break;
							}
							break;

						case TYPE_INTEGER:
							switch ( SIZE_SELECTED )
							{
								case SIZE_8_BIT:
								{
									if ( integer8bit == *((char *)(data+i)) )
									{
										[newList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
									break;

								case SIZE_16_BIT:
								{
									if ( integer16bit == *((short *)(data+i)) )
									{
										[newList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
									break;

								case SIZE_32_BIT:
								{
									if ( integer32bit == *((long *)(data+i)) )
									{
										[newList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
									break;

								case SIZE_64_BIT:
								{
									if ( integer64bit == *((long long *)(data+i)) )
									{
										[newList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
									break;
							}
							break;

						case TYPE_FLOAT:
							switch ( SIZE_SELECTED+2 )
							{
								case SIZE_32_BIT:
								{
									if ( float32bit == *((float *)(data+i)) )
									{
										[newList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
									break;

								case SIZE_64_BIT:
								{
									if ( float64bit == *((double *)(data+i)) )
									{
										[newList addObject:[NSNumber numberWithUnsignedLong:(long unsigned)address + i]];
									}
								}
									break;
							}
							break;
					}
				}
			}

			free( data );
		}
	}

	[addressList release];
	addressList = newList;

	searching = NO;

	// update the interface
	[statusBar stopAnimation:self];
	[self updateProcessPopup];
	[self updateSearchButton];
	[self updateTypePopup];
	[self updateSizePopup];
	[self updateChangeButton];
	[self updateStatusText];
	[addressTable reloadData];

	[pool release];
}


- (void)change
{
	pid_t						pid = (pid_t)PID_SELECTED;
	vm_map_t					task;

	kern_return_t				result;

	char unsigned				*string8bit = (char unsigned *)[[changeTextField stringValue] lossyCString];
	long unsigned				stringSize = strlen( string8bit );
	char						integer8bit = (char)[changeTextField intValue];
	short						integer16bit = (short)[changeTextField intValue];
	long						integer32bit = (long)[changeTextField intValue];
	long long					integer64bit = (long long)[changeTextField intValue];
	float						float32bit = (float)[changeTextField floatValue];
	double						float64bit = (double)[changeTextField doubleValue];

	NSEnumerator				*enumerator = [addressTable selectedRowEnumerator];
	NSNumber					*row;

	if ( (result = task_for_pid( current_task(), pid, &task)) != KERN_SUCCESS )
	{
		NSLog( @"task_for_pid returned error: %i", result );
		return;
	}

	while ( row = [enumerator nextObject] )
	{
		long unsigned		item = [[addressList objectAtIndex:[row intValue]] unsignedLongValue];

		//NSLog( @"address: %X", item );

		switch ( TYPE_SELECTED )
		{
			case TYPE_STRING:
				switch ( SIZE_SELECTED )
				{
					case SIZE_8_BIT:
					{
						result = vm_write( task, (vm_address_t)item, (vm_offset_t)string8bit, (mach_msg_type_number_t)stringSize );
					}
						break;
				}
				break;

			case TYPE_INTEGER:
				switch ( SIZE_SELECTED )
				{
					case SIZE_8_BIT:
					{
						result = vm_write( task, (vm_address_t)item, (vm_offset_t)(&integer8bit), sizeof(char) );
					}
						break;

					case SIZE_16_BIT:
					{
						result = vm_write( task, (vm_address_t)item, (vm_offset_t)(&integer16bit), sizeof(short) );
					}
						break;

					case SIZE_32_BIT:
					{
						result = vm_write( task, (vm_address_t)item, (vm_offset_t)(&integer32bit), sizeof(long) );
					}
						break;

					case SIZE_64_BIT:
					{
						result = vm_write( task, (vm_address_t)item, (vm_offset_t)(&integer64bit), sizeof(long long) );
					}
						break;
				}
				break;

			case TYPE_FLOAT:
				switch ( SIZE_SELECTED+2 )
				{
					case SIZE_32_BIT:
					{
						result = vm_write( task, (vm_address_t)item, (vm_offset_t)(&float32bit), sizeof(float) );
					}
						break;

					case SIZE_64_BIT:
					{
						result = vm_write( task, (vm_address_t)item, (vm_offset_t)(&float64bit), sizeof(double) );
					}
						break;
				}
				break;
		}
	}
}


- (void)updateProcessPopup
{
	if ( searching )
	{
		[processPopup setEnabled:NO];
	}
	else
	{
		[processPopup setEnabled:YES];
	}
}

- (void)updateTypePopup
{
	if ( cheating || searching )
	{
		[typePopup setEnabled:NO];
	}
	else
	{
		int			selected = [typePopup indexOfSelectedItem];
		
		[typePopup setEnabled:YES];
		
		[typePopup removeAllItems];

		[typePopup addItemWithTitle:@"String"];
		[typePopup addItemWithTitle:@"Integer"];
		[typePopup addItemWithTitle:@"Float"];

		[typePopup selectItemAtIndex:selected];
	}
}

- (void)updateSizePopup
{
	if ( cheating || searching )
	{
		[sizePopup setEnabled:NO];
	}
	else
	{
		[sizePopup setEnabled:YES];
		
		[sizePopup removeAllItems];

		switch ( TYPE_SELECTED )
		{
			case TYPE_STRING:
				[sizePopup addItemWithTitle:@"  8-bit"];
				break;

			case TYPE_INTEGER:
				[sizePopup addItemWithTitle:@"  8-bit"];
				[sizePopup addItemWithTitle:@"16-bit"];
				[sizePopup addItemWithTitle:@"32-bit"];
				[sizePopup addItemWithTitle:@"64-bit"];
				break;

			case TYPE_FLOAT:
				[sizePopup addItemWithTitle:@"32-bit"];
				[sizePopup addItemWithTitle:@"64-bit"];
				break;
		}
	}
}

- (void)updateSearchButton
{
	if ( searching )
	{
		[searchTextField setEnabled:NO];
		[searchButton setEnabled:NO];
	}
	else
	{
		[searchTextField setEnabled:YES];
		[searchButton setEnabled:YES];
	}
}

- (void)updateChangeButton
{
	if ( [addressTable selectedRow] == -1 || searching )
	{
		[changeTextField setEnabled:NO];
		[changeButton setEnabled:NO];
	}
	else
	{
		[changeTextField setEnabled:YES];
		[changeButton setEnabled:YES];
	}
}

- (void)updateStatusText
{
	if ( searching )
	{
		[statusText setStringValue:@"Searching..."];
	}
	else if ( !cheating )
	{
		[statusText setStringValue:[NSString stringWithFormat:@"PID: %i", PID_SELECTED]];
	}
	else // cheating
	{
		[statusText setStringValue:[NSString stringWithFormat:@"Found: %i", [addressList count]]];
	}

	[statusText display];
}


- (void)processListChanged:(NSNotification *)note
{
	if ( cheating && [[note name] isEqualToString:@"NSWorkspaceDidTerminateApplicationNotification"] )
	{
		int			pid = PID_SELECTED;
		int			other = [[[note userInfo] objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		
		// check to make sure the program we were cheating wasn't the one that quit
		if ( pid == other )
		{
			// it was, so let's take care of it
			NSBeginAlertSheet( @"", @"OK", nil, nil, window, nil, nil, nil, 0, @"The application that was being cheated has quit." );
			
			[self reset];
		}
	}

	[self rebuildProcessList];
	[self updateProcessPopup];
	[self updateStatusText];
}


- (void)rebuildProcessList
{
	NSString		*selected = [[processPopup titleOfSelectedItem] retain];
	int				i, max;

	[processList release];
	processList = [[[NSWorkspace sharedWorkspace] launchedApplications] retain];

	max = [processList count];

	[processPopup setImagePosition:NSImageOverlaps];

	[processPopup removeAllItems];

	for ( i = 0; i < max; i++ )
	{
		NSString	*name = [[processList objectAtIndex:i] objectForKey:@"NSApplicationName"];
		NSString	*path = [[processList objectAtIndex:i] objectForKey:@"NSApplicationPath"];

		NSImage		*image = [[NSWorkspace sharedWorkspace] iconForFile:path];

		[processPopup addItemWithTitle:name];

		[image setScalesWhenResized:YES];
		[image setSize:NSMakeSize( 16.0, 16.0 )];

		[[processPopup itemAtIndex:i] setImage:image];

		if ( [selected isEqualToString:[processPopup itemTitleAtIndex:i]] )
		{
			[processPopup selectItemAtIndex:i];
		}
	}

	[selected release];
}


- (void)dealloc
{
	[self reset];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	[processList release];
	
	[super dealloc];
}


- (IBAction)processPopup:(id)sender
{
	[self reset];

	[self updateStatusText];
}

- (IBAction)typePopup:(id)sender
{
	[self updateSizePopup];
}

- (IBAction)searchButton:(id)sender
{
	if ( [[searchTextField stringValue] isEqualToString:@""] )
	{
		NSBeep();
		return;
	}

	searching = YES;

	// update the interface
	[statusBar startAnimation:self];
	[self updateProcessPopup];
	[self updateSearchButton];
	[self updateTypePopup];
	[self updateSizePopup];
	[self updateChangeButton];
	[self updateStatusText];

	if ( !cheating )
	{
		cheating = YES;

		[NSThread detachNewThreadSelector:@selector(firstSearch:) toTarget:self withObject:nil];
	}
	else
	{
		[NSThread detachNewThreadSelector:@selector(search:) toTarget:self withObject:nil];
	}
/*
	{
		pid_t			pid = (pid_t)PID_SELECTED;
		vm_map_t		task;

		kern_return_t	result;
		//int				waitStatus;

		addressList = [[NSMutableArray alloc] init];

		result = task_for_pid( current_task(), pid, &task );

		if ( result == KERN_SUCCESS )
			NSLog( @"KERN_SUCCESS" );
		else if ( result == KERN_INVALID_ADDRESS )
			NSLog( @"KERN_INVALID_ADDRESS" );
		else if ( result == KERN_INVALID_ARGUMENT )
			NSLog( @"KERN_INVALID_ARGUMENT" );
		else if ( result == KERN_PROTECTION_FAILURE )
			NSLog( @"KERN_PROTECTION_FAILURE" );
		else if ( result == KERN_NO_SPACE )
			NSLog( @"KERN_NO_SPACE" );

		if ( ptrace( PT_ATTACH, pid, 0, 0 ) != -1 )
		{
			if ( waitpid( pid, &waitStatus, WUNTRACED ) == pid )
			{
				if ( WIFSTOPPED(waitStatus) )
				{
					NSLog( @"process stopped" );
				}
				else
				{
					NSLog( @"process didn't stop" );
				}

				{
					vm_address_t				address = 0x1b000;
					vm_size_t					size = 0;
					vm_region_basic_info_data_t	info;
					mach_msg_type_number_t		infoCnt = 8;
					mach_port_t					object_name = 0;

					BOOL						canRead, canWrite, canExecute;

					char unsigned				*data;
					vm_size_t					dataCnt;

					NSLog( @"pid: %i, task: %i", pid, task );
					
					result = vm_region( task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)(&info), &infoCnt, &object_name );

					NSLog( @"info count: %i", (int)infoCnt );

					if ( result == KERN_SUCCESS )
						NSLog( @"KERN_SUCCESS" );
					else if ( result == KERN_INVALID_ADDRESS )
						NSLog( @"KERN_INVALID_ADDRESS" );
					else if ( result == KERN_INVALID_ARGUMENT )
						NSLog( @"KERN_INVALID_ARGUMENT" );
					else if ( result == KERN_PROTECTION_FAILURE )
						NSLog( @"KERN_PROTECTION_FAILURE" );
					else if ( result == KERN_NO_SPACE )
						NSLog( @"KERN_NO_SPACE" );

					NSLog( @"address: %X, size: %i", address, size );

					canRead = info.protection & VM_PROT_READ;
					canWrite = (info.protection & VM_PROT_WRITE) >> 1;
					canExecute = (info.protection & VM_PROT_EXECUTE) >> 2;

					if ( canRead )
						NSLog( @"can read" );
					if ( canWrite )
						NSLog( @"can write" );
					if ( canExecute )
						NSLog( @"can execute" );

					data = (char unsigned *)malloc( size );
					dataCnt = size;

					result = vm_read_overwrite( task, address, size, (vm_address_t)data, &dataCnt );

					if ( result == KERN_SUCCESS )
						NSLog( @"KERN_SUCCESS" );
					else if ( result == KERN_INVALID_ADDRESS )
						NSLog( @"KERN_INVALID_ADDRESS" );
					else if ( result == KERN_INVALID_ARGUMENT )
						NSLog( @"KERN_INVALID_ARGUMENT" );
					else if ( result == KERN_PROTECTION_FAILURE )
						NSLog( @"KERN_PROTECTION_FAILURE" );
					else if ( result == KERN_NO_SPACE )
						NSLog( @"KERN_NO_SPACE" );

					NSLog( @"data: %X, size: %i", (vm_address_t)data, dataCnt );

					free( data );
				}
			}
			else
			{
				NSLog( @"waitpid() failed" );
			}

			ptrace( PT_DETACH, pid, 0, 0 );
		}
		else
		{
			NSLog( @"ptrace() failed" );
		}
	}*/
}

- (IBAction)changeButton:(id)sender
{
	[self change];
}


- (int)numberOfRowsInTableView:(NSTableView *)table
{
	if ( cheating && !searching )
		return [addressList count];

	return 0;
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	return [NSString stringWithFormat:@"%X", [[addressList objectAtIndex:row] unsignedLongValue]];
}

- (void)tableView:(NSTableView *) setObjectValue:(id)object forTableColumn:(NSTableColumn *)column row:(int)row
{
	return;
}

- (void)tableViewSelectionDidChange:(NSNotification *)note
{
	[self updateChangeButton];
}


@end