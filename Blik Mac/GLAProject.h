//
//  GLAProject.h
//  Blik
//
//  Created by Patrick Smith on 24/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAModel.h"
#import "GLACollection.h"
#import "GLACollectedFile.h"
#import "GLAArrayEditing.h"


@protocol GLAProjectEditing <NSObject>

@property(copy, nonatomic) NSString *name;

@property(nonatomic) BOOL hideFromLauncherMenu;
@property(nonatomic) BOOL groupHighlights;

@end


@interface GLAProject : GLAModel

// Designated init
- (instancetype)initWithName:(NSString *)name dateCreated:(NSDate *)dateCreated groupHighlights:(BOOL)groupHighlights;

@property(readonly, nonatomic) NSDate *dateCreated;
@property(readonly, copy, nonatomic) NSString *name;

@property(readonly, nonatomic) BOOL hideFromLauncherMenu;
@property(readonly, nonatomic) BOOL groupHighlights;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAProjectEditing> editor))editingBlock;

@end
