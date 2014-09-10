//
//  GLAAddNewProjectViewController.h
//  Blik
//
//  Created by Patrick Smith on 14/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLATextField.h"


@interface GLAAddNewProjectViewController : GLAViewController

@property(strong, nonatomic) IBOutlet NSTextField *nameLabel;
@property(strong, nonatomic) IBOutlet GLATextField *nameTextField;

- (void)resetAndFocus;

@end
