//
//  GLAPendingAddedCollectedFilesInfo.m
//  Blik
//
//  Created by Patrick Smith on 10/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAPendingAddedCollectedFilesInfo.h"


@implementation GLAPendingAddedCollectedFilesInfo

- (instancetype)initWithFileURLs:(NSArray *)fileURLs
{
	self = [super init];
	if (self) {
		_fileURLs = [fileURLs copy];
	}
	return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	return self;
}

@end
