//
//  GLAModelUUIDMap.h
//  Blik
//
//  Created by Patrick Smith on 29/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAModel.h"
#import "GLAArrayEditor.h"


@interface GLAModelUUIDMap : NSObject <GLAArrayObserving>

- (void)addObjectsReplacing:(NSArray *)objects;

- (void)setObjects:(NSArray *)objects additionsAndRemovalsBlock:(void(^)(NSArray *additions, NSArray *removals))block;

- (void)removeObjects:(NSArray *)objects;
- (void)removeAllObjects;

- (GLAModel *)objectWithUUID:(NSUUID *)UUID;
- (BOOL)containsObjectWithUUID:(NSUUID *)UUID;

- (GLAModel *)objectForKeyedSubscript:(NSUUID *)UUID;

@end
