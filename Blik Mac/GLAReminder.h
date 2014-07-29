//
//  GLAReminderItem.h
//  Blik
//
//  Created by Patrick Smith on 9/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
@import EventKit;
#import "Mantle/Mantle.h"


@interface GLAReminder : MTLModel <MTLJSONSerializing>

- (instancetype)initWithTitle:(NSString *)title;
- (instancetype)initWithEventKitReminder:(EKReminder *)eventKitReminder;

@property(readonly, nonatomic) EKReminder/*?*/ *eventKitReminder;

@property(copy, nonatomic) NSString *title;

@property(nonatomic) BOOL highPriority;

//@property(copy, nonatomic) NSDateComponents *dueDateComponents;
//@property(nonatomic) NSUInteger priority; 1 (high) to low (9) - used to manually order in list

- (void)setCreatedEventKitReminder:(EKReminder *)eventKitReminder;
- (void)setFoundEventKitReminder:(EKReminder *)eventKitReminder;

@end


@interface GLAReminder (PasteboardSupport)

extern NSString *GLAReminderJSONPasteboardType;

- (NSPasteboardItem *)newPasteboardItem;
+ (void)writeReminders:(NSArray *)reminders toPasteboard:(NSPasteboard *)pboard;

+ (BOOL)canCopyRemindersFromPasteboard:(NSPasteboard *)pboard;
+ (NSArray *)copyRemindersFromPasteboard:(NSPasteboard *)pboard;

@end


@interface GLAReminder (GLADummyContent)

+ (instancetype)dummyReminderWithTitle:(NSString *)title;

@end


@protocol GLAReminderListEditing <NSObject>

- (void)addReminder:(GLAReminder *)reminder;
- (void)removeReminder:(GLAReminder *)reminder;

- (NSArray *)copyRemindersOrderedByPriority;

// This would be synchronous, so no:
//- (void)addReminderWithEventKitReminder:(EKReminder *)eventKitReminder;

// Just set the property directly, the order is worked out when the list is copied again.
//- (void)makeReminderHighPriority:(GLAReminder *)reminder;

@end