//
//  GLAProjectManager.m
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAProjectManager.h"
#import "Mantle/Mantle.h"
#import "GLAModelErrors.h"
#import "GLACollection.h"
#import "GLACollectionColor.h"
#import "GLACollectedFile.h"
#import "GLAArrayEditor.h"
#import "GLAModelArrayEditorStore.h"
#import "GLAArrayEditorStore.h"
#import "GLAArrayMantleJSONStore.h"
#import "GLAObjectNotificationRepresenter.h"
#import "GLAModelUUIDMap.h"

@class GLAProjectManagerStore;


@interface GLAProjectManagerStore : NSObject

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager;

@property(weak, nonatomic) GLAProjectManager *projectManager;

@property(readonly, nonatomic) NSURL *version1DirectoryURL;

- (NSString *)statusOfCurrentActivity;
- (NSString *)statusOfCompletedActivity;

#pragma mark All Projects

- (BOOL)hasLoadedAllProjects;
- (void)loadAllProjectsIfNeeded;
@property(readonly, nonatomic) GLAModelArrayEditorStore *allProjectsEditorStore;
@property(readonly, nonatomic) GLAArrayEditor *allProjectsEditor;

- (NSArray *)copyAllProjects;
- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID;

//- (NSSet *)loadedProjectUUIDsContainingCollection:(GLACollection *)collection;

- (void)requestSaveAllProjects;

- (void)permanentlyDeleteAssociatedFilesForProjects:(NSArray *)projects;

#pragma mark Now Project

- (void)loadNowProjectIfNeeded;
@property(readonly, copy, nonatomic) NSUUID *nowProjectUUID;
@property(readonly, nonatomic) GLAProject *nowProject;

- (void)changeNowProject:(GLAProject *)project;
- (void)requestSaveNowProject;

#pragma mark Collections

- (BOOL)hasLoadedCollectionsForProject:(GLAProject *)project;
- (void)loadCollectionsForProjectIfNeeded:(GLAProject *)project;
- (GLAModelArrayEditorStore *)collectionsEditorStoreForProject:(GLAProject *)project;
- (NSArray *)copyCollectionsForProject:(GLAProject *)project;

- (void)requestSaveCollectionsForProject:(GLAProject *)project;

- (void)clearCollectionsEditorStoreForProject:(GLAProject *)project;
- (void)permanentlyDeleteAssociatedFilesForCollections:(NSArray *)collections;

- (BOOL)collectionWithUUIDIsFreshlyCreated:(NSUUID *)collectionUUID;
- (void)addFreshlyCreatedCollectionWithUUID:(NSUUID *)collectionUUID;

#pragma mark Highlights

- (BOOL)hasLoadedHighlightsForProject:(GLAProject *)project;
- (void)loadHighlightsForProjectIfNeeded:(GLAProject *)project;
- (GLAArrayEditorStore *)highlightsEditorStoreForProject:(GLAProject *)project;
- (NSArray /*id<GLACollectedItem>*/ *)copyHighlightsForProject:(GLAProject *)project;

#pragma mark Collection Files List

- (BOOL)hasLoadedFilesForCollection:(GLACollection *)filesListCollection;
- (void)loadFilesListForCollectionIfNeeded:(GLACollection *)filesListCollection;

- (GLAArrayEditorStore *)filesListEditorStoreForCollection:(GLACollection *)filesListCollection;

- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection;
- (GLACollectedFile *)collectedFileWithUUID:(NSUUID *)collectionUUID insideCollection:(GLACollection *)filesListCollection;

- (void)requestSaveFilesListForCollection:(GLACollection *)filesListCollection;

@end


NSString *GLAProjectManagerJSONAllProjectsKey = @"allProjects";
NSString *GLAProjectManagerJSONNowProjectKey = @"nowProject";
NSString *GLAProjectManagerJSONCollectionsListKey = @"collectionsList";
NSString *GLAProjectManagerJSONHighlightsListKey = @"highlightsList";
NSString *GLAProjectManagerJSONFilesListKey = @"filesList";


@interface GLAProjectManager ()

@property(nonatomic) GLAProjectManagerStore *store;

@property(nonatomic) NSMutableDictionary *projectUUIDNotificationRepresenters;
@property(nonatomic) NSMutableDictionary *collectionUUIDNotificationRepresenters;

@property(nonatomic) NSMutableDictionary *collectionUUIDsToPendingAddedCollectedFiles;


- (void)allProjectsDidChange;
- (void)plannedProjectsDidChange;
- (void)nowProjectDidChange;

- (void)collectionListForProjectDidChange:(GLAProject *)project;
- (void)highlightsListForProjectDidChange:(GLAProject *)project;

@end

#pragma mark -

@implementation GLAProjectManager

- (instancetype)init
{
    self = [super init];
    if (self) {
		_store = [[GLAProjectManagerStore alloc] initWithProjectManager:self];
    }
    return self;
}

+ (instancetype)sharedProjectManager
{
	static GLAProjectManager *sharedProjectManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedProjectManager = [GLAProjectManager new];
	});
	
	return sharedProjectManager;
}

#pragma mark -

- (NSOperationQueue *)receivingOperationQueue
{
	return [NSOperationQueue mainQueue];
}

- (void)handleError:(NSError *)error fromSelector:(SEL)selector
{
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		NSLog(@"ERROR %@ %@", error, NSStringFromSelector(selector));
		//TODO: something a bit more elegant?
		//[NSApp presentError:error];
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}];
}

#pragma mark All Projects

- (void)loadAllProjectsIfNeeded
{
	[(self.store) loadAllProjectsIfNeeded];
}

- (NSArray *)copyAllProjects
{
	return [(self.store) copyAllProjects];
}

- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Project UUID must not be nil.");
	return [(self.store) projectWithUUID:projectUUID];
}

- (BOOL)editAllProjectsUsingBlock:(void (^)(id<GLAArrayEditing> allProjectsEditor))block
{
	GLAProjectManagerStore *store = (self.store);
	GLAArrayEditor *allProjectsEditor = (store.allProjectsEditor);
	NSAssert(allProjectsEditor != nil, @"Store must have an 'all projects editor'");
	
	 if (allProjectsEditor.needsLoadingFromStore) {
		return NO;
	}
	
	GLAArrayEditorChanges *changes = [allProjectsEditor changesMadeInBlock:block];
	if (changes.hasChanges) {
		[self projectsDidChange:(changes.addedChildren)];
		[self projectsDidChange:(changes.replacedChildrenAfter)];
		[store permanentlyDeleteAssociatedFilesForProjects:(changes.removedChildren)];
		
		[self allProjectsDidChange];
		
		return YES;
	}
	else {
		return NO;
	}
}

- (void)loadNowProjectIfNeeded
{
	[(self.store) loadNowProjectIfNeeded];
}

- (GLAProject *)createNewProjectWithName:(NSString *)name
{
	GLAProject *project = [[GLAProject alloc] initWithName:name dateCreated:nil];
	
	[self editAllProjectsUsingBlock:^(id<GLAArrayEditing> allProjectsEditor) {
		[allProjectsEditor addChildren:@[project]];
	}];
	
	return project;
}

- (GLAProject *)renameProject:(GLAProject *)project toName:(NSString *)name
{
	__block GLAProject *changedProject = nil;
	
	GLAProject *(^ projectReplacer)(GLAProject *project) = ^GLAProject *(GLAProject *originalProject) {
		return [originalProject copyWithChangesFromEditing:^(id<GLAProjectEditing> editor) {
			(editor.name) = name;
		}];
	};
	
	[self editAllProjectsUsingBlock:^(id<GLAArrayEditing> allProjectsEditor) {
		changedProject = [allProjectsEditor replaceFirstChildWhoseKey:@"UUID" hasValue:(project.UUID) usingChangeBlock:projectReplacer];
	}];
	
	return changedProject;
}

- (void)permanentlyDeleteProject:(GLAProject *)project
{
	[self editAllProjectsUsingBlock:^(id<GLAArrayEditing> allProjectsEditor) {
		[allProjectsEditor removeFirstChildWhoseKey:@"UUID" hasValue:(project.UUID)];
	}];
	
	[self projectWasDeleted:project];
}

#pragma mark Now Project

- (GLAProject *)nowProject
{
	return (self.store.nowProject);
}

- (void)changeNowProject:(GLAProject *)project
{
	GLAProjectManagerStore *store = (self.store);
	
	[store changeNowProject:project];
	[self nowProjectDidChange];
	
	[store requestSaveNowProject];
}

#pragma mark Collections

- (BOOL)hasLoadedCollectionsForProject:(GLAProject *)project
{
	NSAssert(project != nil, @"Project must not be nil.");
	return [(self.store) hasLoadedCollectionsForProject:project];
}

