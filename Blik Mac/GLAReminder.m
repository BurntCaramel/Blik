//
//  GLAReminderItem.m
//  Blik
//
//  Created by Patrick Smith on 9/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAReminder.h"


@interface GLAReminder ()

@property(readwrite, nonatomic) EKReminder *eventKitReminder;

@end

@implementation GLAReminder

- (void)pendingEventKitReminderWasCreated:(EKReminder *)eventKitReminder
{
	(self.eventKitReminder) = eventKitReminder;
}

@end


@implementation GLAReminder (GLADummyContent)

+ (instancetype)dummyReminderWithTitle:(NSString *)title
{
	GLAReminder *reminderItem = [self new];
	(reminderItem.title) = title;
	
	return reminderItem;
}

@end
