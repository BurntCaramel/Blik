//
//  GLACollectedFilesSetting.h
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLACollectedFile.h"
#import "GLAFileInfoRetriever.h"


typedef id (^ GLACollectedFilesSettingFileInfoRetriever)(GLAFileInfoRetriever *fileInfoRetriever, NSURL *fileURL);


@interface GLACollectedFilesSetting : NSObject

@property(nonatomic) NSSet *directoryURLsToWatch;

- (void)startAccessingCollectedFile:(GLACollectedFile *)collectedFile;
- (void)startAccessingCollectedFile:(GLACollectedFile *)collectedFile invalidate:(BOOL)invalidate;
- (void)stopAccessingCollectedFile:(GLACollectedFile *)collectedFile;

- (void)stopAccessingAllCollectedFilesWaitingUntilDone;

- (void)startAccessingCollectedFilesStoppingRemainders:(NSArray *)collectedFiles;
- (void)startAccessingCollectedFilesStoppingRemainders:(NSArray *)collectedFiles invalidateAll:(BOOL)invalidateAll;

@property(nonatomic) id<GLALoadableArrayUsing> sourceCollectedFilesLoadableArray;

// Must call -startAccessing first. Can be nil.
- (GLAAccessedFileInfo *)accessedFileInfoForCollectedFile:(GLACollectedFile *)collectedFile;
- (NSURL *)filePathURLForCollectedFile:(GLACollectedFile *)collectedFile;

- (void)invalidateAllAccessedFiles;

#pragma mark -

@property(copy, nonatomic) NSArray *defaultURLResourceKeysToRequest;
- (void)addToDefaultURLResourceKeysToRequest:(NSArray *)array;

- (id)copyValueForURLResourceKey:(NSString *)resourceKey forCollectedFile:(GLACollectedFile *)collectedFile;

- (void)addRetrieverBlockForFileInfo:(GLACollectedFilesSettingFileInfoRetriever)retrieverBlock withIdentifier:(NSString *)infoIdentifier;
// Will be nil until it has loaded.
- (id)copyValueForFileInfoIdentifier:(NSString *)infoIdentifier forCollectedFile:(GLACollectedFile *)collectedFile;

@end

extern NSString *GLACollectedFilesSettingDirectoriesDidChangeNotification;
extern NSString *GLACollectedFilesSettingLoadedFileInfoDidChangeNotification;
extern NSString *GLACollectedFilesSettingLoadedFileInfoDidChangeNotification_CollectedFile;


@interface GLACollectedFilesSetting (UIConvenience)

- (void)setUpTableCellView:(NSTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn collectedFile:(GLACollectedFile *)collectedFile;

- (void)setUpMenuItem:(NSMenuItem *)menuItem forOptionalCollectedFile:(GLACollectedFile *)collectedFile wantsIcon:(BOOL)wantsIcon;

@end