- (void)loadCollectionsForProjectIfNeeded:(GLAProject *)project
{
	NSAssert(project != nil, @"Project must not be nil.");
	[(self.store) loadCollectionsForProjectIfNeeded:project];
}

- (NSArray *)copyCollectionsForProject:(GLAProject *)project
{
	return [(self.store) copyCollectionsForProject:project];
}

- (BOOL)editCollectionsOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing> collectionsEditor))block
{
	GLAProjectManagerStore *store = (self.store);
	GLAModelArrayEditorStore *collectionsEditorStore = [store collectionsEditorStoreForProject:project];
	
	[collectionsEditorStore
	 editUsingBlock:block
	 handleAddedChildren:^(NSArray *addedChildren)
	 {
		 [self collectionsDidChange:addedChildren];
	 }
	 handleRemovedChildren:^(NSArray *removedChildren)
	 {
		 [self removeHighlightedItemsWithCollections:removedChildren fromProject:project];
		 [store permanentlyDeleteAssociatedFilesForCollections:removedChildren];
	 }
	 handleReplacedChildren:^(NSArray *originalChildren, NSArray *replacementChildren)
	 {
		 [self collectionsDidChange:replacementChildren];
	 }];
	
	[self collectionListForProjectDidChange:project];
	
	return YES;
}

- (GLACollection *)createNewCollectionWithName:(NSString *)name type:(NSString *)type color:(GLACollectionColor *)color inProject:(GLAProject *)project
{
	NSAssert(project != nil, @"Passed project must not be nil.");
	
	GLACollection *collection = [[GLACollection alloc] initWithType:type creatingFromEditing:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.name) = name;
		(collectionEditor.color) = color;
		(collectionEditor.projectUUID) = (project.UUID);
	}];
	
	[(self.store) addFreshlyCreatedCollectionWithUUID:(collection.UUID)];
	
	[self editCollectionsOfProject:project usingBlock:^(id<GLAArrayEditing> collectionListEditor) {
		[collectionListEditor addChildren:@[collection]];
	}];
	
	return collection;
}

- (GLACollection *)editCollection:(GLACollection *)collection inProject:(GLAProject *)project usingBlock:(void(^)(id<GLACollectionEditing>collectionEditor))editBlock
{
	__block GLACollection *changedCollection = nil;
	
	[self editCollectionsOfProject:project usingBlock:^(id<GLAArrayEditing> collectionListEditor) {
		changedCollection = [collectionListEditor replaceFirstChildWhoseKey:@"UUID" hasValue:(collection.UUID) usingChangeBlock:^GLACollection *(GLACollection *originalCollection) {
			return [originalCollection copyWithChangesFromEditing:editBlock];
		}];
	}];
	
	return changedCollection;
}

- (GLACollection *)renameCollection:(GLACollection *)collection inProject:(GLAProject *)project toString:(NSString *)name
{
	return [self editCollection:collection inProject:project usingBlock:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.name) = name;
	}];
}

- (GLACollection *)changeColorOfCollection:(GLACollection *)collection inProject:(GLAProject *)project toColor:(GLACollectionColor *)color
{
	return [self editCollection:collection inProject:project usingBlock:^(id<GLACollectionEditing> collectionEditor) {
		(collectionEditor.color) = color;
	}];
}

- (void)permanentlyDeleteCollection:(GLACollection *)collection fromProject:(GLAProject *)project
{
	[self editCollectionsOfProject:project usingBlock:^(id<GLAArrayEditing> collectionListEditor) {
		[collectionListEditor removeFirstChildWhoseKey:@"UUID" hasValue:(collection.UUID)];
	}];
}

#pragma mark Highlights

- (BOOL)hasLoadedHighlightsForProject:(GLAProject *)project
{
	NSAssert(project != nil, @"Project must not be nil.");
	return [(self.store) hasLoadedHighlightsForProject:project];
}

- (void)loadHighlightsForProjectIfNeeded:(GLAProject *)project
{
	[(self.store) loadHighlightsForProjectIfNeeded:project];
}

- (NSArray *)copyHighlightsForProject:(GLAProject *)project
{
	return [(self.store) copyHighlightsForProject:project];
}

- (NSArray *)filterCollectedFiles:(NSArray *)collectedFiles notInHighlightsOfProject:(GLAProject *)project
{
	GLAProjectManagerStore *store = (self.store);
	GLAArrayEditorStore *highlightsEditorStore = [store highlightsEditorStoreForProject:project];
	
	NSSet *collectedFileUUIDs = [NSSet setWithArray:[collectedFiles valueForKey:@"UUID"]];
	NSMutableSet *collectedFileUUIDsToRemove = [NSMutableSet new];
	NSArray *highlightedItems = [highlightsEditorStore copyChildren];
	
	for (GLAHighlightedItem *highlightedItem in highlightedItems) {
		if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
			GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
			NSUUID *collectedFileUUID = (highlightedCollectedFile.collectedFileUUID);
			if ([collectedFileUUIDs containsObject:collectedFileUUID]) {
				[collectedFileUUIDsToRemove addObject:collectedFileUUID];
			}
		}
	}
	
	NSMutableArray *filteredCollectedFiles = [NSMutableArray new];
	for (GLACollectedFile *collectedFile in collectedFiles) {
		BOOL filterOut = [collectedFileUUIDsToRemove containsObject:(collectedFile.UUID)];
		if (!filterOut) {
			[filteredCollectedFiles addObject:collectedFile];
		}
	}
	
	return filteredCollectedFiles;
}

- (BOOL)highlightsOfProject:(GLAProject *)project containsCollectedFile:(GLACollectedFile *)collectedFile
{
	GLAProjectManagerStore *store = (self.store);
	GLAArrayEditorStore *highlightsEditorStore = [store highlightsEditorStoreForProject:project];
	
	id<GLAArrayInspecting> highlightsArray = (highlightsEditorStore.inspectArray);
	NSIndexSet *indexes = [highlightsArray indexesOfChildrenWhoseResultFromVisitor:^ NSUUID *(GLAHighlightedItem *highlightedItem) {
		if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
			GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
			return (highlightedCollectedFile.collectedFileUUID);
		}
		
		return nil;
	} hasValueContainedInSet:[NSSet setWithObject:(collectedFile.UUID)]];
	
	return (indexes.count) > 0;
}

- (void)editHighlightsOfProject:(GLAProject *)project usingBlock:(void (^)(id<GLAArrayEditing>highlightsListEditor))block
{
	GLAProjectManagerStore *store = (self.store);
	GLAArrayEditorStore *highlightsEditorStore = [store highlightsEditorStoreForProject:project];
	
	BOOL madeChanges = [highlightsEditorStore editUsingBlock:block handleAddedChildren:nil handleRemovedChildren:nil handleReplacedChildren:nil];
	
	if (madeChanges) {
		[self highlightsListForProjectDidChange:project];
	}
}

- (GLAHighlightedCollectedFile *)editHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile usingBlock:(void(^)(id<GLAHighlightedCollectedFileEditing>editor))editBlock
{
	__block GLAHighlightedCollectedFile *changedHighlightedCollectedFile = nil;
	
	GLAProject *project = [self projectWithUUID:(highlightedCollectedFile.projectUUID)];
	NSParameterAssert(project != nil);
	
	[self editHighlightsOfProject:project usingBlock:^(id<GLAArrayEditing> highlightsListEditor) {
		changedHighlightedCollectedFile = [highlightsListEditor replaceFirstChildWhoseKey:@"UUID" hasValue:(highlightedCollectedFile.UUID) usingChangeBlock:^GLAHighlightedCollectedFile *(GLAHighlightedCollectedFile *originalHighlightedCollectedFile) {
			return [originalHighlightedCollectedFile copyWithChangesFromEditing:editBlock];
		}];
	}];
	
	return changedHighlightedCollectedFile;
}

- (void)removeHighlightedItemsWithCollectedFiles:(NSArray *)collectedFiles fromProject:(GLAProject *)project
{
	NSSet *removedCollectionFileUUIDs = [NSSet setWithArray:[collectedFiles valueForKey:@"UUID"]];
	[self editHighlightsOfProject:project usingBlock:^(id<GLAArrayEditing> highlightsEditor) {
		NSIndexSet *indexesOfRemovedFiles = [highlightsEditor indexesOfChildrenWhoseResultFromVisitor:^ NSUUID *(GLAHighlightedItem *highlightedItem) {
			if ([highlightedItem isKindOfClass:[GLAHighlightedCollectedFile class]]) {
				GLAHighlightedCollectedFile *highlightedCollectedFile = (GLAHighlightedCollectedFile *)highlightedItem;
				return (highlightedCollectedFile.collectedFileUUID);
			}
			
			return nil;
		} hasValueContainedInSet:removedCollectionFileUUIDs];
		[highlightsEditor removeChildrenAtIndexes:indexesOfRemovedFiles];
	}];
}

