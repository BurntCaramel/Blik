//
//  GLAModelUUIDMap.h
//  Blik
//
//  Created by Patrick Smith on 29/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAModel.h"
#import "GLAArrayEditor.h"


@interface GLAModelUUIDMap : NSObject <GLAArrayEditorIndexing>

- (GLAModel *)objectWithUUID:(NSUUID *)UUID;
- (NSArray *)allObjects;

- (GLAModel *)objectForKeyedSubscript:(NSUUID *)UUID;

#pragma mark -

- (void)addObjects:(NSArray *)objects;

- (void)removeObjects:(NSArray *)objects;
- (void)removeAllObjects;

- (void)setObjects:(NSArray *)objects additionsAndRemovalsBlock:(void(^)(NSArray *additions, NSArray *removals))block;

@end
