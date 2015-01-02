//
//  GLAMainSectionNavigator.h
//  Blik
//
//  Created by Patrick Smith on 11/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLAMainSection.h"
#import "GLAProject.h"
#import "GLAProjectManager.h"
#import "GLAPendingAddedCollectedFilesInfo.h"


@protocol GLAMainSectionNavigationStateReading <NSObject>

@property(readonly, nonatomic) GLAMainSection *currentSection;

@end

@interface GLAMainSectionNavigator : NSObject <GLAMainSectionNavigationStateReading>

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager NS_DESIGNATED_INITIALIZER;

@property(nonatomic) GLAProjectManager *projectManager;

- (void)goToSection:(GLAMainSection *)newSection;
- (void)goToPreviousSection;

- (void)goToAllProjects;

- (void)goToNowProject;

- (void)goToProject:(GLAProject *)project;

- (void)addNewProject;

- (void)goToCollection:(GLACollection *)collection;

- (void)addNewCollectionToProject:(GLAProject *)project;
- (void)addNewCollectionToProject:(GLAProject *)project pendingCollectedFilesInfo:(GLAPendingAddedCollectedFilesInfo *)pendingCollectedFilesInfo;

@end


extern NSString *GLAMainSectionNavigatorDidChangeCurrentSectionNotification;
extern NSString *GLAMainSectionNavigatorNotificationUserInfoPreviousSection;