- (void)removeHighlightedItemsWithCollections:(NSArray *)collections fromProject:(GLAProject *)project
{
	NSSet *collectionUUIDs = [NSSet setWithArray:[collections valueForKey:@"UUID"]];
	[self editHighlightsOfProject:project usingBlock:^(id<GLAArrayEditing> highlightsEditor) {
		NSIndexSet *indexesOfRemovedFiles = [highlightsEditor indexesOfChildrenWhoseResultFromVisitor:^ NSUUID *(GLAHighlightedItem *highlightedItem) {
			if ([highlightedItem conformsToProtocol:@protocol(GLAHighlightedCollectedItem)]) {
				id<GLAHighlightedCollectedItem> highlightedCollectedItem = (id<GLAHighlightedCollectedItem>)highlightedItem;
				return (highlightedCollectedItem.holdingCollectionUUID);
			}
			
			return nil;
		} hasValueContainedInSet:collectionUUIDs];
		[highlightsEditor removeChildrenAtIndexes:indexesOfRemovedFiles];
	}];
}

#pragma mark Collection Files List

- (BOOL)hasLoadedFilesForCollection:(GLACollection *)filesListCollection
{
	NSAssert(filesListCollection != nil, @"Collection must not be nil.");
	return [(self.store) hasLoadedFilesForCollection:filesListCollection];
}

- (void)loadFilesListForCollectionIfNeeded:(GLACollection *)filesListCollection
{
	NSAssert(filesListCollection != nil, @"Collection must not be nil.");
	[(self.store) loadFilesListForCollectionIfNeeded:filesListCollection];
}

- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection
{
	NSAssert(filesListCollection != nil, @"Collection must not be nil.");
	return [(self.store) copyFilesListForCollection:filesListCollection];
}

- (GLACollectedFile *)collectedFileWithUUID:(NSUUID *)collectedFileUUID insideCollection:(GLACollection *)filesListCollection
{
	NSAssert(collectedFileUUID != nil, @"Collected file UUID must not be nil.");
	NSAssert(filesListCollection != nil, @"Collection must not be nil.");
	return [(self.store) collectedFileWithUUID:collectedFileUUID insideCollection:filesListCollection];
}

- (BOOL)editFilesListOfCollection:(GLACollection *)filesListCollection usingBlock:(void (^)(id<GLAArrayEditing> filesListEditor))block
{
	GLAProjectManagerStore *store = (self.store);
	GLAArrayEditorStore *filesListEditorStore = [store filesListEditorStoreForCollection:filesListCollection];
	
	[filesListEditorStore
	 editUsingBlock:block
	 handleAddedChildren:nil
	 handleRemovedChildren:^(NSArray *removedChildren) {
		GLAProject *project = [self projectWithUUID:(filesListCollection.projectUUID)];
		[self removeHighlightedItemsWithCollectedFiles:removedChildren fromProject:project];
	}
	 handleReplacedChildren:nil
	 ];
	
	[self filesListForCollectionDidChange:filesListCollection didLoad:NO];
	
	return YES;
}

- (void)editFilesListOfCollection:(GLACollection *)filesListCollection insertingCollectedFiles:(NSArray *)collectedFiles atIndex:(NSUInteger)index
{
	[self editFilesListOfCollection:filesListCollection usingBlock:^(id<GLAArrayEditing> filesListEditor) {
		NSArray *filteredItems = [filesListEditor filterArray:collectedFiles whoseResultFromVisitorIsNotAlreadyPresent:^id(GLACollectedFile *child) {
			return (child.filePathURL.path);
		}];
		
		if (index == NSNotFound) {
			[filesListEditor addChildren:filteredItems];
		}
		else {
			NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, (filteredItems.count))];
			[filesListEditor insertChildren:filteredItems atIndexes:indexes];
		}
	}];
}

- (void)editFilesListOfCollection:(GLACollection *)filesListCollection addingCollectedFiles:(NSArray *)collectedFiles queueIfNeedsLoading:(BOOL)queue
{
	BOOL hasLoaded = [self hasLoadedFilesForCollection:filesListCollection];
	if (hasLoaded) {
		[self editFilesListOfCollection:filesListCollection insertingCollectedFiles:collectedFiles atIndex:NSNotFound];
	}
	else {
		NSMutableDictionary *collectionUUIDsToPendingAddedCollectedFiles = (self.collectionUUIDsToPendingAddedCollectedFiles);
		
		if (!collectionUUIDsToPendingAddedCollectedFiles) {
			(self.collectionUUIDsToPendingAddedCollectedFiles) = collectionUUIDsToPendingAddedCollectedFiles = [NSMutableDictionary new];
		}
		
		NSUUID *collectionUUID = (filesListCollection.UUID);
		
		NSMutableArray *pendingAddedCollectedFiles = collectionUUIDsToPendingAddedCollectedFiles[collectionUUID];
		if (!pendingAddedCollectedFiles) {
			collectionUUIDsToPendingAddedCollectedFiles[collectionUUID] = [NSMutableArray arrayWithArray:collectedFiles];
		}
		else {
			[pendingAddedCollectedFiles addObjectsFromArray:collectedFiles];
		}
	}
}

#pragma mark Highlighted Collected File

- (GLACollection *)collectionForHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile loadIfNeeded:(BOOL)load
{
	NSUUID *projectUUID = (highlightedCollectedFile.projectUUID);
	GLAProject *project = [self projectWithUUID:projectUUID];
	if (!project) {
		return nil;
	}
	GLAModelArrayEditorStore *collectionsEditorStore = [(self.store) collectionsEditorStoreForProject:project];
	
	NSUUID *collectionUUID = (highlightedCollectedFile.holdingCollectionUUID);
	GLACollection *collection = (GLACollection *)[collectionsEditorStore modelWithUUID:collectionUUID];
	
	if (collection) {
		return collection;
	}
	
	if (load) {
		[self loadCollectionsForProjectIfNeeded:project];
	}
	
	return nil;
}

- (GLACollectedFile *)collectedFileForHighlightedCollectedFile:(GLAHighlightedCollectedFile *)highlightedCollectedFile loadIfNeeded:(BOOL)load
{
	GLACollection *holdingCollection = [self collectionForHighlightedCollectedFile:highlightedCollectedFile loadIfNeeded:load];
	
	if (holdingCollection) {
		if ([self hasLoadedFilesForCollection:holdingCollection]) {
			NSUUID *collectedFileUUID = (highlightedCollectedFile.collectedFileUUID);
			GLACollectedFile *collectedFile = [self collectedFileWithUUID:collectedFileUUID insideCollection:holdingCollection];
			
			return collectedFile;
		}
		
		if (load) {
			[self loadFilesListForCollectionIfNeeded:holdingCollection];
		}
	}
	
	return nil;
}

#pragma mark Validating

- (NSString *)normalizeName:(NSString *)name
{
	if (!name) {
		return @"";
	}
	
	NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	return [name stringByTrimmingCharactersInSet:whitespaceCharacterSet];
}

- (BOOL)nameIsValid:(NSString *)name
{
	NSString *normalizedName = [self normalizeName:name];
	if ([normalizedName isEqualToString:@""]) {
		return NO;
	}
	
	return YES;
}

#pragma mark Saving

- (void)requestSaveAllProjects
{
	[(self.store) requestSaveAllProjects];
}

- (void)requestSaveCollectionsForProject:(GLAProject *)project
{
	[(self.store) requestSaveCollectionsForProject:project];
}

- (void)requestSaveFilesListForCollections:(GLACollection *)filesListCollection
{
	[(self.store) requestSaveFilesListForCollection:filesListCollection];
}


#pragma mark Notifications

- (id)notificationObjectForProject:(GLAProject *)project
{
	return [self notificationObjectForProjectUUID:(project.UUID)];
}

- (id)notificationObjectForProjectUUID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Passed project UUID must not be nil.");
	
	NSMutableDictionary *notificationRepresenters = (self.projectUUIDNotificationRepresenters);
	if (!notificationRepresenters) {
		notificationRepresenters = (self.projectUUIDNotificationRepresenters) = [NSMutableDictionary new];
	}
	
	GLAObjectNotificationRepresenter *representer = notificationRepresenters[projectUUID];
	
	if (!representer) {
		representer = notificationRepresenters[projectUUID] = [[GLAObjectNotificationRepresenter alloc] initWithUUID:projectUUID];
	}
	
	return representer;
}

