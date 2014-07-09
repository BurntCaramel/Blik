//
//  GLAReminderItem.h
//  Glance Prototype A
//
//  Created by Patrick Smith on 9/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
@import EventKit;

@interface GLAReminderItem : NSObject

@property(nonatomic) EKReminder *reminder;

@property(copy, nonatomic) NSString *title;

+ (instancetype)dummyReminderItemWithTitle:(NSString *)title;

@end
