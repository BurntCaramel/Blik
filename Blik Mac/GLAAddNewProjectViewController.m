//
//  GLAAddNewProjectViewController.m
//  Blik
//
//  Created by Patrick Smith on 14/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAAddNewProjectViewController.h"
#import "GLAUIStyle.h"


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

- (void)prepareView
{
	[super prepareView];
	
	GLAUIStyle *uiStyle = [GLAUIStyle activeStyle];
	NSTextField *nameLabel = (self.nameLabel);
	(nameLabel.textColor) = (uiStyle.lightTextColor);
	(nameLabel.layer.borderColor) = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0].CGColor;
}

- (void)resetAndFocus
{
	(self.nameTextField.stringValue) = @"";
	
	[(self.view.window) makeFirstResponder:(self.nameTextField)];
}

- (IBAction)confirmCreate:(id)sender
{
	
}

@end
