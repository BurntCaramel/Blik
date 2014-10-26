//
//  GLAAddNewProjectViewController.h
//  Blik
//
//  Created by Patrick Smith on 14/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
#import "GLATextField.h"
#import "GLAButton.h"


@interface GLAAddNewProjectViewController : GLAViewController

@property(strong, nonatomic) IBOutlet NSTextField *nameLabel;
@property(strong, nonatomic) IBOutlet GLATextField *nameTextField;

@property(strong, nonatomic) IBOutlet GLAButton *confirmCreateButton;

- (void)resetAndFocus;

- (IBAction)confirmCreate:(id)sender;

@end

extern NSString *GLAAddNewProjectViewControllerDidConfirmCreatingNotification;
