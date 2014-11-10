//
//  GLAModelArrayEditorStore.m
//  Blik
//
//  Created by Patrick Smith on 9/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAModelArrayEditorStore.h"


@implementation GLAModelArrayEditorStore

- (void)setUpArrayEditorOptions:(GLAArrayEditorOptions *)options
{
	[super setUpArrayEditorOptions:options];
	
	GLAModelUUIDMap *modelUUIDMap = [GLAModelUUIDMap new];
	(self.modelUUIDMap) = modelUUIDMap;
	
	[options addObserver:modelUUIDMap];
}

- (GLAModel *)modelWithUUID:(NSUUID *)UUID
{
	GLAModelUUIDMap *modelUUIDMap = (self.modelUUIDMap);
	return [modelUUIDMap objectWithUUID:UUID];
}

@end
