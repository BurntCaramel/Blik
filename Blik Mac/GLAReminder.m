//
//  GLAReminderItem.m
//  Blik
//
//  Created by Patrick Smith on 9/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAReminder.h"


@interface GLAReminder ()

@property(readwrite, nonatomic) EKReminder/*?*/ *eventKitReminder;

// Used by Mantle
@property(nonatomic, readonly) NSString *calendarItemExternalIdentifier;
@property(nonatomic, readonly) NSString *calendarTitle;

@end

@implementation GLAReminder

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
	return
	@{
	  @"title": @"title",
	  @"highPriority": @"highPriority",
	  @"calendarItemExternalIdentifier": @"calendarItemExternalIdentifier",
	  @"calendarTitle": @"calendarTitle"
	  };
}

- (instancetype)initWithTitle:(NSString *)title
{
	self = [super init];
	if (self) {
		(self.title) = title;
	}
	return self;
}

- (instancetype)initWithEventKitReminder:(EKReminder *)eventKitReminder
{
	self = [self initWithTitle:(eventKitReminder.title)];
	if (self) {
		(self.eventKitReminder) = eventKitReminder;
	}
	return self;
}

- (void)setCreatedEventKitReminder:(EKReminder *)eventKitReminder
{
	(self.eventKitReminder) = eventKitReminder;
}

#pragma mark Mantle specific properties

- (NSString *)calendarItemExternalIdentifier
{
	return (self.eventKitReminder.calendarItemExternalIdentifier);
}

- (NSString *)calendarTitle
{
	return (self.eventKitReminder.calendar.title);
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
