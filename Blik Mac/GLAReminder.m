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

- (void)setFoundEventKitReminder:(EKReminder *)eventKitReminder
{
	(self.eventKitReminder) = eventKitReminder;
}

#pragma mark Mantle specific properties

+ (NSValueTransformer *)highPriorityJSONTransformer
{
	return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
}

- (NSString *)calendarItemExternalIdentifier
{
	return (self.eventKitReminder.calendarItemExternalIdentifier);
}

- (NSString *)calendarTitle
{
	return (self.eventKitReminder.calendar.title);
}

@end


@implementation GLAReminder (PasteboardSupport)

NSString *GLAReminderJSONPasteboardType = @"com.burntcaramel.GLAReminder.JSONPasteboardType";

- (NSPasteboardItem *)newPasteboardItem
{
	NSDictionary *selfAsJSON = [MTLJSONAdapter JSONDictionaryFromModel:self];
	return [[NSPasteboardItem alloc] initWithPasteboardPropertyList:selfAsJSON ofType:GLAReminderJSONPasteboardType];
}

+ (void)writeReminders:(NSArray *)reminders toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:@[GLAReminderJSONPasteboardType] owner:nil];
	
	NSArray *draggedCollectionsJSON = [MTLJSONAdapter JSONArrayFromModels:reminders];
	[pboard setPropertyList:draggedCollectionsJSON forType:GLAReminderJSONPasteboardType];
}

+ (BOOL)canCopyRemindersFromPasteboard:(NSPasteboard *)pboard
{
	NSString *pboardType = [pboard availableTypeFromArray:@[GLAReminderJSONPasteboardType]];
	if (!pboardType) {
		return NO;
	}
	
	return YES;
}

+ (NSArray *)copyRemindersFromPasteboard:(NSPasteboard *)pboard
{
	NSString *pboardType = [pboard availableTypeFromArray:@[GLAReminderJSONPasteboardType]];
	if (!pboardType) {
		return nil;
	}
	
	id possibleRemindersJSON = [pboard propertyListForType:GLAReminderJSONPasteboardType];
	if (![possibleRemindersJSON isKindOfClass:[NSArray class]]) {
		return nil;
	}
	
	NSArray *remindersJSON = possibleRemindersJSON;
	NSError *error = nil;
	NSArray *reminders = [MTLJSONAdapter modelsOfClass:[self class] fromJSONArray:remindersJSON error:&error];
	
	return reminders;
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
