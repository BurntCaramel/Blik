//
//  GLAAddCollectedFilesChoiceViewController.h
//  Blik
//
//  Created by Patrick Smith on 9/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAPendingAddedCollectedFilesInfo.h"
#import "GLAButton.h"
#import "GLAAddCollectedFilesChoiceActions.h"


@interface GLAAddCollectedFilesChoiceViewController : GLAViewController

@property(nonatomic) IBOutlet GLAButton *addToExistingCollectionButton;
@property(nonatomic) IBOutlet GLAButton *addToNewCollectionButton;

@property(copy, nonatomic) GLAPendingAddedCollectedFilesInfo *info;

- (IBAction)addToExistingCollection:(id)sender;
- (IBAction)addToNewCollection:(id)sender;

@property(weak, nonatomic) id<GLAAddCollectedFilesChoiceActionsDelegate> actionsDelegate;

@end
