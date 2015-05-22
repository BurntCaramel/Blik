//
//  GLAFileCollecting.h
//  Blik
//
//  Created by Patrick Smith on 22/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol GLAFileCollecting <NSObject>

- (BOOL)fileURLsAreAllCollected:(NSArray *)fileURLs;
- (void)addFileURLsToCollection:(NSArray *)fileURLs;
- (void)removeFileURLsFromCollection:(NSArray *)fileURLs;

@end

NS_ASSUME_NONNULL_END
