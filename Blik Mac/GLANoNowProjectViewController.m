//
//  GLANoNowProjectViewController.m
//  Blik
//
//  Created by Patrick Smith on 7/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLANoNowProjectViewController.h"
#import "GLAUIStyle.h"


@interface GLANoNowProjectViewController ()

@end

@implementation GLANoNowProjectViewController

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	
	[uiStyle prepareTextLabel:(self.mainLabel)];
}

@end
