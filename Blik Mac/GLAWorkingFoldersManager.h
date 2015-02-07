//
//  GLAWorkingFoldersManager.h
//  Blik
//
//  Created by Patrick Smith on 7/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;


@interface GLAWorkingFoldersManager : NSObject

+ (instancetype)sharedWorkingFoldersManager;

- (NSURL *)version1DirectoryURLWithInnerDirectoryComponents:(NSArray *)extraPathComponents;
- (NSURL *)version1DirectoryURL;

@end
