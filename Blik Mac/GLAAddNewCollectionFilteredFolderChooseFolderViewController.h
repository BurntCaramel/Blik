//
//  GLAAddNewCollectionFilteredFolderChooseFolderViewController.h
//  Blik
//
//  Created by Patrick Smith on 18/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAButton.h"
#import "GLAPopUpButton.h"
#import "GLAMainSectionNavigator.h"


@interface GLAAddNewCollectionFilteredFolderChooseFolderViewController : GLAViewController

@property(nonatomic) IBOutlet NSTextField *chooseFolderLabel;
@property(nonatomic) IBOutlet NSTextField *chooseTagLabel;

@property(nonatomic) IBOutlet NSImageView *chosenFolderIconImageView;
@property(nonatomic) IBOutlet NSTextField *chosenFolderNameField;

@property(nonatomic) IBOutlet GLAButton *chooseFolderButton;

@property(nonatomic) IBOutlet GLAPopUpButton *chooseTagPopUpButton;

@property(nonatomic) IBOutlet GLAButton *nextButton;

@property(readonly, nonatomic) NSURL *chosenFolderURL;
@property(readonly, copy, nonatomic) NSString *chosenTagName;

@property(nonatomic) GLAMainSectionNavigator *sectionNavigator;

@end
