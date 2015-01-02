//
//  GLAPendingAddedCollectedFilesInfo.h
//  Blik
//
//  Created by Patrick Smith on 10/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLACollectedFile.h"


@interface GLAPendingAddedCollectedFilesInfo : NSObject <NSCopying>

- (instancetype)initWithFileURLs:(NSArray *)fileURLs;

@property(readonly, copy, nonatomic) NSArray *fileURLs;

@end
