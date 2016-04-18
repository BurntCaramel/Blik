//
//  PGWSCFNotificationObserver.h
//  Blik
//
//  Created by Patrick Smith on 26/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

@import Foundation;


typedef void (^ PGWS_CFNotificationCallback)(CFNotificationCenterRef center, CFStringRef name, const void *object, CFDictionaryRef userInfo);


@interface PGWSCFNotificationObserver: NSObject

- (instancetype)initWithCenter:(CFNotificationCenterRef)center block:(PGWS_CFNotificationCallback)block name:(CFStringRef)name object:(const void *)object suspensionBehavior:(CFNotificationSuspensionBehavior)suspensionBehavior NS_DESIGNATED_INITIALIZER;

- (instancetype)init __unavailable;

@end
