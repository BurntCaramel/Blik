//
//  GLAProjectInstructionsViewController.m
//  Blik
//
//  Created by Patrick Smith on 5/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAProjectInstructionsViewController.h"
#import "GLAUIStyle.h"


@interface GLAProjectInstructionsViewController ()

@end

@implementation GLAProjectInstructionsViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	[uiStyle prepareTextLabel:(self.mainInstructionTextLabel)];
}

@end
