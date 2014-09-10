//
//  GLAAddNewProjectViewController.m
//  Blik
//
//  Created by Patrick Smith on 14/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAAddNewProjectViewController.h"

@interface GLAAddNewProjectViewController ()

@end

@implementation GLAAddNewProjectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)resetAndFocus
{
	(self.nameTextField.stringValue) = @"";
	
	[(self.view.window) makeFirstResponder:(self.nameTextField)];
}

@end
