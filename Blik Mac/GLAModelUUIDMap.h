//
//  GLAModelUUIDMap.h
//  Blik
//
//  Created by Patrick Smith on 29/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAModel.h"


@interface GLAModelUUIDMap : NSObject

- (void)addObjectsReplacing:(NSArray *)objects;
- (void)removeObjects:(NSArray *)objects;

- (GLAModel *)objectWithUUID:(NSUUID *)UUID;

@end
