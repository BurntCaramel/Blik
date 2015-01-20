//
//  GLACollectedFileTableViewHelper.h
//  Blik
//
//  Created by Patrick Smith on 18/01/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAFileInfoRetriever.h"
#import "GLACollectedFile.h"


@protocol GLACollectedFileListHelperDelegate;


@interface GLACollectedFileListHelper : NSObject <GLAFileInfoRetrieverDelegate>

- (instancetype)initWithDelegate:(id<GLACollectedFileListHelperDelegate>)delegate;

@property(nonatomic, weak, readonly) id<GLACollectedFileListHelperDelegate> delegate;

@property(nonatomic, copy) NSArray *collectedFiles;

@property(nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

- (void)setUpTableCellView:(NSTableCellView *)cellView forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@end


@protocol GLACollectedFileListHelperDelegate

- (void)collectedFileListHelper:(GLACollectedFileListHelper *)helper didLoadInfoForCollectedFilesAtIndexes:(NSIndexSet *)indexes;

@end