
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      cheat_types.h
// Created:   Thu Sep 11 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#ifndef _cheat_types_H
#define _cheat_types_H


enum tagTCtype
{
	TYPE_INTEGER, TYPE_STRING, TYPE_DECIMAL, TYPE_UNKNOWN
};
typedef int			TCtype;

enum tagTCsize
{
	SIZE_8_BIT, SIZE_16_BIT, SIZE_32_BIT, SIZE_64_BIT
};
typedef int			TCsize;

enum tagTCstatus
{
	STATUS_DISCONNECTED, STATUS_CONNECTED, STATUS_CHEATING, STATUS_SEARCHING, STATUS_CHANGING, STATUS_CHANGING_LATER, STATUS_CHANGING_CONTINUOUSLY, STATUS_UNDOING, STATUS_REDOING
};
typedef int			TCstatus;
// NOTE: STATUS_CHANGING_LATER should not be used, as this future is not implemented.


typedef long unsigned		TCaddress;
#define						TCAddressSize sizeof(TCaddress)


#endif

