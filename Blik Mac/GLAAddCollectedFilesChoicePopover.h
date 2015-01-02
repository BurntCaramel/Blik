//
//  GLAAddCollectedFilesChoicePopover.h
//  Blik
//
//  Created by Patrick Smith on 9/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAPendingAddedCollectedFilesInfo.h"
#import "GLAAddCollectedFilesChoiceViewController.h"
#import "GLAAddCollectedFilesChoiceActions.h"


@interface GLAAddCollectedFilesChoicePopover : NSPopover

+ (instancetype)sharedAddCollectedFilesChoicePopover;

@property(nonatomic) GLAAddCollectedFilesChoiceViewController *addCollectedFilesChoiceViewController;

@property(copy, nonatomic) GLAPendingAddedCollectedFilesInfo *info;

@property(weak, nonatomic) id<GLAAddCollectedFilesChoiceActionsDelegate> actionsDelegate;

@end
