//
//  GLAPluckedCollectedFiles.h
//  Blik
//
//  Created by Patrick Smith on 23/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAPluckedItems.h"
#import "GLAProjectManager.h"
#import "GLACollectedFile.h"
#import "GLAArrayEditor.h"


@interface GLAPluckedCollectedFilesList : GLAPluckedItems

- (instancetype)initWithProjectManager:(GLAProjectManager *)projectManager;

@property(nonatomic) GLAProjectManager *projectManager;

- (BOOL)hasPluckedCollectedFiles;
- (NSArray *)copyPluckedCollectedFiles;

#pragma mark Plucking

- (void)addCollectedFilesToPluckList:(NSArray *)collectedFiles fromCollection:(GLACollection *)collection;

- (void)removeFromPluckListAnyCollectedFilesWithUUIDs:(NSSet *)filterUUIDs;
- (void)clearPluckList;

#pragma mark Placing

- (void)placeAllPluckedCollectedFilesIntoCollection:(GLACollection *)destinationCollection project:(GLAProject *)destinationProject;

- (void)placePluckedCollectedFilesFilteringByUUIDs:(NSSet *)filterUUIDs intoCollection:(GLACollection *)destinationCollection project:(GLAProject *)destinationProject;

@end

extern NSString *GLAPluckedCollectedFilesListDidAddCollectedFilesNotification;
extern NSString *GLAPluckedCollectedFilesListDidRemoveCollectedFilesNotification;
