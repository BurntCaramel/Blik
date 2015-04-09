//
//  NSMenu+GLAMenuItemConvenience.m
//  Blik
//
//  Created by Patrick Smith on 9/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "NSMenu+GLAMenuItemConvenience.h"


@implementation NSMenu (GLAMenuItemConvenience)

- (void)gla_addDescriptiveMenuItemWithTitle:(NSString *)title
{
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
	(item.enabled) = NO;
	[self addItem:item];
}

@end
