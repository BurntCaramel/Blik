//
//  GLAProjectManager.h
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAProject.h"
#import "GLACollection.h"


@interface GLAProjectManager : NSObject

+ (instancetype)sharedProjectManager;

#pragma mark Using Projects

- (void)useAllProjects:(void(^)(NSArray *allProjects))allProjectsReceiver;
- (void)usePlannedProjects:(void(^)(NSArray *plannedProjects))plannedProjectsReceiver;

#pragma mark Project Changes

- (void)projectDetailsDidChange:(GLAProject *)project; // Name
- (void)projectCollectionsListDidChange:(GLAProject *)project; // Added, removed, reordered
- (void)projectRemindersListDidChange:(GLAProject *)project; // Added, removed

- (void)collectionDidChange:(GLACollection *)collection insideProject:(GLAProject *)project;
- (void)reminderDidChange:(GLACollection *)collection insideProject:(GLAProject *)project;

//- (void)saveProject:(GLAProject *)project;

@end
