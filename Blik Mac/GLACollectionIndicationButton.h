//
//  GLACollectionIndicationView.h
//  Blik
//
//  Created by Patrick Smith on 28/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Cocoa;
#import "GLACollection.h"


@interface GLACollectionIndicationButton : NSButton

@property(nonatomic) GLACollection *collection;

@property(nonatomic) CGFloat diameter;
@property(nonatomic) CGFloat verticalOffsetDown;
@property(nonatomic) BOOL isFolder;

@property(readonly, nonatomic) NSColor *colorForDrawing;

@end
