//
//  GLAModelUUIDMap.m
//  Blik
//
//  Created by Patrick Smith on 29/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAModelUUIDMap.h"


@interface GLAModelUUIDMap ()

@property(nonatomic) NSMutableDictionary *mutableDictionary;

@end

@implementation GLAModelUUIDMap

- (instancetype)init
{
	self = [super init];
	if (self) {
		_mutableDictionary = [NSMutableDictionary new];
	}
	return self;
}

- (void)addObjectsReplacing:(NSArray *)objects
{
	NSMutableDictionary *mutableDictionary = (self.mutableDictionary);
	for (GLAModel *model in objects) {
		mutableDictionary[model.UUID] = model;
	}
}

- (void)removeObjects:(NSArray *)objects
{
	NSMutableDictionary *mutableDictionary = (self.mutableDictionary);
	[mutableDictionary removeObjectsForKeys:[objects valueForKey:@"UUID"]];
}

- (GLAModel *)objectWithUUID:(NSUUID *)UUID
{
	NSMutableDictionary *mutableDictionary = (self.mutableDictionary);
	return mutableDictionary[UUID];
}

@end
