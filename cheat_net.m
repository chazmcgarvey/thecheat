
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      cheat_net.m
// Created:   Mon Sep 08 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#include "cheat_net.h"


u_int32_t RandomChecksum()
{
	u_int8_t		byte1, byte2, byte3, byte4;
	char			*ptr;
	
	u_int32_t		checksum;
	long			randomValue = random();

	byte1 = randomValue & 0xFF;
	byte2 = (randomValue >> 8) & 0xFF;
	byte3 = (randomValue >> 16) & 0xFF;
	byte4 = CountBits( byte1 ) + CountBits( byte2 ) + CountBits( byte3 );
	
	ptr = (char *)(&checksum);

	COPY_TO_BUFFER( ptr, &byte1, sizeof(byte1) );
	COPY_TO_BUFFER( ptr, &byte2, sizeof(byte2) );
	COPY_TO_BUFFER( ptr, &byte3, sizeof(byte3) );
	COPY_TO_BUFFER( ptr, &byte4, sizeof(byte4) );

	return checksum;
}

char VerifyChecksum( u_int32_t checksum )
{
	u_int8_t		byte1, byte2, byte3, byte4;
	char			*ptr = (char *)(&checksum);

	COPY_FROM_BUFFER( &byte1, ptr, sizeof(byte1) );
	COPY_FROM_BUFFER( &byte2, ptr, sizeof(byte2) );
	COPY_FROM_BUFFER( &byte3, ptr, sizeof(byte3) );
	COPY_FROM_BUFFER( &byte4, ptr, sizeof(byte4) );

	if ( (CountBits( byte1 ) + CountBits( byte2 ) + CountBits( byte3 )) == byte4 )
	{
		return 1;
	}

	CMLog( @"checksum failed" );

	return 0;
}

int CountBits( u_int8_t byte )
{
	int				count = 0;
	int				i;

	for ( i = 0; i < 8; i++ )
	{
		count += byte & 1;

		byte >>= 1;
	}

	return count;
}


int SendBuffer( int sockfd, char const *buffer, int *length )
{
	int				bytesSent = 0;
	int				bytesLeft = *length;
	int				n = 0;

	while( bytesSent < *length )
	{
		if ( (n = send( sockfd, buffer+bytesSent, bytesLeft, 0 )) == -1 )
		{
			break;
		}

		bytesSent += n;
		bytesLeft -= n;
	}

	*length = bytesSent;

	return (n == -1)? -1:0;
}

int ReadBuffer( int sockfd, char *buffer, int length )
{
	int				bytesRead = 0;
	int				bytesLeft = length;
	int				n;

	while( bytesRead < length )
	{
		if ( (n = recv( sockfd, buffer+bytesRead, bytesLeft, 0 )) == -1 || n == 0 )
		{
			return (bytesRead > 0)? bytesRead:n;
		}

		bytesRead += n;
		bytesLeft -= n;
	}

	return bytesRead;
}