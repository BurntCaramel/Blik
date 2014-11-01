//
//  GLAProject.h
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAModel.h"
#import "GLACollection.h"
#import "GLAReminder.h"
#import "GLAArrayEditing.h"


@protocol GLAProjectEditing <NSObject>

@property(readwrite, copy, nonatomic) NSString *name;

@end


@interface GLAProject : GLAModel

// Designated init
- (instancetype)initWithName:(NSString *)name dateCreated:(NSDate *)dateCreated;

@property(readonly, nonatomic) NSDate *dateCreated;

@property(readonly, copy, nonatomic) NSString *name;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAProjectEditing> editor))editingBlock;

@end
