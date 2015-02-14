//
//  GLACollectedFile.h
//  Blik
//
//  Created by Patrick Smith on 2/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAModel.h"
#import "GLACollection.h"
#import "GLAArrayEditing.h"
#import "GLAAccessedFileInfo.h"


@interface GLACollectedFile : GLAModel <GLACollectedItem>

- (instancetype)initWithFileURL:(NSURL *)fileURL;

+ (NSArray *)collectedFilesWithFileURLs:(NSArray *)fileURLs;
+ (NSArray *)filePathsURLsForCollectedFiles:(NSArray *)collectedFiles ignoreMissing:(BOOL)ignoreMissing;

+ (NSArray *)filteredCollectedFiles:(NSArray *)collectedFiles notAlreadyPresentInArrayInspector:(id<GLAArrayInspecting>)inspectableArray;

// Retain this if you want this to be cached.
- (GLAAccessedFileInfo *)accessFile;

//@property(readonly, nonatomic) NSURL *filePathURL;
//@property(readonly, nonatomic) NSURL *fileReferenceURL;
@property(readonly, nonatomic) BOOL wasCreatedFromBookmarkData; // If true, needs -startAccessingSecurityScopedResource

@property(nonatomic) NSData *sourceBookmarkData;

- (NSData *)bookmarkDataWithError:(NSError *__autoreleasing *)error;
@property(readonly, nonatomic) NSData *bookmarkData;

@end
