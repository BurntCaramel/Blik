//
//  GLAPopUpButton.h
//  Blik
//
//  Created by Patrick Smith on 8/08/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
@class GLAPopUpButtonCell;


@interface GLAPopUpButton : NSPopUpButton

@property (nonatomic) GLAPopUpButtonCell *cell;

@property (nonatomic, getter = isAlwaysHighlighted) BOOL alwaysHighlighted;

@end


@interface GLAPopUpButtonCell : NSPopUpButtonCell

@property (nonatomic, getter = isAlwaysHighlighted) BOOL alwaysHighlighted;

@end