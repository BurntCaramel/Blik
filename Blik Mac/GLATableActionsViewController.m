//
//  GLATableActionsViewController.m
//  Blik
//
//  Created by Patrick Smith on 13/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLATableActionsViewController.h"

@interface GLATableActionsViewController ()

@property(nonatomic) BOOL private_expanded;

@end

@implementation GLATableActionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)addInsideView:(NSView *)holderView underRelativeToView:(NSView *)associatedView
{
	NSView *actionsView = (self.view);
	NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:actionsView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
	(heightConstraint.priority) = 999;
	
	NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:actionsView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:associatedView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
	(topConstraint.priority) = 750;
	
	(self.heightConstraint) = heightConstraint;
	(self.topConstraint) = topConstraint;
	
	NSArray *constraints =
	@[
	  // Leading
	  [NSLayoutConstraint constraintWithItem:actionsView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:associatedView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
	  // Width
	  [NSLayoutConstraint constraintWithItem:actionsView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:associatedView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0],
	  topConstraint,
	  heightConstraint
	  ];
	
	(self.holderView) = holderView;
	[holderView addSubview:actionsView];
	[holderView addConstraints:constraints];
}

- (void)addBottomConstraintToView:(NSView *)bottomView
{
	NSView *actionsView = (self.view);
	
	NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:bottomView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:actionsView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
	(bottomConstraint.priority) = 750;
	
	(self.bottomConstraint) = bottomConstraint;
	[(self.holderView) addConstraint:bottomConstraint];
}

@end
