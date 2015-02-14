//
//  GLANavigationButtonGroup.h
//  Blik
//
//  Created by Patrick Smith on 10/02/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAViewController.h"
#import "GLAButton.h"


@interface GLANavigationButtonGroup : NSObject

+ (instancetype)buttonGroupWithViewController:(GLAViewController *)viewController templateButton:(GLAButton *)templateButton;

@property(weak, nonatomic) GLAViewController *viewController;
@property(nonatomic) GLAButton *templateButton;

- (GLAButton *)makeLeadingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier;
- (GLAButton *)makeCenterButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier;
- (GLAButton *)makeTrailingButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier;

- (GLAButton *)addButtonWithTitle:(NSString *)title action:(SEL)action identifier:(NSString *)identifier;

@property(nonatomic) GLAButton *leadingButton;
@property(nonatomic) GLAButton *centerButton;
@property(nonatomic) GLAButton *trailingButton;

@property(nonatomic) NSTimeInterval leadingButtonInDuration;
@property(nonatomic) NSTimeInterval leadingButtonOutDuration;
@property(nonatomic) NSTimeInterval centerButtonInDuration;
@property(nonatomic) NSTimeInterval centerButtonOutDuration;
@property(nonatomic) NSTimeInterval trailingButtonInDuration;
@property(nonatomic) NSTimeInterval trailingButtonOutDuration;

- (void)animateButtonsIn;
- (void)animateButtonsOutWithCompletionHandler:(dispatch_block_t)completionHandler;

@end
