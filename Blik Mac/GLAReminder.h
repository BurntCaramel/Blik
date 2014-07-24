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


@interface GLAReminder : MTLModel

@property(readonly, nonatomic) EKReminder *eventKitReminder;

@property(copy, nonatomic) NSString *title;

// Used by Mantle
@property(nonatomic, readonly) NSString *calendarItemExternalIdentifier;

//@property(copy, nonatomic) NSDateComponents *dueDateComponents;
//@property(nonatomic) NSUInteger priority; 1 (high) to low (9) - used to manually order in list

- (void)pendingEventKitReminderWasCreated:(EKReminder *)eventKitReminder;

@end


@interface GLAReminder (GLADummyContent)

+ (instancetype)dummyReminderWithTitle:(NSString *)title;

@end


@protocol GLAReminderListEditing <NSObject>

- (void)addEventKitReminder:(EKReminder *)eventKitReminder;
- (void)removeEventKitReminder:(EKReminder *)eventKitReminder;

@end