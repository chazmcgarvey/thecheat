
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.dogcows.com/chaz/wiki/TheCheat
 *
 * Copyright (c) 2003-2010, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */

#import <Cocoa/Cocoa.h>


@interface NSMenu ( MenuExtras )

- (void)removeItemWithTitle:(NSString *)title;
- (void)removeAllItemsWithTitle:(NSString *)title;
- (void)removeItemWithTag:(int)tag;
- (void)removeItemWithRepresentedObject:(id)object;

- (void)removeAllItems;

- (void)enableAllItems;
- (void)disableAllItems;

@end
