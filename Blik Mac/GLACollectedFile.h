//
//  GLACollectedFile.h
//  Blik
//
//  Created by Patrick Smith on 2/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAModel.h"
#import "GLACollection.h"

/*
@protocol GLACollectedFileInfoReading <NSObject>

@property(readonly, nonatomic) NSString *displayName;

@end
*/

@interface GLACollectedFile : GLAModel <GLACollectedItem>

- (instancetype)initWithFileURL:(NSURL *)URL;

@property(readonly, nonatomic) NSURL *URL;

//- (NSOperation *)newOperationToUpdateInformation;
//- (void)updateInformation:(dispatch_block_t)completionBlock;
- (void)updateInformationWithError:(NSError *__autoreleasing *)error; // Blocks: recommended to call this on a background queue.

@property(readonly, nonatomic) BOOL isMissing;
@property(readonly, nonatomic) BOOL isDirectory;
@property(readonly, nonatomic) BOOL isExecutable;
@property(readonly, copy, nonatomic) NSString *name;

- (NSData *)bookmarkDataWithError:(NSError *__autoreleasing *)error;
@property(readonly, nonatomic) NSData *bookmarkData;

@end
