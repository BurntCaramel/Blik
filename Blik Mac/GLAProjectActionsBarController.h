//
//  GLAProjectActionsBarController.h
//  Blik
//
//  Created by Patrick Smith on 14/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"
#import "GLAView.h"
#import "GLAButton.h"

@interface GLAProjectActionsBarController : GLAViewController <GLAViewDelegate>

@property(strong, nonatomic) IBOutlet GLAView *normalView;
@property(strong, nonatomic) IBOutlet GLAView *editingItemsView;
@property(strong, nonatomic) IBOutlet GLAView *editingPlanView;

@property(strong, nonatomic) IBOutlet GLAButton *editItemsButton;
@property(strong, nonatomic) IBOutlet GLAButton *finishEditingItemsButton;

@property(strong, nonatomic) IBOutlet GLAButton *editPlanButton;
@property(strong, nonatomic) IBOutlet GLAButton *finishEditingPlanButton;

- (void)showBarForEditingItems;
- (void)hideBarForEditingItems;

- (void)showBarForEditingPlan;
- (void)hideBarForEditingPlan;

@end
