//
//  GLAArrangedDirectoryChildren.h
//  Blik
//
//  Created by Patrick Smith on 11/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Foundation;
//#import "GLAFileInfoRetriever.h"

@class GLAFileInfoRetriever;


@protocol GLAArrangedDirectoryChildrenOptionViewing <NSObject>

@property(readonly, copy, nonatomic) NSString *resourceKeyToSortBy;
@property(readonly, nonatomic) BOOL sortsAscending;

@property(readonly, nonatomic) BOOL hidesInvisibles;

@end

@protocol GLAArrangedDirectoryChildrenOptionEditing <GLAArrangedDirectoryChildrenOptionViewing>

@property(readwrite, copy, nonatomic) NSString *resourceKeyToSortBy;
@property(readwrite, nonatomic) BOOL sortsAscending;

@property(readwrite, nonatomic) BOOL hidesInvisibles;

@end


@protocol GLAArrangedDirectoryChildrenDelegate;
// To be used on the Main Queue;
// Does processing on a background queue.
@interface GLAArrangedDirectoryChildren : NSObject <GLAArrangedDirectoryChildrenOptionViewing>

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL delegate:(id<GLAArrangedDirectoryChildrenDelegate>)delegate fileInfoRetriever:(GLAFileInfoRetriever *)fileInfoRetriever;

@property(readonly, nonatomic) NSURL *directoryURL;
@property(readonly, weak, nonatomic) id<GLAArrangedDirectoryChildrenDelegate> delegate;
@property(readonly, nonatomic) GLAFileInfoRetriever *fileInfoRetriever;

- (void)updateAfterEditingOptions:( void( ^ )(id<GLAArrangedDirectoryChildrenOptionEditing> editor) )editorBlock;

@property(readonly, copy, nonatomic) NSArray *arrangedChildren;

@end

@protocol GLAArrangedDirectoryChildrenDelegate <NSObject>

- (void)arrangedDirectoryChildrenDidUpdateChildren:(GLAArrangedDirectoryChildren *)arrangedDirectoryChildren;

@end
