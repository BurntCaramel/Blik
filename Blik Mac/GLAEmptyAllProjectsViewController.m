//
//  GLAEmptyAllProjectsViewController.m
//  Blik
//
//  Created by Patrick Smith on 27/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAEmptyAllProjectsViewController.h"
#import "GLAUIStyle.h"


@interface GLAEmptyAllProjectsViewController ()

@end

@implementation GLAEmptyAllProjectsViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	[uiStyle prepareTextLabel:(self.mainLabel)];
}

@end
