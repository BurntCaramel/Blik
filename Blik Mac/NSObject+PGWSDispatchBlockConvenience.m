//
//  NSObject+PGWSDispatchBlockConvenience.m
//  Blik
//
//  Created by Patrick Smith on 13/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "NSObject+PGWSDispatchBlockConvenience.h"


@implementation NSObject (PGWSDispatchBlockConvenience)

- (void)pgws_useReceiverAsyncOnDispatchQueue:(dispatch_queue_t)dispatchQueue block:(void (^)(id receiver))block
{
	NSParameterAssert(dispatchQueue != nil);
	NSParameterAssert(block != nil);
	
	__weak id weakSelf = self;
	dispatch_async(dispatchQueue, ^{
		id strongSelf = weakSelf;
		if (!strongSelf) {
			return;
		}
		
		block(strongSelf);
	});
}

- (void)pgws_useReceiverSyncOnDispatchQueue:(dispatch_queue_t)dispatchQueue block:(void (^)(id receiver))block
{
	NSParameterAssert(dispatchQueue != nil);
	NSParameterAssert(block != nil);
	
	dispatch_sync(dispatchQueue, ^{
		block(self);
	});
}

- (id)pgws_useReceiverSyncOnDispatchQueue:(dispatch_queue_t)dispatchQueue returningResultFromBlock:(id (^)(id receiver))block
{
	NSParameterAssert(block != nil);
	
	__block id result = nil;
	
	dispatch_sync(dispatchQueue, ^{
		result = block(self);
	});
	
	return result;
}

- (BOOL)pgws_useReceiverSyncOnDispatchQueue:(dispatch_queue_t)dispatchQueue returningBoolResultFromBlock:(BOOL (^)(id receiver))block
{
	NSParameterAssert(block != nil);
	
	__block BOOL result = NO;
	
	dispatch_sync(dispatchQueue, ^{
		result = block(self);
	});
	
	return result;
}

@end
