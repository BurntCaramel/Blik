//
//  GLAApplicationSettingsManager.h
//  Blik
//
//  Created by Patrick Smith on 7/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAArrayEditing.h"


@interface GLAApplicationSettingsManager : NSObject

+ (instancetype)sharedApplicationSettingsManager; // Works on the main queue


- (void)loadPermittedApplicationFolders;
- (NSArray *)copyPermittedApplicationFolders;
- (BOOL)editPermittedApplicationFoldersUsingBlock:(void (^)(id<GLAArrayEditing> foldersEditor))block;

@end
