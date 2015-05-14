//
//  GLATableHeaderCell.h
//  Blik
//
//  Created by Patrick Smith on 13/05/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLAUIStyle.h"


@interface GLATableHeaderCell : NSTableHeaderCell

- (instancetype)initWithCell:(NSTableHeaderCell *)cell;

@end


@interface GLAUIStyle (GLATableHeaderCell)

- (void)prepareContentTableColumn:(NSTableColumn *)tableColumn;

@end