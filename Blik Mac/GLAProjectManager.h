//
//  GLAProjectManager.h
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Foundation;
#import "GLAProject.h"
#import "GLACollection.h"
#import "GLAHighlightedItem.h"


@interface GLAProjectManager : NSObject

+ (instancetype)sharedProjectManager; // Works on the main queue

@property(readonly, nonatomic) NSOperationQueue *receivingOperationQueue; // Main queue by default

@property(nonatomic) BOOL shouldLoadTestProjects;

#pragma mark Status

- (NSString *)statusOfCurrentActivity;
- (NSString *)statusOfCompletedActivity;

#pragma mark Using Projects

#pragma mark Projects

- (void)loadAllProjects;
- (void)loadNowProject;

// All of these may be nil until they are loaded.
// Use the notifications below to react to when they are ready.
@property(readonly, copy, nonatomic) NSArray *allProjectsSortedByDateCreatedNewestToOldest;
//@property(readonly, copy, nonatomic) NSArray *plannedProjects;

- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID;

- (GLAProject *)createNewProjectWithName:(NSString *)name;

- (GLAProject *)renameProject:(GLAProject *)project toName:(NSString *)name;

- (void)deleteProjectPermanently:(GLAProject *)project;


#pragma mark Now Project

@property(readonly, copy, nonatomic) GLAProject *nowProject;

- (void)changeNowProject:(GLAProject *)project;

#pragma mark Collections

- (void)loadCollectionsForProject:(GLAProject *)project;
- (NSArray *)copyCollectionsForProject:(GLAProject *)project;

- (NSUUID *)projectUUIDHoldingCollectionWithUUID:(NSUUID *)collectionUUID;
- (GLAProject *)projectHoldingCollection:(Collection *)collection;
- (GLACollection *)canonicalCollectionForCollection:(GLACollection *)collection;

- (BOOL)editProjectCollections:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> collectionListEditor))block;
//- (id<GLAProjectEditing>)editProject:(GLAProject *)project;

- (GLACollection *)createNewCollectionWithName:(NSString *)name type:(NSString *)type color:(GLACollectionColor *)color inProject:(GLAProject *)project;

- (GLACollection *)editCollection:(GLACollection *)collection inProject:(GLAProject *)project usingBlock:(void(^)(id<GLACollectionEditing>collectionEditor))editBlock;

- (GLACollection *)renameCollection:(GLACollection *)collection inProject:(GLAProject *)project toString:(NSString *)name;
- (GLACollection *)changeColorOfCollection:(GLACollection *)collection inProject:(GLAProject *)project toColor:(GLACollectionColor *)color;

- (void)permanentlyDeleteCollection:(GLACollection *)collection fromProject:(GLAProject *)project;

#pragma mark Highlights

- (void)loadHighlightsForProject:(GLAProject *)project;
- (NSArray /* GLAHighlightedItem */ *)copyHighlightsForProject:(GLAProject *)project;

- (BOOL)editHighlightsOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> highlightsEditor))block;

//- (void)addCollectedItemToHighlights:(id<GLACollectedItem>)collectedItem;

#pragma mark Collection Files List

- (void)loadFilesListForCollection:(GLACollection *)filesListCollection;
- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection;

- (BOOL)editFilesListOfCollection:(GLACollection *)filesListCollection usingBlock:(void (^)(id<GLAArrayEditing> filesListEditor))block;

#pragma mark Validating

- (BOOL)nameIsValid:(NSString *)name;
- (NSString *)normalizeName:(NSString *)name;

#pragma mark Saving

- (void)requestSaveAllProjects;
- (void)requestSaveCollectionsForProject:(GLAProject *)project;
- (void)requestSaveFilesListForCollections:(GLACollection *)filesListCollection;

#pragma mark Project Changes

- (void)collectionListForProjectDidChange:(GLAProject *)project; // Added, removed, reordered

- (void)projectRemindersListDidChange:(GLAProject *)project; // Added, removed

- (void)filesListForCollectionDidChange:(GLACollection *)collection; // Added, removed, reordered

- (void)collectionDidChange:(GLACollection *)collection insideProject:(GLAProject *)project; // Renamed, color changed, content changed.

//- (void)reminderDidChange:(GLACollection *)collection insideProject:(GLAProject *)project;

#pragma mark Notifications

- (id)notificationObjectForProject:(GLAProject *)project;
- (id)notificationObjectForCollection:(GLACollection *)collection;

//- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName project:(GLAProject *)project;

@end


extern NSString *GLAProjectManagerAllProjectsDidChangeNotification;
extern NSString *GLAProjectManagerPlannedProjectsDidChangeNotification;
extern NSString *GLAProjectManagerNowProjectDidChangeNotification;

// Object GLAProject
extern NSString *GLAProjectCollectionsDidChangeNotification;
extern NSString *GLAProjectHighlightsDidChangeNotification;

// Object: GLACollection
extern NSString *GLACollectionFilesListDidChangeNotification;

//extern NSString *GLAProjectManagerProjectRemindersDidChangeNotification;

//extern NSString *GLAProjectManagerNotificationChangedPropertiesKey;
