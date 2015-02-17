//
//  GLAFolderQuery.h
//  Blik
//
//  Created by Patrick Smith on 14/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAModel.h"


@protocol GLAFolderQueryEditing <NSObject>

@property(readwrite, copy, nonatomic) NSSet *tagNames;

@end


@interface GLAFolderQuery : GLAModel

+ (NSSet *)availableTagNamesInsideFolderURL:(NSURL *)folderURL;

- (instancetype)initCreatingByEditing:(void(^)(id<GLAFolderQueryEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAFolderQueryEditing> editor))editingBlock;

@property(readonly, copy, nonatomic) NSSet *tagNames;
//@property(copy, nonatomic) NSSet *ignoredFileNames;

- (NSString *)fileMetadataQueryRepresentation;

@end
