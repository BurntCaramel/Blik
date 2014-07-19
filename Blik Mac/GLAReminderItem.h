//
//  GLAReminderItem.h
//  Blik
//
//  Created by Patrick Smith on 9/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
@import EventKit;

@interface GLAReminderItem : NSObject

@property(nonatomic) EKReminder *reminder;

@property(copy, nonatomic) NSString *title;

//@property(copy, nonatomic) NSDateComponents *dueDateComponents;
//@property(nonatomic) NSUInteger priority; 1 (high) to low (9) - used to manually order in list

+ (instancetype)dummyReminderItemWithTitle:(NSString *)title;

@end
