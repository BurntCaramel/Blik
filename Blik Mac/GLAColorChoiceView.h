//
//  GLAColorChoiceView.h
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;


@interface GLAColorChoiceView : NSView

@property(nonatomic) NSColor *color;
@property(nonatomic) BOOL on;

@property(nonatomic) BOOL togglesOnAndOff;

@end

extern NSString *GLAColorChoiceViewOnDidChangeNotification;
extern NSString *GLAColorChoiceViewDidClickNotification;