- (id)notificationObjectForCollection:(GLACollection *)collection
{
	return [self notificationObjectForCollectionUUID:(collection.UUID)];
}

- (id)notificationObjectForCollectionUUID:(NSUUID *)collectionUUID
{
	NSAssert(collectionUUID != nil, @"Passed collection UUID must not be nil.");
	
	NSMutableDictionary *notificationRepresenters = (self.collectionUUIDNotificationRepresenters);
	if (!notificationRepresenters) {
		notificationRepresenters = (self.collectionUUIDNotificationRepresenters) = [NSMutableDictionary new];
	}
	
	GLAObjectNotificationRepresenter *representer = notificationRepresenters[collectionUUID];
	
	if (!representer) {
		representer = notificationRepresenters[collectionUUID] = [[GLAObjectNotificationRepresenter alloc] initWithUUID:collectionUUID];
	}
	
	return representer;
}

- (void)allProjectsDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerAllProjectsDidChangeNotification object:self];
}

- (void)plannedProjectsDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerPlannedProjectsDidChangeNotification object:self];
}

- (void)nowProjectDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectManagerNowProjectDidChangeNotification object:self];
}

- (void)projectDidChange:(GLAProject *)project
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectDidChangeNotification object:[self notificationObjectForProject:project]];
}

- (void)projectsDidChange:(NSArray *)projects
{
	for (GLAProject *project in projects) {
		[self projectDidChange:project];
	}
}

- (void)projectWasDeleted:(GLAProject *)project
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectWasDeletedNotification object:[self notificationObjectForProject:project]];
}

- (void)collectionListForProjectDidChange:(GLAProject *)project
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectCollectionsDidChangeNotification object:[self notificationObjectForProject:project]];
}

- (void)highlightsListForProjectDidChange:(GLAProject *)project
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAProjectHighlightsDidChangeNotification object:[self notificationObjectForProject:project]];
}

- (void)collectionDidChange:(GLACollection *)collection
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionDidChangeNotification object:[self notificationObjectForCollection:collection]];
}

- (void)collectionsDidChange:(NSArray *)collections
{
	for (GLACollection *collection in collections) {
		[self collectionDidChange:collection];
	}
}

- (void)filesListForCollectionDidChange:(GLACollection *)collection didLoad:(BOOL)didLoad
{
	if (didLoad) {
		NSUUID *collectionUUID = (collection.UUID);
		NSMutableDictionary *collectionUUIDsToPendingAddedCollectedFiles = (self.collectionUUIDsToPendingAddedCollectedFiles);
		if (collectionUUIDsToPendingAddedCollectedFiles) {
			NSArray *pendingAddedCollectedFiles = collectionUUIDsToPendingAddedCollectedFiles[collectionUUID];
			
			if (pendingAddedCollectedFiles) {
				[self editFilesListOfCollection:collection insertingCollectedFiles:pendingAddedCollectedFiles atIndex:NSNotFound];
				[collectionUUIDsToPendingAddedCollectedFiles removeObjectForKey:collectionUUID];
			}
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GLACollectionFilesListDidChangeNotification object:[self notificationObjectForCollection:collection]];
}

#pragma mark Status

- (NSString *)statusOfCurrentActivity
{
	return [(self.store) statusOfCurrentActivity];
}

- (NSString *)statusOfCompletedActivity
{
	return [(self.store) statusOfCompletedActivity];
}

#pragma mark Dummy

+ (GLAProject *)newDummyProjectWithName:(NSString *)name
{
	GLAProject *project = [[GLAProject alloc] initWithName:name dateCreated:[NSDate date]];
	
	return project;
}

+ (NSArray *)allProjectsDummyContent
{
	static NSArray *dummyAllProjects;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dummyAllProjects =
  @[
	[GLAProjectManager newDummyProjectWithName:@"Project With Big Long Name That Goes On"],
	[GLAProjectManager newDummyProjectWithName:@"Eat a thousand muffins in one day"],
	[GLAProjectManager newDummyProjectWithName:@"Another, yet another project"],
	[GLAProjectManager newDummyProjectWithName:@"The one that just won’t die"],
	[GLAProjectManager newDummyProjectWithName:@"Could this be my favourite project ever?"],
	[GLAProjectManager newDummyProjectWithName:@"Freelance project #82"]
	];
	});
	
	return dummyAllProjects;
	
	
}

+ (GLAProject *)nowProjectDummyContent
{
	NSArray *allProjects = [GLAProjectManager allProjectsDummyContent];
	return allProjects[0];
}

+ (NSArray *)collectionListDummyContent
{
	return
	@[
	  [GLACollection dummyCollectionWithName:@"Working Files" color:[GLACollectionColor pastelLightBlue] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Briefs" color:[GLACollectionColor pastelGreen] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Contacts" color:[GLACollectionColor pastelPinkyPurple] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Apps" color:[GLACollectionColor pastelRed] type:GLACollectionTypeFilesList],
	  [GLACollection dummyCollectionWithName:@"Research" color:[GLACollectionColor pastelYellow] type:GLACollectionTypeFilesList]
	  ];
}

@end


#pragma mark -

@interface GLAProjectManagerStore () <GLAArrayEditorStoreDelegate, GLAArrayMantleJSONStoreErrorHandler>

//@property(readwrite, nonatomic) NSArray *plannedProjectsSortedByDateNextPlanned;

@property(readonly, nonatomic) NSOperationQueue *foregroundOperationQueue;
@property(nonatomic) NSOperationQueue *backgroundOperationQueue;

@property(readwrite, copy, nonatomic) NSUUID *nowProjectUUID;

@property(nonatomic) NSMutableDictionary *projectIDsToCollectionEditorStores;
@property(nonatomic) NSMutableSet *freshlyCreatedCollectionUUIDs;

@property(nonatomic) NSMutableDictionary *projectIDsToHighlightsEditorStores;

@property(nonatomic) NSMutableDictionary *collectionIDsToFilesListEditorStores;

@property(readonly, nonatomic) NSURL *allProjectsJSONFileURL;
@property(readonly, nonatomic) NSURL *nowProjectJSONFileURL;

@property(nonatomic) BOOL needsToLoadAllProjects;

@property(nonatomic) BOOL needsToSaveAllProjects;

//@property(nonatomic) BOOL needsToLoadPlannedProjects;
//- (void)loadPlannedProjects;
//@property(nonatomic) BOOL needsToSavePlannedProjects;
//- (void)writePlannedProjects;

@property(nonatomic) BOOL needsToLoadNowProject;
- (void)loadNowProject:(dispatch_block_t)completionBlock;

@property(nonatomic) BOOL needsToSaveNowProject;
- (void)writeNowProject:(dispatch_block_t)completionBlock;

#pragma Status

@property(nonatomic) NSMutableSet *actionsThatAreRunning;
@property(nonatomic) NSMutableDictionary *actionsToBeginTime;
@property(nonatomic) NSMutableDictionary *actionsToEndTime;

- (dispatch_block_t)beginActionWithIdentifier:(NSString *)actionIdentifierFormat, ... NS_FORMAT_FUNCTION(1,2);

- (NSTimeInterval)durationOfLastRunOfActionWithIdentifier:(NSString *)actionIdentifier;

@end


@implementation GLAProjectManagerStore

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager;
{
    self = [super init];
    if (self) {
		(self.projectManager) = projectManager;
		
		_backgroundOperationQueue = [NSOperationQueue new];
		(_backgroundOperationQueue.name) = @"com.burntcaramel.GLAProjectManager.background";
		(_backgroundOperationQueue.maxConcurrentOperationCount) = 1;
		
#if 0
		NSError *testError = [GLAModelErrors errorForMissingRequiredKey:GLAProjectManagerJSONAllProjectsKey inJSONFileAtURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
		[projectManager handleError:testError];
#endif
    }
    return self;
}

#pragma mark Queuing Work

- (NSOperationQueue *)foregroundOperationQueue
{
	GLAProjectManager *projectManager = (self.projectManager);
	if (projectManager) {
		return (projectManager.receivingOperationQueue);
	}
	else {
		return nil;
	}
}

- (void)runInBackground:(void (^)(GLAProjectManagerStore *store))block
{
	__weak GLAProjectManagerStore *weakStore = self;
	
	[(self.backgroundOperationQueue) addOperationWithBlock:^{
		GLAProjectManagerStore *store = weakStore;
		
		block(store);
	}];
}

- (void)runInForeground:(void (^)(GLAProjectManagerStore *store, GLAProjectManager *projectManager))block
{
	__weak GLAProjectManagerStore *weakStore = self;
	
	[(self.foregroundOperationQueue) addOperationWithBlock:^{
		GLAProjectManagerStore *store = weakStore;
		GLAProjectManager *projectManager = (store.projectManager);
		
		block(store, projectManager);
	}];
}

- (BOOL)shouldLoadTestProjects
{
	GLAProjectManager *pm = (self.projectManager);
	if (pm) {
		return (pm.shouldLoadTestProjects);
	}
	else {
		return NO;
	}
}

- (void)handleError:(NSError *)error fromSelector:(SEL)selector
{
	GLAProjectManager *pm = (self.projectManager);
	[pm handleError:error fromSelector:selector];
}

#pragma mark Files

- (NSURL *)version1DirectoryURLWithInnerDirectoryComponents:(NSArray *)extraPathComponents
{
	GLAProjectManager *projectManager = (self.projectManager);
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	NSURL *directoryURL = [fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	
	if (!directoryURL) {
		[projectManager handleError:error fromSelector:_cmd];
		return nil;
	}
	
	// Convert path to its components, so we can add more components
	// and convert back into a URL.
	NSMutableArray *pathComponents = [(directoryURL.pathComponents) mutableCopy];
	
	// {appBundleID}/v1/
	NSString *appBundleID = ([NSBundle mainBundle].bundleIdentifier);
	[pathComponents addObject:appBundleID];
	[pathComponents addObject:@"v1"];
	
	// Append extra path components passed to this method.
	if (extraPathComponents) {
		[pathComponents addObjectsFromArray:extraPathComponents];
	}
	
	// Convert components back into a URL.
	directoryURL = [NSURL fileURLWithPathComponents:pathComponents];
	
	BOOL directorySuccess = [fm createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
	if (!directorySuccess) {
		[projectManager handleError:error fromSelector:_cmd];
		return nil;
	}
	
	return directoryURL;
}

- (NSURL *)version1DirectoryURL
{
	return [self version1DirectoryURLWithInnerDirectoryComponents:nil];
}

- (NSURL *)allProjectsJSONFileURL
{
	NSURL *directoryURL = (self.version1DirectoryURL);
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"all-projects.json"];
	
	return fileURL;
}

- (NSURL *)nowProjectJSONFileURL
{
	NSURL *directoryURL = (self.version1DirectoryURL);
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"now-project.json"];
	
	return fileURL;
}

- (NSURL *)projectDirectoryURLForProjectID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Project UUID must not be nil.");
	
	NSString *projectDirectoryName = [NSString stringWithFormat:@"project-%@", (projectUUID.UUIDString)];
	NSURL *directoryURL = [self version1DirectoryURLWithInnerDirectoryComponents:@[projectDirectoryName]];
	
	return directoryURL;
}

- (NSURL *)collectionsListJSONFileURLForProjectID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Project UUID must not be nil.");
	
	NSURL *directoryURL = [self projectDirectoryURLForProjectID:projectUUID];
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"collections-list.json"];
	
	return fileURL;
}

