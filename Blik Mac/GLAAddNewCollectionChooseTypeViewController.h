//
//  GLAAddNewCollectionChooseTypeViewController.h
//  Blik
//
//  Created by Patrick Smith on 18/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAMainSectionNavigator.h"


@interface GLAAddNewCollectionChooseTypeViewController : GLAViewController

@property(strong, nonatomic) IBOutlet NSTextField *headingLabel;
@property(strong, nonatomic) IBOutlet NSTextField *collectedFilesLabel;
@property(strong, nonatomic) IBOutlet NSTextField *filteredFolderLabel;

@property(nonatomic) GLAProject *project;
@property(nonatomic) GLAMainSectionNavigator *sectionNavigator;

@end
