//
//  GLASegmentedControl.h
//  Blik
//
//  Created by Patrick Smith on 1/04/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;

#import "GLAButton.h"


@interface GLASegmentedCell : NSSegmentedCell <GLAButtonStyling>

@end


@interface GLASegmentedControl : NSSegmentedControl <GLAButtonStyling>

- (GLASegmentedCell *)cell;

@end
