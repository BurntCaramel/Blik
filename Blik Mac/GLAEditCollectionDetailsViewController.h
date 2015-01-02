//
//  GLAEditCollectionDetailsViewController.h
//  Blik
//
//  Created by Patrick Smith on 20/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAView.h"
#import "GLACollection.h"
#import "GLACollectionColorPickerViewController.h"
#import "GLATextField.h"


@interface GLAEditCollectionDetailsViewController : GLAViewController

@property(strong, nonatomic) IBOutlet NSTextField *nameLabel;
@property(nonatomic) IBOutlet GLATextField *nameTextField;

@property(strong, nonatomic) IBOutlet NSTextField *colorLabel;
@property(strong, nonatomic) IBOutlet GLAView *colorPickerHolderView;
@property(nonatomic) GLAViewController *colorPickerHolderViewController;
@property(strong, nonatomic) GLACollectionColorPickerViewController *colorPickerViewController;

- (IBAction)nameChanged:(id)sender;
- (void)chosenColorDidChange:(NSNotification *)note;

@property(nonatomic) NSString *chosenName;
@property(nonatomic) GLACollectionColor *chosenCollectionColor;

- (void)addObserver:(id)observer forChosenNameDidChangeNotificationWithSelector:(SEL)aSelector;
- (void)addObserver:(id)observer forChosenColorDidChangeNotificationWithSelector:(SEL)aSelector;

@end

extern NSString *GLAEditCollectionDetailsViewControllerChosenNameDidChangeNotification;
extern NSString *GLAEditCollectionDetailsViewControllerChosenColorDidChangeNotification;
