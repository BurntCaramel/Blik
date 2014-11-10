//
//  GLAModelArrayEditorStore.h
//  Blik
//
//  Created by Patrick Smith on 9/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAArrayEditorStore.h"
#import "GLAModel.h"
#import "GLAModelUUIDMap.h"


@interface GLAModelArrayEditorStore : GLAArrayEditorStore

@property(nonatomic) GLAModelUUIDMap *modelUUIDMap;

- (GLAModel *)modelWithUUID:(NSUUID *)UUID;

@end
