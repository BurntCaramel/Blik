//
//  GLAProject.h
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "GLACollection.h"
#import "GLAReminder.h"
#import "GLAArrayEditing.h"
#import "Mantle/Mantle.h"


@protocol GLAProjectEditing <NSObject>

@property(readwrite, copy, nonatomic) NSString *name;

@end


@interface GLAProject : MTLModel <MTLJSONSerializing>

// Designated init
- (instancetype)initWithUUID:(NSUUID *)UUID name:(NSString *)name dateCreated:(NSDate *)dateCreated;

@property(readonly, nonatomic) NSUUID *UUID;
@property(readonly, copy, nonatomic) NSString *name;
@property(readonly, nonatomic) NSDate *dateCreated;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAProjectEditing> editor))editingBlock;

@end
