//
//  GLATableRowView.h
//  Blik
//
//  Created by Patrick Smith on 17/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

@import Cocoa;


@interface GLATableProjectRowView : NSTableRowView

- (void)checkMouseLocationIsInside;

@property(nonatomic) BOOL enabled;
@property(nonatomic) BOOL showsDividers;

@end
