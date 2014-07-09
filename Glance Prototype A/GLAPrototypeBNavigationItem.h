//
//  GLAPrototypeBNavigationItem.h
//  Glance Prototype A
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLAPrototypeBNavigationItemCell;


@interface GLAPrototypeBNavigationItem : NSButton

@end


@interface GLAPrototypeBNavigationItemCell : NSButtonCell

@property (nonatomic) CGFloat leftSpacing;
@property (nonatomic) CGFloat rightSpacing;
@property (nonatomic) CGFloat verticalOffsetDown;

@property (readonly, nonatomic, getter = isAlwaysHighlighted) BOOL alwaysHighlighted;
@property (readonly, nonatomic, getter = isOnAndShowsOnState) BOOL onAndShowsOnState;

@end