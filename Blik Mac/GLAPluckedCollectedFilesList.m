//
//  GLAPluckedCollectedFiles.m
//  Blik
//
//  Created by Patrick Smith on 23/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAPluckedCollectedFilesList.h"
#import "NSMutableDictionary+PGWSChecking.h"
#import "GLAModelUUIDMap.h"


@interface GLAPluckedCollectedFilesList ()

@property(readonly, nonatomic) NSMutableDictionary *projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs;

@property(readonly, nonatomic) GLAArrayEditor *collectedFilesArrayEditor;

@end

@implementation GLAPluckedCollectedFilesList

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager;
{
	self = [super init];
	if (self) {
		_projectManager = projectManager;
		_projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs = [NSMutableDictionary new];
		
		GLAArrayEditorOptions *arrayEditorOptions = [GLAArrayEditorOptions new];
		[arrayEditorOptions setPrimaryIndexer:[GLAModelUUIDMap new]];
		_collectedFilesArrayEditor = [[GLAArrayEditor alloc] initWithObjects:@[] options:arrayEditorOptions];
		
		[self startObserving];
	}
	return self;
}

- (void)dealloc
{
	[self stopObserving];
}

- (void)startObserving
{
	//GLAProjectManager *pm = (self.projectManager);
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self selector:@selector(collectionWasDeletedNotification:) name:GLACollectionWasDeletedNotification object:nil];
}

- (void)stopObserving
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc removeObserver:self];
}

- (void)collectionWasDeletedNotification:(NSNotification *)note
{
	NSDictionary *userInfo = (note.userInfo);
	GLACollection *collection = userInfo[GLACollectionNotificationUserInfoCollectionKey];
	[self removeFromPluckListAllCollectedFilesInCollectionsWithUUIDs:[NSSet setWithObject:(collection.UUID)]];
}

#pragma mark -

- (BOOL)hasPluckedCollectedFiles
{
	return (self.collectedFilesArrayEditor.childrenCount) > 0;
}

- (NSArray *)copyPluckedCollectedFiles
{
	return [(self.collectedFilesArrayEditor) copyChildren];
}

#pragma mark Plucking

- (void)addCollectedFilesToPluckList:(NSArray *)collectedFiles fromCollection:(GLACollection *)collection
{
	NSUUID *collectionUUID = (collection.UUID);
	NSUUID *projectUUID = (collection.projectUUID);
	
	NSMutableDictionary *projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs = (self.projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs);
	
	NSMutableDictionary *collectionUUIDsToCollectedFileUUIDs = [projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs pgws_objectForKey:projectUUID addingInstanceOfClassIfNotPresent:[NSMutableDictionary class]];
	
	NSMutableSet *pluckedCollectedFileUUIDs = [collectionUUIDsToCollectedFileUUIDs pgws_objectForKey:collectionUUID addingInstanceOfClassIfNotPresent:[NSMutableSet class]];
	
	NSSet *collectedFileUUIDsToAdd = [NSSet setWithArray:[collectedFiles valueForKey:@"UUID"]];
	[pluckedCollectedFileUUIDs unionSet:collectedFileUUIDsToAdd];
	
	
	GLAArrayEditor *collectedFilesArrayEditor = (self.collectedFilesArrayEditor);
	[collectedFilesArrayEditor changesMadeInBlock:^(id<GLAArrayEditing> arrayEditor) {
		NSArray *collectedFilesToAdd = [arrayEditor filterArray:collectedFiles whoseResultFromVisitorIsNotAlreadyPresent:^NSUUID *(GLACollectedFile *collectedFile) {
			return (collectedFile.UUID);
		}];
		[arrayEditor addChildren:collectedFilesToAdd];
	}];
	
	
	[self didAddCollectedFiles];
}

- (NSArray *)removeFromPluckListAnyCollectedFilesWithUUIDs:(NSSet *)filterUUIDs removeFromSourceCollections:(BOOL)removeFromSourceCollections
{
	NSMutableSet *removedCollectedFileUUIDs = [NSMutableSet new];
	NSMutableArray *collectedFilesToPlace = [NSMutableArray new];
	
	NSMutableDictionary *projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs = (self.projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs);
	for (NSUUID *projectUUID in projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs)
	{
		NSMutableDictionary *collectionUUIDsToCollectedFileUUIDs = projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs[projectUUID];
		
		for (NSUUID *collectionUUID in collectionUUIDsToCollectedFileUUIDs)
		{
			NSMutableSet *pluckedCollectedFileUUIDs = collectionUUIDsToCollectedFileUUIDs[collectionUUID];
			
			NSMutableSet *pluckedCollectedFileUUIDsFiltered = [pluckedCollectedFileUUIDs mutableCopy];
			if (filterUUIDs) {
				[pluckedCollectedFileUUIDsFiltered intersectSet:filterUUIDs];
			}
			
			if ((pluckedCollectedFileUUIDsFiltered.count) == 0) {
				continue;
			}
			
			[pluckedCollectedFileUUIDs minusSet:pluckedCollectedFileUUIDsFiltered];
			
			[removedCollectedFileUUIDs unionSet:pluckedCollectedFileUUIDsFiltered];
			
			if (removeFromSourceCollections) {
				NSArray *collectedFiles = [self removeCollectedFilesWithUUIDs:pluckedCollectedFileUUIDsFiltered fromCollectionWithUUID:collectionUUID projectUUID:projectUUID];
				[collectedFilesToPlace addObjectsFromArray:collectedFiles];
			}
		}
	}
	
	GLAArrayEditor *collectedFilesArrayEditor = (self.collectedFilesArrayEditor);
	[collectedFilesArrayEditor changesMadeInBlock:^(id<GLAArrayEditing> arrayEditor) {
		NSIndexSet *indexes = [arrayEditor indexesOfChildrenWhoseResultFromVisitor:^NSUUID *(GLACollectedFile *collectedFile) {
			return (collectedFile.UUID);
		} hasValueContainedInSet:removedCollectedFileUUIDs];
		[arrayEditor removeChildrenAtIndexes:indexes];
	}];
	
	[self didRemoveCollectedFiles];
	
	return collectedFilesToPlace;
}

