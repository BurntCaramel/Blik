//
//  GLAColorChoiceView.h
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;


@interface GLAColorChoiceView : NSView

@property(copy, nonatomic) NSColor *color;
@property(nonatomic) BOOL on;

@property(nonatomic) BOOL togglesOnAndOff;

@property(nonatomic) NSSize dotSize;
@property(nonatomic) CALayer *dotLayer;

@end

extern NSString *GLAColorChoiceViewOnDidChangeNotification;
extern NSString *GLAColorChoiceViewDidClickNotification;
