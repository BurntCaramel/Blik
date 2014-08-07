//
//  GLACollectionFileContent.h
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollectionContent.h"
#import "GLAArrayEditing.h"
@class GLACollectedFile;


@interface GLACollectionFilesListContent : GLACollectionContent

@property(nonatomic) id<GLAArrayEditing> filesListEditing;
- (NSArray/*[GLACollectedFile]*/ *)copyFiles;

@end
