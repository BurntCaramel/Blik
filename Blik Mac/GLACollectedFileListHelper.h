//
//  GLACollectedFileTableViewHelper.h
//  Blik
//
//  Created by Patrick Smith on 18/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLACollectedFile.h"
#import "GLACollectedFilesSetting.h"


@protocol GLACollectedFileListHelperDelegate;


@interface GLACollectedFileListHelper : NSObject

- (instancetype)initWithDelegate:(id<GLACollectedFileListHelperDelegate>)delegate;

+ (NSArray *)defaultURLResourceKeysToRequest;

@property(weak, readonly, nonatomic) id<GLACollectedFileListHelperDelegate> delegate;

@property(copy, nonatomic) GLAProject *project;

@property(copy, nonatomic) NSArray *collectedFiles;
@property(readonly, nonatomic) GLACollectedFilesSetting *collectedFilesSetting;
//@property(readonly, nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

- (id<GLAFileAccessing>)accessFileForCollectedFile:(GLACollectedFile *)collectedFile;

#pragma mark -

- (void)setUpTableCellView:(NSTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn collectedFile:(GLACollectedFile *)collectedFile;

@end


@protocol GLACollectedFileListHelperDelegate <NSObject>

- (void)collectedFileListHelperDidInvalidate:(GLACollectedFileListHelper *)helper;

@optional

- (void)collectedFileListHelper:(GLACollectedFileListHelper *)helper didLoadInfoForCollectedFiles:(NSArray *)collectedFiles;

//- (NSArray *)orderedCollectedFilesForCollectedFileListHelper:(GLACollectedFileListHelper *)helper;
//- (void)collectedFileListHelper:(GLACollectedFileListHelper *)helper didLoadInfoForCollectedFilesAtIndexes:(NSIndexSet *)indexes;

@end