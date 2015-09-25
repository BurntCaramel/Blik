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


- (BOOL)hasLoadedPermittedApplicationFolders;
- (void)loadPermittedApplicationFolders;
- (NSArray *)copyPermittedApplicationFolders;
- (void)editPermittedApplicationFoldersUsingBlock:(void (^)(id<GLAArrayEditing> foldersEditor))block;

- (id<GLALoadableArrayUsing>)usePermittedApplicationFolders;

- (void)ensureAccessToPermittedApplicationsFolders;

#pragma mark -

@property(nonatomic) BOOL hidesMainWindowWhenInactive;
- (IBAction)toggleHidesMainWindowWhenInactive:(id)sender;

@end

extern NSString *GLAApplicationSettingsManagerPermittedApplicationFoldersDidChangeNotification;
extern NSString *GLAApplicationSettingsManagerHideMainWindowWhenInactiveDidChangeNotification;
