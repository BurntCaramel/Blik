//
//  GLAFolderQuery.h
//  Blik
//
//  Created by Patrick Smith on 14/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAModel.h"
#import "GLACollectedFile.h"


@protocol GLAFolderQueryEditing <NSObject>

@property(readwrite, copy, nonatomic) GLACollectedFile *collectedFileForFolderURL;
@property(readwrite, copy, nonatomic) NSArray *tagNames;

@end


@interface GLAFolderQuery : GLAModel

- (instancetype)initCreatingByEditing:(void(^)(id<GLAFolderQueryEditing> editor))editingBlock;

- (instancetype)copyWithChangesFromEditing:(void(^)(id<GLAFolderQueryEditing> editor))editingBlock;

@property(readonly, copy, nonatomic) GLACollectedFile *collectedFileForFolderURL;
//@property(readonly, copy, nonatomic) NSURL *folderURL;
@property(readonly, copy, nonatomic) NSArray *tagNames;
//@property(copy, nonatomic) NSSet *ignoredFileNames;

- (NSString *)fileMetadataQueryRepresentation;


+ (NSSet *)availableTagNamesInsideFolderURL:(NSURL *)folderURL;

@end
