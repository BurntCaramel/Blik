//
//  GLAProjectItem.m
//  Blik
//
//  Created by Patrick Smith on 18/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProjectItem.h"

@implementation GLAProjectItem

+ (instancetype)dummyItemWithTitle:(NSString *)title colorIdentifier:(GLAProjectItemColor)colorIdentifier
{
	GLAProjectItem *item = [self new];
	(item.title) = title;
	(item.colorIdentifier) = colorIdentifier;
	
	return item;
}

@end