- (NSURL *)highlightsListJSONFileURLForProjectID:(NSUUID *)projectUUID
{
	NSAssert(projectUUID != nil, @"Project UUID must not be nil.");
	
	NSURL *directoryURL = [self projectDirectoryURLForProjectID:projectUUID];
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"highlights-list.json"];
	
	return fileURL;
}

- (NSURL *)collectionDirectoryURLForCollectionID:(NSUUID *)collectionUUID
{
	NSAssert(collectionUUID != nil, @"Collection UUID must not be nil.");
	
	NSString *collectionDirectoryName = [NSString stringWithFormat:@"collection-%@", (collectionUUID.UUIDString)];
	NSURL *directoryURL = [self version1DirectoryURLWithInnerDirectoryComponents:@[collectionDirectoryName]];
	
	return directoryURL;
}

- (NSURL *)filesListJSONFileURLForCollectionID:(NSUUID *)collectionUUID
{
	NSAssert(collectionUUID != nil, @"Collection UUID must not be nil.");
	
	NSURL *directoryURL = [self collectionDirectoryURLForCollectionID:collectionUUID];
	NSURL *fileURL = [directoryURL URLByAppendingPathComponent:@"files-list.json"];
	
	return fileURL;
}

#pragma mark -

- (NSDictionary *)background_readJSONDictionaryFromFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:(fileURL.path)]) {
		return nil;
	}
	
	NSData *JSONData = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
	if (!JSONData) {
		[projectManager handleError:error fromSelector:_cmd];
		return nil;
	}
	
	NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
	if (!JSONDictionary) {
		[projectManager handleError:error fromSelector:_cmd];
		return nil;
	}
	
	return JSONDictionary;
}

- (NSArray *)background_readModelsOfClass:(Class)modelClass atDictionaryKey:(NSString *)JSONKey fromJSONFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSDictionary *JSONDictionary = [self background_readJSONDictionaryFromFileURL:fileURL];
	if (!JSONDictionary) {
		return nil;
	}
	
	NSArray *JSONArray = JSONDictionary[JSONKey];
	if (!JSONArray) {
		error = [GLAModelErrors errorForMissingRequiredKey:JSONKey inJSONFileAtURL:fileURL];
		[projectManager handleError:error fromSelector:_cmd];
		return nil;
	}
	
	NSArray *models = [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONArray error:&error];
	if (!models) {
		[projectManager handleError:error fromSelector:_cmd];
		return nil;
	}
	
	return models;
}

- (BOOL)writeJSONDictionary:(NSDictionary *)JSONDictionary toFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:&error];
	if (!JSONData) {
		[projectManager handleError:error fromSelector:_cmd];
		return NO;
	}
	
	[JSONData writeToURL:fileURL atomically:YES];
	
	return YES;
}

#pragma mark All Projects

#if 1

// GLAArrayMantleJSONStore

@synthesize allProjectsEditor = _allProjectsEditor;

- (GLAArrayEditor *)allProjectsEditorCreateIfNeeded:(BOOL)create
{
	GLAArrayEditor *allProjectsEditor = _allProjectsEditor;
	if (allProjectsEditor) {
		return allProjectsEditor;
	}
	else if (!create) {
		return nil;
	}
	
	NSURL *JSONFileURL = (self.allProjectsJSONFileURL);
	
	GLAArrayEditorOptions *arrayEditorOptions = [GLAArrayEditorOptions new];
	(arrayEditorOptions.store) = [[GLAArrayMantleJSONStore alloc] initWithModelClass:[GLAProject class] JSONFileURL:JSONFileURL JSONDictionaryKey:GLAProjectManagerJSONAllProjectsKey freshlyMade:NO operationQueue:(self.backgroundOperationQueue) errorHandler:self];
	//[arrayEditorOptions addIndexer:[GLAModelUUIDMap new]];
	[arrayEditorOptions setPrimaryIndexer:[GLAModelUUIDMap new]];
	
	allProjectsEditor = [[GLAArrayEditor alloc] initWithObjects:@[] options:arrayEditorOptions];
	
	_allProjectsEditor = allProjectsEditor;
	
	return allProjectsEditor;
}

- (GLAArrayEditor *)allProjectsEditor
{
	return [self allProjectsEditorCreateIfNeeded:YES];
}

- (BOOL)hasLoadedAllProjects
{
	GLAArrayEditor *allProjectsEditor = [self allProjectsEditorCreateIfNeeded:NO];
	if (!allProjectsEditor) {
		return NO;
	}
	
	id<GLAArrayStoring> store = (allProjectsEditor.store);
	return (store.loadState) == GLAArrayStoringLoadStateFinishedLoading;
}

- (void)loadAllProjectsIfNeeded
{
	GLAArrayEditor *allProjectsEditor = [self allProjectsEditorCreateIfNeeded:YES];
	
	id<GLAArrayStoring> editorStore = (allProjectsEditor.store);
	NSAssert(editorStore != nil, @"All projects array editor must have a store");
	
	__weak GLAProjectManagerStore *weakSelf = self;
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load All Projects"];
	[editorStore loadIfNeededWithChildProcessor:nil completionBlock:^(NSArray *loadedItems) {
		__strong GLAProjectManagerStore *self = weakSelf;
		[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[(self.projectManager) allProjectsDidChange];
			
			[self matchNowProjectFromAllProjectsUsingUUID];
			
			actionTracker();
		}];
	}];
}

- (NSArray *)copyAllProjects
{
	GLAArrayEditor *allProjectsEditor = [self allProjectsEditorCreateIfNeeded:NO];
	if (allProjectsEditor) {
		return [allProjectsEditor copyChildren];
	}
	else {
		return nil;
	}
}

