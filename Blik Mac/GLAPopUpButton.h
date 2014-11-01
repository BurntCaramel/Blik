//
//  GLAPopUpButton.h
//  Blik
//
//  Created by Patrick Smith on 8/08/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
#import "GLAButton.h"
@class GLAPopUpButtonCell;


@interface GLAPopUpButton : NSPopUpButton <GLAButtonStyling>

@property (nonatomic) GLAPopUpButtonCell *cell;

@end


@interface GLAPopUpButtonCell : NSPopUpButtonCell <GLAButtonStyling>

@end