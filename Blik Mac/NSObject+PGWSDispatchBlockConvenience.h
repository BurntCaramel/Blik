//
//  NSObject+PGWSDispatchBlockConvenience.h
//  Blik
//
//  Created by Patrick Smith on 13/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;


@interface NSObject (PGWSDispatchBlockConvenience)

- (void)pgws_useReceiverAsyncOnDispatchQueue:(dispatch_queue_t)dispatchQueue block:(void (^)(id receiver))block;

- (id)pgws_useReceiverSyncOnDispatchQueue:(dispatch_queue_t)dispatchQueue returningResultFromBlock:(id (^)(id receiver))block;
- (BOOL)pgws_useReceiverSyncOnDispatchQueue:(dispatch_queue_t)dispatchQueue returningBoolResultFromBlock:(BOOL (^)(id receiver))block;

@end