- (void)requestSaveAllProjects
{
	GLAArrayEditor *allProjectsEditor = [self allProjectsEditorCreateIfNeeded:NO];
	if (!allProjectsEditor) {
		return;
	}
	
	[(allProjectsEditor.store) saveIfNeededWithCompletionBlock:nil];
}

- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID
{
	GLAArrayEditor *allProjectsEditor = (self.allProjectsEditor);
#if 1
	GLAProject *project = allProjectsEditor[projectUUID];
	return project;
#else
	GLAProject *project = [allProjectsEditor firstChildWhoseKey:@"UUID" hasValue:projectUUID];
	return project;
#endif
}

#else

@synthesize allProjectsEditorStore = _allProjectsEditorStore;

- (GLAModelArrayEditorStore *)allProjectsEditorStoreCreateIfNeeded:(BOOL)create
{
	GLAModelArrayEditorStore *allProjectsEditorStore = _allProjectsEditorStore;
	if (allProjectsEditorStore) {
		return allProjectsEditorStore;
	}
	else if (!create) {
		return nil;
	}
	
	NSURL *JSONFileURL = (self.allProjectsJSONFileURL);
	
	allProjectsEditorStore = [[GLAModelArrayEditorStore alloc] initWithDelegate:self modelClass:[GLAProject class] JSONFileURL:JSONFileURL JSONDictionaryKey:GLAProjectManagerJSONAllProjectsKey arrayEditorOptions:nil freshlyMade:NO];
	(allProjectsEditorStore.userInfo) =
	@{
	  @"allProjects": @(YES)
	  };
	
	_allProjectsEditorStore = allProjectsEditorStore;
	
	return allProjectsEditorStore;
}

- (GLAModelArrayEditorStore *)allProjectsEditorStore
{
	return [self allProjectsEditorStoreCreateIfNeeded:YES];
}

- (BOOL)hasLoadedAllProjects
{
	GLAArrayEditorStore *allProjectsEditorStore = [self allProjectsEditorStoreCreateIfNeeded:NO];
	if (!allProjectsEditorStore) {
		return NO;
	}
	
	return (allProjectsEditorStore.finishedLoading);
}

- (void)loadAllProjectsIfNeeded
{
	GLAArrayEditorStore *allProjectsEditorStore = [self allProjectsEditorStoreCreateIfNeeded:YES];
	
	if (!(allProjectsEditorStore.needsLoading)) {
		return;
	}
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load All Projects"];
	[allProjectsEditorStore loadWithCompletionBlock:^{
		[(self.projectManager) allProjectsDidChange];
		
		[self matchNowProjectFromAllProjectsUsingUUID];
		
		actionTracker();
	}];
}

- (NSArray *)copyAllProjects
{
	GLAArrayEditorStore *allProjectsEditorStore = [self allProjectsEditorStoreCreateIfNeeded:NO];
	if (allProjectsEditorStore) {
		return [allProjectsEditorStore copyChildren];
	}
	else {
		return nil;
	}
}

- (void)requestSaveAllProjects
{
	GLAArrayEditorStore *allProjectsEditorStore = [self allProjectsEditorStoreCreateIfNeeded:NO];
	if (!allProjectsEditorStore) {
		return;
	}
	
	[allProjectsEditorStore saveWithCompletionBlock:nil];
}

- (GLAProject *)projectWithUUID:(NSUUID *)projectUUID
{
	GLAModelArrayEditorStore *allProjectsEditorStore = [self allProjectsEditorStoreCreateIfNeeded:YES];
	return (GLAProject *)[allProjectsEditorStore modelWithUUID:projectUUID];
}

#endif

- (void)permanentlyDeleteAssociatedFilesForProjects:(NSArray *)projects
{
	for (GLAProject *project in projects) {
		NSArray *collections = [self copyCollectionsForProject:project];
		[self permanentlyDeleteAssociatedFilesForCollections:collections];
		[self clearCollectionsEditorStoreForProject:project];
	}
	
	[self runInBackground:^(GLAProjectManagerStore *store) {
		NSFileManager *fm = [NSFileManager defaultManager];
		
		for (GLAProject *project in projects) {
			NSURL *directoryURL = [self projectDirectoryURLForProjectID:(project.UUID)];
			
			NSError *error = nil;
			
			BOOL success = [fm removeItemAtURL:directoryURL error:&error];
			if (!success) {
				[store handleError:error fromSelector:_cmd];
			}
		}
	}];
}

#pragma mark Now Project

- (void)matchNowProjectFromAllProjectsUsingUUID
{
	NSUUID *nowProjectUUID = (self.nowProjectUUID);
	if (!nowProjectUUID) {
		return;
	}
	
	[self loadAllProjectsIfNeeded];

	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[projectManager nowProjectDidChange];
	}];
}

- (void)loadNowProjectIfNeeded
{
	// Only load once.
	if (self.needsToLoadNowProject) {
		return;
	}
	// If currently saving, don't load anything from disk.
	if (self.needsToSaveNowProject) {
		return;
	}
	
	if (self.nowProjectUUID) {
		return;
	}
	
	(self.needsToLoadNowProject) = YES;
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Now Project"];
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		[store loadNowProject:actionTracker];
	}];
}

- (void)loadNowProject:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = (self.nowProjectJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	BOOL loadTestContent = (self.shouldLoadTestProjects);
	[self runInBackground:^(GLAProjectManagerStore *store) {
		GLAProject *project = nil;
		
		if (loadTestContent) {
			project = [GLAProjectManager nowProjectDummyContent];
		}
		else {
			project = [store background_readNowProjectFromJSONFileURL:fileURL];
		}
		
		[store background_processLoadedNowProject:project];
		
		completionBlock();
	}];
}

- (GLAProject *)background_readNowProjectFromJSONFileURL:(NSURL *)fileURL
{
	GLAProjectManager *projectManager = (self.projectManager);
	NSError *error = nil;
	
	NSDictionary *JSONDictionary = [self background_readJSONDictionaryFromFileURL:fileURL];
	if (!JSONDictionary) {
		return nil;
	}
	
	NSDictionary *JSONProject = JSONDictionary[GLAProjectManagerJSONNowProjectKey];
	if (!JSONProject) {
		error = [GLAModelErrors errorForMissingRequiredKey:GLAProjectManagerJSONNowProjectKey inJSONFileAtURL:fileURL];
		[projectManager handleError:error fromSelector:_cmd];
		return nil;
	}
	
	GLAProject *project = [MTLJSONAdapter modelOfClass:[GLAProject class] fromJSONDictionary:JSONProject error:&error];
	if (!project) {
		[projectManager handleError:error fromSelector:_cmd];
		return nil;
	}
	
	return project;
}

- (void)background_processLoadedNowProject:(GLAProject *)project
{
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		(store.nowProjectUUID) = (project.UUID);
		
		[store matchNowProjectFromAllProjectsUsingUUID];
		
		(store.needsToLoadNowProject) = NO;
	}];
}

- (GLAProject *)nowProject
{
	NSUUID *nowProjectUUID = (self.nowProjectUUID);
	if (nowProjectUUID) {
		return [self projectWithUUID:nowProjectUUID];
	}
	else {
		return nil;
	}
}

- (void)changeNowProject:(GLAProject *)project
{
	(self.nowProjectUUID) = (project.UUID);
}

#pragma mark Collections

- (GLAModelArrayEditorStore *)collectionsEditorStoreForProject:(GLAProject *)project createIfNeeded:(BOOL)create
{
	NSMutableDictionary *projectIDsToCollectionEditorStores = (self.projectIDsToCollectionEditorStores);
	if (projectIDsToCollectionEditorStores == nil) {
		projectIDsToCollectionEditorStores = (self.projectIDsToCollectionEditorStores) = [NSMutableDictionary new];
	}
	
	NSUUID *projectUUID = (project.UUID);
	GLAModelArrayEditorStore *collectionsEditorStore = projectIDsToCollectionEditorStores[projectUUID];
	if (collectionsEditorStore) {
		return collectionsEditorStore;
	}
	else if (!create) {
		return nil;
	}
	
	NSURL *JSONFileURL = [self collectionsListJSONFileURLForProjectID:projectUUID];
	
	//TODO: add freshly made for projects.
	
	collectionsEditorStore = [[GLAModelArrayEditorStore alloc] initWithDelegate:self modelClass:[GLACollection class] JSONFileURL:JSONFileURL JSONDictionaryKey:GLAProjectManagerJSONCollectionsListKey arrayEditorOptions:nil freshlyMade:NO];
	(collectionsEditorStore.userInfo) =
	@{
	  @"projectUUID": projectUUID
	  };
	
	projectIDsToCollectionEditorStores[projectUUID] = collectionsEditorStore;
	
	return collectionsEditorStore;
}