- (void)removeFromPluckListAllCollectedFilesInCollectionsWithUUIDs:(NSSet *)collectionUUIDs
{
	NSMutableSet *removedCollectedFileUUIDs = [NSMutableSet new];
	
	NSMutableDictionary *projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs = (self.projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs);
	for (NSUUID *projectUUID in projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs)
	{
		NSMutableDictionary *collectionUUIDsToCollectedFileUUIDs = projectUUIDsToCollectionUUIDsToPluckedCollectedFileUUIDs[projectUUID];
		
		for (NSUUID *collectionUUID in collectionUUIDsToCollectedFileUUIDs)
		{
			if ([collectionUUIDs containsObject:collectionUUID]) {
				NSMutableSet *pluckedCollectedFileUUIDs = collectionUUIDsToCollectedFileUUIDs[collectionUUID];
				[removedCollectedFileUUIDs unionSet:pluckedCollectedFileUUIDs];
				
				[collectionUUIDsToCollectedFileUUIDs removeObjectForKey:collectionUUID];
			}
		}
	}
	
	
	GLAArrayEditor *collectedFilesArrayEditor = (self.collectedFilesArrayEditor);
	[collectedFilesArrayEditor changesMadeInBlock:^(id<GLAArrayEditing> arrayEditor) {
		NSIndexSet *indexes = [arrayEditor indexesOfChildrenWhoseResultFromVisitor:^NSUUID *(GLACollectedFile *collectedFile) {
			return (collectedFile.UUID);
		} hasValueContainedInSet:removedCollectedFileUUIDs];
		[arrayEditor removeChildrenAtIndexes:indexes];
	}];
	
	
	[self didRemoveCollectedFiles];
}

- (NSArray *)removeCollectedFilesWithUUIDs:(NSSet *)collectedFilesUUIDs fromCollectionWithUUID:(NSUUID *)collectionUUID projectUUID:(NSUUID *)projectUUID
{
	__block NSArray *collectedFiles = nil;
	
	GLAProjectManager *pm = (self.projectManager);
	
	GLACollection *collection = [pm collectionWithUUID:collectionUUID inProjectWithUUID:projectUUID];
	NSAssert(collection != nil, @"Collection still exists");
	[pm editFilesListOfCollection:collection usingBlock:^(id<GLAArrayEditing> filesListEditor) {
		NSIndexSet *indexes = [filesListEditor indexesOfChildrenWhoseResultFromVisitor:^NSUUID *(GLACollectedFile *collectedFile) {
			return (collectedFile.UUID);
		} hasValueContainedInSet:collectedFilesUUIDs];
		
		collectedFiles = [filesListEditor childrenAtIndexes:indexes];
		
		[filesListEditor removeChildrenAtIndexes:indexes];
	}];
	
	return collectedFiles;
}

- (void)removeFromPluckListAnyCollectedFilesWithUUIDs:(NSSet *)filterUUIDs
{
	(void)[self removeFromPluckListAnyCollectedFilesWithUUIDs:filterUUIDs removeFromSourceCollections:NO];
}

- (void)clearPluckList
{
	(void)[self removeFromPluckListAnyCollectedFilesWithUUIDs:nil removeFromSourceCollections:NO];
}

#pragma mark Placing

- (void)placeAllPluckedCollectedFilesIntoCollection:(GLACollection *)destinationCollection project:(GLAProject *)destinationProject
{
	NSArray *collectedFilesToPlace = [self removeFromPluckListAnyCollectedFilesWithUUIDs:nil removeFromSourceCollections:YES];
	
	GLAProjectManager *pm = (self.projectManager);
	
	[pm editFilesListOfCollection:destinationCollection addingCollectedFiles:collectedFilesToPlace queueIfNeedsLoading:YES];
}

- (void)placePluckedCollectedFilesFilteringByUUIDs:(NSSet *)filterUUIDs intoCollection:(GLACollection *)destinationCollection project:(GLAProject *)destinationProject
{
	NSArray *collectedFilesToPlace = [self removeFromPluckListAnyCollectedFilesWithUUIDs:filterUUIDs removeFromSourceCollections:YES];
	
	GLAProjectManager *pm = (self.projectManager);
	
	[pm editFilesListOfCollection:destinationCollection addingCollectedFiles:collectedFilesToPlace queueIfNeedsLoading:YES];
}

#pragma mark - Notifications

- (void)didAddCollectedFiles
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAPluckedCollectedFilesListDidAddCollectedFilesNotification object:self];
}

- (void)didRemoveCollectedFiles
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GLAPluckedCollectedFilesListDidRemoveCollectedFilesNotification object:self];
}

@end

NSString *GLAPluckedCollectedFilesListDidAddCollectedFilesNotification = @"GLAPluckedCollectedFilesListDidAddCollectedFilesNotification";
NSString *GLAPluckedCollectedFilesListDidRemoveCollectedFilesNotification = @"GLAPluckedCollectedFilesListDidRemoveCollectedFilesNotification";

