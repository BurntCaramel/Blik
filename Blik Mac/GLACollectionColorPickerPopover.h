//
//  GLACollectionColorPicker.h
//  Blik
//
//  Created by Patrick Smith on 1/10/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;
#import "GLACollectionColorPickerViewController.h"


@interface GLACollectionColorPickerPopover : NSPopover

+ (instancetype)sharedColorPickerPopover;

@property(nonatomic) GLACollectionColorPickerViewController *colorPickerViewController;

@property(nonatomic) GLACollectionColor *chosenCollectionColor;

@end

extern NSString *GLACollectionColorPickerPopoverChosenColorDidChangeNotification;
