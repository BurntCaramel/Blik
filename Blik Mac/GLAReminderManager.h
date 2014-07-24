//
//  GLAReminderManager.h
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
@import EventKit;
#import "GLAReminder.h"

extern NSString *GLAReminderDidSaveEventKitReminderNotification;
extern NSString *GLAReminderCouldNotSaveEventKitReminderNotification;


@interface GLAReminderManager : NSObject

+ (instancetype)sharedReminderManager;

@property (nonatomic) EKCalendar *calendarForNewReminders;
@property (nonatomic) NSArray *calendarsForFindingReminders;

- (void)createEventStore;

#pragma mark Requesting Access from the User

@property(readonly, nonatomic) EKAuthorizationStatus authorizationStatus;
@property(readonly, getter = isAuthorized, nonatomic) BOOL authorized;
- (void)requestAccessToReminders:(EKEventStoreRequestAccessCompletionHandler)completion;

#pragma mark Finding Reminders

- (void)fetchAllRemindersIfNeeded:(void(^)(NSArray *allReminders))allRemindersReceiver;
@property(nonatomic) NSArray *allReminders;
@property(nonatomic) NSDate *dateLastFetchedReminders;

- (void)findRemindersWithTitle:(NSString *)title reminderReceiver:(void(^)(NSArray *reminders, NSError *errorOrNil))reminderReceiver;

#pragma mark Saving Reminders

- (void)createAndSaveEventKitReminderForReminder:(GLAReminder *)reminder;

//- (BOOL)isTryingToSaveEventKitReminderForReminder:(GLAReminder *)reminder;
//- (NSDate *)latestAttemptedDateToSaveEventKitReminderForReminder:(GLAReminder *)reminder;

@end
