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

+ (instancetype)sharedProjectManager; // Works on the main queue

@property(readonly, nonatomic) NSOperationQueue *receivingOperationQueue; // Main queue by default

@property(nonatomic) BOOL shouldLoadTestProjects;

#pragma mark Using Projects

// Lazy loaded

- (void)requestAllProjects;
- (void)requestPlannedProjects;
- (void)requestNowProject;

- (void)requestCollectionsForProject:(GLAProject *)project;
- (void)requestRemindersForProject:(GLAProject *)project;

// All of these may be nil until they are loaded.
// Use the notifications below to react to when they are ready.
@property(readonly, copy, nonatomic) NSArray *allProjectsSortedByDateCreatedNewestToOldest;
@property(readonly, copy, nonatomic) NSArray *plannedProjects;
@property(readonly, copy, nonatomic) GLAProject *nowProject;

- (NSArray *)copyCollectionsForProject:(GLAProject *)project;

#pragma mark Editing

- (void)changeNowProject:(id<GLAProjectBaseReading>)project;

- (GLAProject *)createNewProjectWithName:(NSString *)name;

- (void)renameProject:(GLAProject *)project toString:(NSString *)name;

- (void)deleteProjectPermanently:(GLAProject *)project;
//- (id<GLAProjectEditing>)editProject:(id<GLAProjectBaseReading>)project;

- (BOOL)editProjectCollections:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> collectionListEditor))block;
//- (id<GLAProjectEditing>)editProject:(GLAProject *)project;

- (GLACollection *)editCollection:(GLACollection *)collection inProject:(GLAProject *)project usingBlock:(void(^)(id<GLACollectionEditing>collectionEditor))editBlock;

- (GLACollection *)renameCollection:(GLACollection *)collection inProject:(GLAProject *)project toString:(NSString *)name;
- (GLACollection *)changeColorOfCollection:(GLACollection *)collection inProject:(GLAProject *)project toColor:(GLACollectionColor *)color;

#pragma mark Saving

- (void)saveAllProjects;
- (void)saveCollectionsForProject:(GLAProject *)project;

#pragma mark Project Changes

- (void)projectNameDidChange:(GLAProject *)project; // Name

- (void)collectionListForProjectDidChange:(GLAProject *)project; // Added, removed, reordered
- (void)projectRemindersListDidChange:(GLAProject *)project; // Added, removed

- (void)collectionDidChange:(GLACollection *)collection insideProject:(GLAProject *)project; // Renamed, color changed, content changed.

- (void)reminderDidChange:(GLACollection *)collection insideProject:(GLAProject *)project;

@end


extern NSString *GLAProjectManagerAllProjectsDidChangeNotification;
extern NSString *GLAProjectManagerPlannedProjectsDidChangeNotification;
extern NSString *GLAProjectManagerNowProjectDidChangeNotification;

extern NSString *GLAProjectManagerProjectCollectionsDidChangeNotification;
extern NSString *GLAProjectManagerCollectionPropertiesDidChangeNotification;

extern NSString *GLAProjectManagerProjectRemindersDidChangeNotification;

extern NSString *GLAProjectManagerNotificationProjectKey;
extern NSString *GLAProjectManagerNotificationChangedPropertiesKey;
