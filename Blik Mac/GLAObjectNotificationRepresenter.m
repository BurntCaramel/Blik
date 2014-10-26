//
//  GLAObjectNotificationRepresenter.m
//  Blik
//
//  Created by Patrick Smith on 23/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAObjectNotificationRepresenter.h"


@implementation GLAObjectNotificationRepresenter

- (instancetype)initWithUUID:(NSUUID *)UUID
{
	self = [super init];
	if (self) {
		_UUID = UUID;
	}
	return self;
}

@end
