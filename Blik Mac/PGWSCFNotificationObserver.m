//
//  PGWSCFNotificationObserver.m
//  Blik
//
//  Created by Patrick Smith on 26/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

#import "PGWSCFNotificationObserver.h"


typedef void (^ PGWS_CFNotificationRemoveCallback)(const void *observer);

@interface PGWSCFNotificationObserver ()

@property(nonatomic, copy) PGWS_CFNotificationCallback block;
@property(nonatomic, copy) PGWS_CFNotificationRemoveCallback remover;

@end

@implementation PGWSCFNotificationObserver

- (instancetype)initWithCenter:(CFNotificationCenterRef)center block:(PGWS_CFNotificationCallback)block name:(CFStringRef)name object:(const void *)object suspensionBehavior:(CFNotificationSuspensionBehavior)suspensionBehavior
{
	self = [super init];
	if (self) {
		(self.block) = block;
		(self.remover) = ^(const void *observer) {
			CFNotificationCenterRemoveObserver(center, observer, name, object);
		};
		
		CFNotificationCenterAddObserver(center, (__bridge const void *)self, &PGWS_CFNotificationCenter_receiveNotification, name, object, suspensionBehavior);
	}
	return self;
}

- (void)dealloc
{
	(self.remover)((__bridge const void *)self);
}

void PGWS_CFNotificationCenter_receiveNotification(CFNotificationCenterRef center, void *observerUntyped, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	PGWSCFNotificationObserver *observer = (__bridge PGWSCFNotificationObserver *)observerUntyped;
	PGWS_CFNotificationCallback block = (observer.block);
	
	block(center, name, object, userInfo);
}

@end