- (void)clearCollectionsEditorStoreForProject:(GLAProject *)project
{
	NSMutableDictionary *projectIDsToCollectionEditorStores = (self.projectIDsToCollectionEditorStores);
	if (!projectIDsToCollectionEditorStores) {
		return;
	}
	
	NSUUID *projectUUID = (project.UUID);
	[projectIDsToCollectionEditorStores removeObjectForKey:projectUUID];
}

- (GLAModelArrayEditorStore *)collectionsEditorStoreForProject:(GLAProject *)project
{
	return [self collectionsEditorStoreForProject:project createIfNeeded:YES];
}

- (BOOL)hasLoadedCollectionsForProject:(GLAProject *)project
{
	GLAModelArrayEditorStore *collectionsEditorStore = [self collectionsEditorStoreForProject:project createIfNeeded:NO];
	if (!collectionsEditorStore) {
		return NO;
	}
	
	return (collectionsEditorStore.finishedLoading);
}

- (void)loadCollectionsForProjectIfNeeded:(GLAProject *)project
{
	GLAModelArrayEditorStore *collectionsEditorStore = [self collectionsEditorStoreForProject:project];
	
	if ( ! collectionsEditorStore.needsLoading ) {
		return;
	}
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Collections for Project \"%@\"", (project.name)];
	[collectionsEditorStore loadWithCompletionBlock:^{
		[(self.projectManager) collectionListForProjectDidChange:project];
		
		actionTracker();
	}];
}

- (NSArray *)copyCollectionsForProject:(GLAProject *)project
{
	GLAModelArrayEditorStore *collectionsEditorStore = [self collectionsEditorStoreForProject:project];
	if (collectionsEditorStore) {
		return [collectionsEditorStore copyChildren];
	}
	else {
		return nil;
	}
}

- (void)permanentlyDeleteAssociatedFilesForCollections:(NSArray *)collections
{
	[self runInBackground:^(GLAProjectManagerStore *store) {
		NSFileManager *fm = [NSFileManager defaultManager];
		
		for (GLACollection *collection in collections) {
			NSURL *directoryURL = [self collectionDirectoryURLForCollectionID:(collection.UUID)];
			
			NSError *error = nil;
			
			BOOL success = [fm removeItemAtURL:directoryURL error:&error];
			if (!success) {
				[store handleError:error fromSelector:_cmd];
			}
		}
	}];
}

- (BOOL)collectionWithUUIDIsFreshlyCreated:(NSUUID *)collectionUUID
{
	NSMutableSet *freshlyCreatedCollectionUUIDs = (self.freshlyCreatedCollectionUUIDs);
	if (!freshlyCreatedCollectionUUIDs) {
		return NO;
	}
	
	return [freshlyCreatedCollectionUUIDs containsObject:(collectionUUID)];
}

- (void)addFreshlyCreatedCollectionWithUUID:(NSUUID *)collectionUUID
{
	NSMutableSet *freshlyCreatedCollectionUUIDs = (self.freshlyCreatedCollectionUUIDs);
	if (!freshlyCreatedCollectionUUIDs) {
		(self.freshlyCreatedCollectionUUIDs) = freshlyCreatedCollectionUUIDs = [NSMutableSet new];
	}
	
	[freshlyCreatedCollectionUUIDs addObject:collectionUUID];
}

#pragma mark Highlights

- (GLAArrayEditorStore *)highlightsEditorStoreForProject:(GLAProject *)project createIfNeeded:(BOOL)create
{
	NSMutableDictionary *projectIDsToHighlightsEditorStores = (self.projectIDsToHighlightsEditorStores);
	if (projectIDsToHighlightsEditorStores == nil) {
		projectIDsToHighlightsEditorStores = (self.projectIDsToHighlightsEditorStores) = [NSMutableDictionary new];
	}
	
	NSUUID *projectUUID = (project.UUID);
	GLAArrayEditorStore *highlightsEditorStore = projectIDsToHighlightsEditorStores[projectUUID];
	if (highlightsEditorStore) {
		return highlightsEditorStore;
	}
	else if (!create) {
		return nil;
	}
	
	NSURL *JSONFileURL = [self highlightsListJSONFileURLForProjectID:projectUUID];
	
	highlightsEditorStore = [[GLAArrayEditorStore alloc] initWithDelegate:self modelClass:[GLAHighlightedItem class] JSONFileURL:JSONFileURL JSONDictionaryKey:GLAProjectManagerJSONHighlightsListKey arrayEditorOptions:nil freshlyMade:NO];
	(highlightsEditorStore.userInfo) =
	@{
	  @"projectUUID": projectUUID
	  };
	
	projectIDsToHighlightsEditorStores[projectUUID] = highlightsEditorStore;
	
	return highlightsEditorStore;
}

- (GLAArrayEditorStore *)highlightsEditorStoreForProject:(GLAProject *)project
{
	return [self highlightsEditorStoreForProject:project createIfNeeded:YES];
}

- (BOOL)hasLoadedHighlightsForProject:(GLAProject *)project
{
	GLAArrayEditorStore *highlightsEditorStore = [self highlightsEditorStoreForProject:project createIfNeeded:NO];
	if (!highlightsEditorStore) {
		return NO;
	}
	
	return (highlightsEditorStore.finishedLoading);
}

- (void)loadHighlightsForProjectIfNeeded:(GLAProject *)project
{
	GLAArrayEditorStore *highlightsEditorStore = [self highlightsEditorStoreForProject:project];
	
	if ( ! highlightsEditorStore.needsLoading ) {
		return;
	}
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Highlights for Project \"%@\"", (project.name)];
	[highlightsEditorStore loadWithCompletionBlock:^{
		[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[projectManager highlightsListForProjectDidChange:project];
		}];
		
		actionTracker();
	}];
}

- (NSArray /* GLAHighlightedItem */ *)copyHighlightsForProject:(GLAProject *)project
{
	NSParameterAssert(project != nil);
	GLAArrayEditorStore *highlightsEditorStore = [self highlightsEditorStoreForProject:project];
	if (highlightsEditorStore) {
		return [highlightsEditorStore copyChildren];
	}
	else {
		return nil;
	}
}

#pragma mark Files List

- (GLAArrayEditorStore *)filesListEditorStoreForCollection:(GLACollection *)filesListCollection createIfNeeded:(BOOL)create
{
	NSMutableDictionary *collectionIDsToFilesListEditorStores = (self.collectionIDsToFilesListEditorStores);
	if (collectionIDsToFilesListEditorStores == nil) {
		collectionIDsToFilesListEditorStores = (self.collectionIDsToFilesListEditorStores) = [NSMutableDictionary new];
	}
	
	NSUUID *collectionUUID = (filesListCollection.UUID);
	GLAArrayEditorStore *filesListEditorStore = collectionIDsToFilesListEditorStores[collectionUUID];
	if (filesListEditorStore) {
		return filesListEditorStore;
	}
	else if (!create) {
		return nil;
	}
	
	NSURL *JSONFileURL = [self filesListJSONFileURLForCollectionID:collectionUUID];
	BOOL collectionIsFreshlyMade = [self collectionWithUUIDIsFreshlyCreated:collectionUUID];
	
	filesListEditorStore = [[GLAArrayEditorStore alloc] initWithDelegate:self modelClass:[GLACollectedFile class] JSONFileURL:JSONFileURL JSONDictionaryKey:GLAProjectManagerJSONFilesListKey arrayEditorOptions:nil freshlyMade:collectionIsFreshlyMade];
	(filesListEditorStore.userInfo) =
	@{
	  @"collectionUUID": collectionUUID
	  };
	
	collectionIDsToFilesListEditorStores[collectionUUID] = filesListEditorStore;
	
	return filesListEditorStore;
}

- (GLAArrayEditorStore *)filesListEditorStoreForCollection:(GLACollection *)filesListCollection
{
	return [self filesListEditorStoreForCollection:filesListCollection createIfNeeded:YES];
}

- (BOOL)hasLoadedFilesForCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection createIfNeeded:NO];
	if (!filesListEditorStore) {
		return NO;
	}
	
	return (filesListEditorStore.finishedLoading);
}

- (void)loadFilesListForCollectionIfNeeded:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection];
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Load Files List for Collection \"%@\"", (filesListCollection.name)];
	[filesListEditorStore loadWithCompletionBlock:^{
		[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[projectManager filesListForCollectionDidChange:filesListCollection didLoad:YES];
		}];
		
		actionTracker();
	}];
}

