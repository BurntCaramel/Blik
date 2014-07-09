//
//  GLAReminderItem.m
//  Glance Prototype A
//
//  Created by Patrick Smith on 9/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAReminderItem.h"

@implementation GLAReminderItem

+ (instancetype)dummyReminderItemWithTitle:(NSString *)title
{
	GLAReminderItem *reminderItem = [self new];
	(reminderItem.title) = title;
	return reminderItem;
}

@end
