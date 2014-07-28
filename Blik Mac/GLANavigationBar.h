//
//  GLAPrototypeBNavigationBar.h
//  Blik
//
//  Created by Patrick Smith on 7/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAView.h"

@interface GLANavigationBar : GLAView

@property(nonatomic) NSColor *highlightColor;

- (void)highlightWithColor:(NSColor *)color animate:(BOOL)animate;

@end