- (NSArray *)copyFilesListForCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection];
	if (filesListEditorStore) {
		return [filesListEditorStore copyChildren];
	}
	else {
		return nil;
	}
}

- (GLACollectedFile *)collectedFileWithUUID:(NSUUID *)collectedFileUUID insideCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection];
	id<GLAArrayInspecting> arrayInspector = (filesListEditorStore.inspectArray);
	
	NSUInteger index = [arrayInspector indexOfFirstChildWhoseKey:@"UUID" hasValue:collectedFileUUID];
	if (index == NSNotFound) {
		return nil;
	}
	
	GLACollectedFile *collectedFile = [arrayInspector childAtIndex:index];
	return collectedFile;
}

#pragma mark - Saving

#pragma mark Save Now Project

- (void)requestSaveNowProject
{
	// FIXME: if now project is changed while a save is already in process, need a change counter or == here.
	if (self.needsToSaveNowProject) {
		return;
	}
	
	(self.needsToSaveNowProject) = YES;
	
	dispatch_block_t actionTracker = [self beginActionWithIdentifier:@"Save Now Project"];
	[self writeNowProject:actionTracker];
}

- (void)writeNowProject:(dispatch_block_t)completionBlock
{
	NSURL *fileURL = (self.nowProjectJSONFileURL);
	if (!fileURL) {
		return;
	}
	
	NSUUID *projectUUID = (self.nowProjectUUID);
	GLAProject *project = [self projectWithUUID:projectUUID];
	
	if (!project) {
		return;
	}
	
	[self runInBackground:^(GLAProjectManagerStore *store) {
		// TODO: support saving no now project.
		NSAssert(project != nil, @"Can't save no now project.");
		NSDictionary *JSONProject = [MTLJSONAdapter JSONDictionaryFromModel:project];
		
		NSDictionary *JSONDictionary =
		@{GLAProjectManagerJSONNowProjectKey: JSONProject};
		
		[store writeJSONDictionary:JSONDictionary toFileURL:fileURL];
		
		completionBlock();
		
		[store runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			(store.needsToSaveNowProject) = NO;
		}];
	}];
}

#pragma mark Save Project Collection List

- (void)requestSaveCollectionsForProject:(GLAProject *)project
{
	GLAArrayEditorStore *collectionsEditorStore = [self collectionsEditorStoreForProject:project];
	[collectionsEditorStore saveWithCompletionBlock:nil];
}

#pragma mark Save Collection Content

- (void)requestSaveFilesListForCollection:(GLACollection *)filesListCollection
{
	GLAArrayEditorStore *filesListEditorStore = [self filesListEditorStoreForCollection:filesListCollection];
	[filesListEditorStore saveWithCompletionBlock:nil];
}

#pragma mark Array Editor Store

- (void)arrayMantleJSONStore:(GLAArrayMantleJSONStore *)store handleError:(NSError *)error
{
	[self handleError:error fromSelector:nil];
}

- (NSOperationQueue *)foregroundOperationQueueForArrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore
{
	return (self.foregroundOperationQueue);
}

- (NSOperationQueue *)backgroundOperationQueueForArrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore
{
	return (self.backgroundOperationQueue);
}

- (void)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore handleError:(NSError *)error fromMethodWithSelector:(SEL)storeMethodSelector
{
	[self handleError:error fromSelector:storeMethodSelector];
}


- (NSArray *)arrayEditorStore:(GLAArrayEditorStore *)arrayEditorStore processLoadedChildrenInBackground:(NSArray *)children
{
	Class modelClass = (arrayEditorStore.modelClass);
	if ([modelClass isSubclassOfClass:[GLACollection class]]) {
		NSUUID *projectUUID = (arrayEditorStore.userInfo)[@"projectUUID"];
		
		NSMutableArray *processedChildren = [NSMutableArray arrayWithCapacity:(children.count)];
		for (GLACollection *collection in children) {
			GLACollection *collectionWithProject = [collection copyWithChangesFromEditing:^(id<GLACollectionEditing> editor) {
				(editor.projectUUID) = projectUUID;
			}];
			[processedChildren addObject:collectionWithProject];
		}
		
		return processedChildren;
	}
	else if ([modelClass isSubclassOfClass:[GLAHighlightedItem class]]) {
		NSUUID *projectUUID = (arrayEditorStore.userInfo)[@"projectUUID"];
		
		NSMutableArray *processedChildren = [NSMutableArray arrayWithCapacity:(children.count)];
		for (GLAHighlightedItem *item in children) {
			GLAHighlightedItem *itemWithProject = [item copyWithChangesFromEditing:^(id<GLAHighlightedItemEditing> editor) {
				(editor.projectUUID) = projectUUID;
			}];
			[processedChildren addObject:itemWithProject];
		}
		
		return processedChildren;
	}
	else {
		return children;
	}
}

#pragma mark Status

- (dispatch_block_t)beginActionWithIdentifier:(NSString *)actionIdentifierFormat, ... NS_FORMAT_FUNCTION(1,2)
{
	NSDate *nowDate = [NSDate date];
	
	va_list args;
	va_start(args, actionIdentifierFormat);
	NSString *actionIdentifier = [[NSString alloc] initWithFormat:actionIdentifierFormat arguments:args];
	va_end(args);
	
	[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
		if (!(store.actionsThatAreRunning)) {
			(store.actionsThatAreRunning) = [NSMutableSet new];
			(store.actionsToBeginTime) = [NSMutableDictionary new];
			(store.actionsToEndTime) = [NSMutableDictionary new];
		}
		
		[(store.actionsThatAreRunning) addObject:actionIdentifier];
		(store.actionsToBeginTime)[actionIdentifier] = nowDate;
	}];
	
	return ^ {
		NSDate *nowDate = [NSDate date];
		
		[self runInForeground:^(GLAProjectManagerStore *store, GLAProjectManager *projectManager) {
			[(store.actionsThatAreRunning) removeObject:actionIdentifier];
			(store.actionsToEndTime)[actionIdentifier] = nowDate;
		}];
	};
}

- (NSTimeInterval)durationOfLastRunOfActionWithIdentifier:(NSString *)actionIdentifier
{
	NSDate *beginDate = (self.actionsToBeginTime)[actionIdentifier];
	NSDate *endDate = (self.actionsToEndTime)[actionIdentifier];
	
	return [endDate timeIntervalSinceDate:beginDate];
}

- (NSString *)statusOfActions:(NSArray *)actionIdentifiers
{
	NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
	(numberFormatter.minimumFractionDigits) = 3;
	(numberFormatter.maximumFractionDigits) = 3;
	
	NSMutableArray *lines = [NSMutableArray array];
	for (NSString *actionIdentifier in actionIdentifiers) {
		NSTimeInterval duration = [self durationOfLastRunOfActionWithIdentifier:actionIdentifier];
		NSString *statusForAction = [NSString localizedStringWithFormat:@"%@s: %@", [numberFormatter stringFromNumber:@(duration)], actionIdentifier];
		[lines addObject:statusForAction];
	}
	
	return [lines componentsJoinedByString:@"\n"];
}

- (NSString *)statusOfCurrentActivity
{
	if (!(self.actionsThatAreRunning)) {
		return @"No activity yet";
	}
	
	return [self statusOfActions:[(self.actionsThatAreRunning) allObjects]];
}

- (NSString *)statusOfCompletedActivity
{
	if (!(self.actionsThatAreRunning)) {
		return @"Nothing completed yet";
	}
	
	return [self statusOfActions:[(self.actionsToEndTime) allKeys]];
}

@end


NSString *GLAProjectManagerAllProjectsDidChangeNotification = @"GLAProjectManagerAllProjectsDidChangeNotification";
NSString *GLAProjectManagerPlannedProjectsDidChangeNotification = @"GLAProjectManagerPlannedProjectsDidChangeNotification";
NSString *GLAProjectManagerNowProjectDidChangeNotification = @"GLAProjectManagerNowProjectDidChangeNotification";

NSString *GLAProjectDidChangeNotification = @"GLAProjectDidChangeNotification";
NSString *GLAProjectWasDeletedNotification = @"GLAProjectWasDeletedNotification";
NSString *GLAProjectCollectionsDidChangeNotification = @"GLAProjectCollectionsDidChangeNotification";
//NSString *GLAProjectManagerProjectRemindersDidChangeNotification = @"GLAProjectManagerProjectRemindersDidChangeNotification";

NSString *GLAProjectHighlightsDidChangeNotification = @"GLAProjectHighlightsDidChangeNotification";

NSString *GLACollectionDidChangeNotification = @"GLACollectionDidChangeNotification";
NSString *GLACollectionFilesListDidChangeNotification = @"GLACollectionFilesListDidChangeNotification";
