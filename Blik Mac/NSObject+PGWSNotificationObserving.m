//
//  NSObject+PGWSNotificationObserving.m
//  Blik
//
//  Created by Patrick Smith on 9/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "NSObject+PGWSNotificationObserving.h"


@implementation NSObject (PGWSNotificationObserving)

#pragma mark Notifying

- (void)pgws_postNotificationName:(NSString *)notificationName
{
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

- (void)pgws_postNotificationName:(NSString *)notificationName userInfo:(NSDictionary *)userInfo
{
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];
}

@end
