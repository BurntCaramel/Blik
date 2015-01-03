//
//  GLAAddCollectedFilesChoiceViewController.m
//  Blik
//
//  Created by Patrick Smith on 9/12/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAAddCollectedFilesChoiceViewController.h"


@interface GLAAddCollectedFilesChoiceViewController ()

@end

@implementation GLAAddCollectedFilesChoiceViewController

- (void)prepareView
{
    [super prepareView];
	
	
}

- (IBAction)addToExistingCollection:(id)sender
{
	id<GLAAddCollectedFilesChoiceActionsDelegate> actionsDelegate = (self.actionsDelegate);
	if ((actionsDelegate) && [actionsDelegate respondsToSelector:@selector(performAddCollectedFilesToExistingCollection:info:)]) {
		[actionsDelegate performAddCollectedFilesToExistingCollection:self info:(self.info)];
	}
}

- (IBAction)addToNewCollection:(id)sender
{
	id<GLAAddCollectedFilesChoiceActionsDelegate> actionsDelegate = (self.actionsDelegate);
	if ((actionsDelegate) && [actionsDelegate respondsToSelector:@selector(performAddCollectedFilesToNewCollection:info:)]) {
		[actionsDelegate performAddCollectedFilesToNewCollection:self info:(self.info)];
	}
}

@end
