//
//  GLAObjectNotificationRepresenter.h
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;


@interface GLAObjectNotificationRepresenter : NSObject

- (instancetype)initWithUUID:(NSUUID *)UUID;

@property(nonatomic, readonly) NSUUID *UUID;

@end
