//
//  GLAMainContentManners.h
//  Blik
//
//  Created by Patrick Smith on 15/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAProjectManager.h"
#import "GLAProject.h"
#import "GLAMainSectionNavigator.h"


@interface GLAMainContentManners : NSObject

+ (instancetype)sharedManners;

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager NS_DESIGNATED_INITIALIZER;

#pragma mark -

@property(readonly, nonatomic) GLAProjectManager *projectManager;

- (void)askToPermanentlyDeleteProject:(GLAProject *)project fromView:(NSView *)view;
- (void)askToPermanentlyDeleteCollection:(GLACollection *)collection fromView:(NSView *)view;

@end
