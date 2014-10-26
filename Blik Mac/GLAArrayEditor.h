//
//  GLAArrayEditor.h
//  Blik
//
//  Created by Patrick Smith on 4/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "GLAArrayEditing.h"

@class GLAArrayEditorChanges;


@interface GLAArrayEditor : NSObject <GLAArrayEditing>

// Designated init
- (instancetype)initWithObjects:(NSArray *)objects;
- (instancetype)init;

- (GLAArrayEditorChanges *)changesMadeInBlock:(void (^)(id<GLAArrayEditing> arrayEditor))editorBlock;

@end


@interface GLAArrayEditorChanges : NSObject

@property(nonatomic) NSArray *addedChildren;
@property(nonatomic) NSArray *removedChildren;

@property(nonatomic) NSArray *replacedChildrenBefore;
@property(nonatomic) NSArray *replacedChildrenAfter;

@end
