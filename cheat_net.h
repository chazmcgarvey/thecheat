
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      cheat_net.h
// Created:   Mon Sep 08 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#ifndef _cheat_net_H
#define _cheat_net_H

#import <Chaz/Chaz.h>

#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>


// macros

#define COPY_TO_BUFFER( to, from, size )	memcpy( to, from, size ), (char *)to += size;
#define COPY_FROM_BUFFER( to, from, size )	memcpy( to, from, size ), (char *)from += size;


struct tagPacketHeader
{
	u_int32_t		checksum;
	u_int32_t		function;
	u_int32_t		size;
};

typedef struct tagPacketHeader PacketHeader;


u_int32_t RandomChecksum();
char VerifyChecksum( u_int32_t checksum );
int CountBits( u_int8_t byte );

int SendBuffer( int socket, char const *buffer, int *length );
int ReadBuffer( int socket, char *buffer, int length );


#endif

