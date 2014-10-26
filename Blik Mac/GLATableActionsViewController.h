//
//  GLATableActionsViewController.h
//  Blik
//
//  Created by Patrick Smith on 13/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAViewController.h"


@interface GLATableActionsViewController : GLAViewController

@property(nonatomic) NSView *holderView;
@property(nonatomic) NSLayoutConstraint *heightConstraint;
@property(nonatomic) NSLayoutConstraint *topConstraint;

- (void)addInsideView:(NSView *)holderView underRelativeToView:(NSView *)associatedView;

@property(nonatomic) NSLayoutConstraint *bottomConstraint;

- (void)addBottomConstraintToView:(NSView *)bottomView;

@end
