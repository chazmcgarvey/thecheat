
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      MenuExtras.h
// Created:   Wed Sep 17 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import <Cocoa/Cocoa.h>


@interface NSMenu (MenuExtras)

- (void)removeItemWithTitle:(NSString *)title;
- (void)removeAllItemsWithTitle:(NSString *)title;
- (void)removeItemWithTag:(int)tag;

- (void)removeAllItems;

- (void)enableAllItems;
- (void)disableAllItems;

@end