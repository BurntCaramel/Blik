//
//  GLAAddNewCollectionViewController.h
//  Blik
//
//  Created by Patrick Smith on 27/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAProject.h"
#import "GLACollection.h"
#import "GLACollectionColor.h"
#import "GLAPendingAddedCollectedFilesInfo.h"
#import "GLATextField.h"
#import "GLAButton.h"
#import "GLAColorChoiceView.h"


@interface GLAAddNewCollectionViewController : GLAViewController

@property(strong, nonatomic) GLAProject *project;

@property(copy, nonatomic) GLAPendingAddedCollectedFilesInfo *pendingAddedCollectedFilesInfo;

@property(strong, nonatomic) IBOutlet NSTextField *nameLabel;
@property(strong, nonatomic) IBOutlet GLATextField *nameTextField;

@property(strong, nonatomic) IBOutlet NSTextField *colorLabel;
@property(strong, nonatomic) IBOutlet GLAColorChoiceView *colorChoiceView;
@property(strong, nonatomic) IBOutlet GLACollectionColor *chosenCollectionColor;

@property(strong, nonatomic) IBOutlet GLAButton *confirmCreateButton;

- (void)resetAndFocus;

- (IBAction)confirmCreate:(id)sender;

@end

extern NSString *GLAAddNewCollectionViewControllerDidConfirmCreatingNotification;