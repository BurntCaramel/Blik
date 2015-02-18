//
//  GLAAddNewCollectionChooseTypeViewController.m
//  Blik
//
//  Created by Patrick Smith on 18/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAAddNewCollectionChooseTypeViewController.h"
#import "GLAUIStyle.h"


@interface GLAAddNewCollectionChooseTypeViewController ()

@end

@implementation GLAAddNewCollectionChooseTypeViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *style = [GLAUIStyle activeStyle];
	[style prepareSecondaryInstructionalTextLabel:(self.collectedFilesLabel)];
	[style prepareSecondaryInstructionalTextLabel:(self.filteredFolderLabel)];
}

- (IBAction)createNewCollectedFilesCollection:(id)sender
{
	[(self.sectionNavigator) addNewCollectionGoToCollectedFilesSection];
}

- (IBAction)createNewFilteredFolderCollection:(id)sender
{
	[(self.sectionNavigator) addNewCollectionGoToFilteredFolderSection];
}

@end
