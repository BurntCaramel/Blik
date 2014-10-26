//
//  GLAPrototypeBNavigationItem.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAButton.h"


@interface GLANavigationButtonCell : GLAButtonCell

- (NSRect)highlightRectForBounds:(NSRect)bounds;

@end


@interface GLANavigationButton : GLAButton

@property (nonatomic) GLANavigationButtonCell *cell;

@end
