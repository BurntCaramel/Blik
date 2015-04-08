//
//  GLAFileInfo.h
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;


@protocol GLAFileAccessing <NSObject>

@property(readonly, nonatomic) NSURL *filePathURL;

@end


@interface GLAAccessedFileInfo : NSObject <GLAFileAccessing>

- (instancetype)initWithFileURL:(NSURL *)fileURL sourceBookmarkData:(NSData *)bookmarkData NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithBookmarkData:(NSData *)bookmarkData;
- (instancetype)initWithFileURL:(NSURL *)fileURL;

@property(readonly, copy, nonatomic) NSError *errorResolving;
@property(readonly, copy, nonatomic) NSData *sourceBookmarkData;

@property(readonly, nonatomic) NSURL *filePathURL;

- (void)resolveFilePathURLAgain;

//@property(readonly, nonatomic) NSURL *fileReferenceURL;

@end
