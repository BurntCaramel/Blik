//
//  GLACollectedFolderContentViewController.h
//  Blik
//
//  Created by Patrick Smith on 10/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLACollectedFile.h"


@interface GLACollectedFolderContentsViewController : GLAViewController

@property(nonatomic) GLACollectedFile *collectedFolder;
@property(nonatomic) NSURL *sourceDirectoryURL;

@property(nonatomic) NSString *resourceKeyToSortBy;
@property(nonatomic) BOOL sortsAscending;

@property(nonatomic) BOOL hidesInvisibles;

@property(nonatomic) IBOutlet NSOutlineView *folderContentOutlineView;

@end
