//
//  GLAReminderManager.h
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
@import EventKit;
#import "GLAReminder.h"


@interface GLAReminderManager : NSObject

+ (instancetype)sharedReminderManager; // Work on the main queue

@property (nonatomic) EKCalendar *calendarForNewReminders;
@property (nonatomic) NSArray *calendarsForFindingReminders;

#pragma mark Getting set up early

- (void)createEventStoreIfNeeded;

#pragma mark Requesting Access from the User

@property(readonly, nonatomic) EKAuthorizationStatus authorizationStatus;
@property(readonly, getter = isAuthorized, nonatomic) BOOL authorized;
- (void)requestAccessToReminders:(EKEventStoreRequestAccessCompletionHandler)completion;

#pragma mark All Reminders

- (void)useAllReminders:(void(^)(NSArray *allReminders))allRemindersReceiver;

@property(nonatomic) NSDate *dateLastFetchedReminders;
- (void)invalidateAllReminders;

#pragma mark Finding Reminders

- (void)findRemindersWithTitle:(NSString *)title reminderReceiver:(void(^)(NSArray *reminders))reminderReceiver;

#pragma mark Reminder Lists/Calendars

- (void)useCurrentAllReminderCalendars:(void(^)(NSArray *allReminderCalendars))allReminderCalendarsReceiver;

#pragma mark Saving Reminders

// Posts a GLAReminderDidSaveEventKitReminderNotification or GLAReminderCouldNotSaveEventKitReminderNotification depending if it was successful or not.
- (void)createAndSaveEventKitReminderForReminder:(GLAReminder *)reminder;

//- (BOOL)isCurrentlyTryingToSaveEventKitReminderForReminder:(GLAReminder *)reminder;
//- (NSDate *)latestAttemptedDateToSaveEventKitReminderForReminder:(GLAReminder *)reminder;

@end

extern NSString *GLAReminderDidSaveEventKitReminderNotification;
extern NSString *GLAReminderCouldNotSaveEventKitReminderNotification;
