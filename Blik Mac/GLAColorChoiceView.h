//
//  GLAColorChoiceView.h
//  Blik
//
//  Created by Patrick Smith on 16/09/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;


@interface GLAColorChoiceView : NSView

@property(nonatomic) NSColor *color;
@property(nonatomic) BOOL on;

@end

extern NSString *GLAColorChoiceViewOnDidChangeNotification;
