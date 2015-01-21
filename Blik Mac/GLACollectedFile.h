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

/*
@protocol GLACollectedFileInfoReading <NSObject>

@property(readonly, nonatomic) NSString *displayName;

@end
*/

@interface GLACollectedFile : GLAModel <GLACollectedItem>

- (instancetype)initWithFileURL:(NSURL *)fileURL;

+ (NSArray *)collectedFilesWithFileURLs:(NSArray *)fileURLs;
+ (NSArray *)filePathsURLsForCollectedFiles:(NSArray *)collectedFiles ignoreMissing:(BOOL)ignoreMissing;

+ (NSArray *)filteredCollectedFiles:(NSArray *)collectedFiles notAlreadyPresentInArrayInspector:(id<GLAArrayInspecting>)inspectableArray;

@property(readonly, nonatomic) NSURL *filePathURL;
@property(readonly, nonatomic) NSURL *fileReferenceURL;
@property(readonly, nonatomic) BOOL wasCreatedFromBookmarkData; // If true, needs -startAccessingSecurityScopedResource

//- (NSOperation *)newOperationToUpdateInformation;
//- (void)updateInformation:(dispatch_block_t)completionBlock;
- (BOOL)updateInformationWithError:(NSError *__autoreleasing *)error; // Synchronous: recommended to call this on a background queue.

@property(readonly, nonatomic) BOOL isMissing;
@property(readonly, nonatomic) BOOL isDirectory;
@property(readonly, nonatomic) BOOL isExecutable;
@property(readonly, copy, nonatomic) NSString *name;

- (NSData *)bookmarkDataWithError:(NSError *__autoreleasing *)error;
@property(readonly, nonatomic) NSData *bookmarkData;

@end
